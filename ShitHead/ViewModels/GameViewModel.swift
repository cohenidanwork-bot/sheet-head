// ShitHead/ViewModels/GameViewModel.swift
import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {
    @Published var gameState: GameState?
    @Published var appPhase: AppPhase = .home
    @Published var selectedCards: [Card] = []
    @Published var setupCards: [Card] = []
    @Published var chosenFaceUp: [Card] = []
    @Published var showPhaseBanner: Bool = false
    @Published var phaseBannerText: String = ""
    @Published var showBurnFlash: Bool = false
    @Published var shakeCardID: String? = nil
    @Published var difficulty: Difficulty = .easy

    private var aiPlayer: any PlayerProtocol = EasyAIPlayer()
    private var aiTask: Task<Void, Never>?
    private var previousCardPhase: CardPhase?

    // MARK: - Game Start

    func startNewGame() {
        aiTask?.cancel()
        GamePersistence.clear()
        let state = GameEngine.setupGame(difficulty: difficulty)
        setupCards = state.human.hand
        chosenFaceUp = []
        gameState = state
        previousCardPhase = nil
        appPhase = .setup
        aiPlayer = difficulty == .easy ? EasyAIPlayer() : HardAIPlayer()
    }

    func confirmSetup() {
        guard chosenFaceUp.count == 3, var state = gameState else { return }
        state = GameEngine.confirmPlayerSetup(state: state, faceUpCards: chosenFaceUp)
        gameState = state
        previousCardPhase = .hand
        appPhase = .playing
        GamePersistence.save(state)
    }

    func resumeIfSaved() {
        guard appPhase == .home, let saved = GamePersistence.load() else { return }
        gameState = saved
        previousCardPhase = saved.human.cardPhase
        appPhase = .playing
        aiPlayer = difficulty == .easy ? EasyAIPlayer() : HardAIPlayer()
        if saved.currentTurn == .ai { scheduleAIMove() }
    }

    // MARK: - Player Actions

    func toggleCard(_ card: Card) {
        guard appPhase == .playing, gameState?.currentTurn == .human else { return }
        if selectedCards.contains(card) {
            selectedCards.removeAll { $0 == card }
        } else {
            selectedCards.append(card)
        }
    }

    func playSelectedCards() {
        guard var state = gameState, !selectedCards.isEmpty else { return }
        guard RuleValidator.canPlay(selectedCards, on: state.discardPile, reversalActive: state.reversalActive) else {
            shakeCardID = selectedCards.last?.id
            selectedCards = []
            return
        }
        let prevPileCount = state.discardPile.count
        state = GameEngine.applyMove(selectedCards, by: .human, state: state)
        selectedCards = []
        finishTurn(state: state, prevPileCount: prevPileCount)
    }

    func playBlindCard() {
        guard var state = gameState,
              state.human.cardPhase == .faceDown,
              state.currentTurn == .human else { return }
        let prevPileCount = state.discardPile.count
        state = GameEngine.applyBlindDraw(by: .human, state: state)
        finishTurn(state: state, prevPileCount: prevPileCount)
    }

    func pickUpPile() {
        guard var state = gameState else { return }
        state = GameEngine.pickUpPile(for: .human, state: state)
        finishTurn(state: state, prevPileCount: 0)
    }

    // MARK: - Turn Management

    private func finishTurn(state: GameState, prevPileCount: Int) {
        let didBurn = state.discardPile.isEmpty && prevPileCount > 0
        if didBurn { triggerBurnFlash() }

        checkPhaseTransition(newState: state)

        let outcome = GameEngine.checkWinCondition(state: state)
        gameState = state
        GamePersistence.save(state)

        if case .gameOver = outcome {
            appPhase = outcome
            return
        }

        appPhase = .playing
        if state.currentTurn == .ai { scheduleAIMove() }
    }

    private func scheduleAIMove() {
        aiTask?.cancel()
        aiTask = Task {
            let delay = Double.random(in: 0.8...1.2)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await executeAITurn()
        }
    }

    @MainActor
    private func executeAITurn() {
        guard var state = gameState, state.currentTurn == .ai else { return }
        let prevPileCount = state.discardPile.count
        if state.ai.cardPhase == .faceDown {
            state = GameEngine.applyBlindDraw(by: .ai, state: state)
        } else if let move = aiPlayer.chooseMove(state: state) {
            state = GameEngine.applyMove(move, by: .ai, state: state)
        } else {
            state = GameEngine.pickUpPile(for: .ai, state: state)
        }
        finishTurn(state: state, prevPileCount: prevPileCount)
    }

    // MARK: - UI Effects

    private func triggerBurnFlash() {
        showBurnFlash = true
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            showBurnFlash = false
        }
    }

    private func checkPhaseTransition(newState: GameState) {
        let current = newState.human.cardPhase
        guard let prev = previousCardPhase, prev != current else {
            if previousCardPhase == nil { previousCardPhase = current }
            return
        }
        previousCardPhase = current
        switch current {
        case .faceUp: showBanner("Playing face-up cards")
        case .faceDown: showBanner("Playing blind cards")
        default: break
        }
    }

    private func showBanner(_ text: String) {
        phaseBannerText = text
        showPhaseBanner = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showPhaseBanner = false
        }
    }
}
