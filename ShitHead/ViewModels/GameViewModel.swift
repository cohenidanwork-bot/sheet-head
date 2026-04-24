// SheetHead/ViewModels/GameViewModel.swift
import SwiftUI

// MARK: - Blast Types

enum BlastType: Equatable {
    case burn
    case bomb
    case playerPickup
    case cpuPickup
    case reversal
    case skip

    var headline: String {
        switch self {
        case .burn:         return "PILE CLEARED"
        case .bomb:         return "FOUR OF A KIND"
        case .playerPickup: return "TAKE THE PILE"
        case .cpuPickup:    return "TAKES THE PILE"
        case .reversal:     return "PLAY UNDER 7"
        case .skip:         return "SKIP"
        }
    }

    var subline: String {
        switch self {
        case .burn:         return "THE PILE IS GONE"
        case .bomb:         return "PILE CLEARED"
        case .playerPickup: return "YOU PICK UP THE PILE"
        case .cpuPickup:    return "IT TAKES THE PILE"
        case .reversal:     return "PLAY UNDER 7"
        case .skip:         return "NEXT PLAYER MISSES A TURN"
        }
    }

    var overlayColor: Color {
        switch self {
        case .burn:         return Color(hex: "#1A0000")
        case .bomb:         return Color(hex: "#1A0C00")
        case .playerPickup: return Color(hex: "#0D0018")
        case .cpuPickup:    return Color(hex: "#001800")
        case .reversal:     return Color(hex: "#00081A")
        case .skip:         return Color(hex: "#12001A")
        }
    }

    var accentColor: Color {
        switch self {
        case .burn:         return Color(hex: "#FF2200")
        case .bomb:         return Color(hex: "#FFB300")
        case .playerPickup: return Color(hex: "#CC0055")
        case .cpuPickup:    return Color(hex: "#00CC44")
        case .reversal:     return Color(hex: "#0088FF")
        case .skip:         return Color(hex: "#AA00FF")
        }
    }
}

// MARK: - Flying Card

struct FlyingCard: Identifiable {
    let id = UUID()
    let card: Card
    let from: FlyZone
    let to: FlyZone
    let rotation: Double

    enum FlyZone {
        case drawPile, discardPile, playerHand, playerFaceUp, opponentHand
    }
}

// MARK: - ViewModel

@MainActor
final class GameViewModel: ObservableObject {
    @Published var gameState: GameState?
    @Published var appPhase: AppPhase = .home
    @Published var selectedCards: [Card] = []
    @Published var setupCards: [Card] = []
    @Published var chosenFaceUp: [Card] = []
    @Published var showPhaseBanner: Bool = false
    @Published var phaseBannerText: String = ""
    @Published var phaseBannerIcon: String = "info.circle.fill"
    @Published var phaseBannerTint: Color = .shGold
    @Published var showBurnFlash: Bool = false
    @Published var shakeCardID: String? = nil
    @Published var difficulty: Difficulty = .easy
    @Published var flyingCards: [FlyingCard] = []
    @Published var hiddenCardIDs: Set<String> = []
    @Published var activeBlast: BlastType? = nil
    @Published var lastPlayedCards: [Card] = []
    @Published var opponentName: String = "CPU"

    private static let opponentNames = [
        "DUKE", "BLAZE", "VIPER", "KNAVE", "REX", "GRIM", "OTTO", "LUDO",
        "FINN", "ZEKE", "BRAM", "MORT", "PIKE", "ROOK", "FLINT", "SHADE",
        "WOLF", "CRUZ", "SLICK", "DUTCH", "GATOR", "NOVA", "CROSS", "SABLE"
    ]

    private var aiPlayer: any PlayerProtocol = EasyAIPlayer()
    private var aiTask: Task<Void, Never>?
    private var blastTask: Task<Void, Never>?
    private var previousCardPhase: CardPhase?
    private var previousReversalActive: Bool = false

    // MARK: - Computed

    var mustPickUp: Bool {
        guard let state = gameState, state.currentTurn == .human else { return false }
        if state.human.cardPhase == .faceDown { return false }
        return selectedCards.isEmpty
            && GameEngine.legalMoves(for: .human, in: state).isEmpty
            && !state.discardPile.isEmpty
    }

    // MARK: - Navigation

    func goHome() {
        aiTask?.cancel()
        blastTask?.cancel()
        GamePersistence.clear()
        activeBlast = nil
        flyingCards = []
        lastPlayedCards = []
        selectedCards = []
        appPhase = .home
    }

    // MARK: - Game Start

    func startNewGame() {
        aiTask?.cancel()
        blastTask?.cancel()
        GamePersistence.clear()
        let state = GameEngine.setupGame(difficulty: difficulty)
        setupCards = state.human.hand
        chosenFaceUp = []
        gameState = state
        previousCardPhase = nil
        previousReversalActive = false
        flyingCards = []
        lastPlayedCards = []
        selectedCards = []
        activeBlast = nil
        opponentName = Self.opponentNames.randomElement() ?? "CPU"
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
        if state.currentTurn == .ai { scheduleAIMove() }
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
        let cardsToPlay = selectedCards
        let wasBomb = RuleValidator.isBomb(pile: state.discardPile, adding: cardsToPlay)
        let wasSkip = cardsToPlay.contains { $0.rank == .eight }
        let fromZone: FlyingCard.FlyZone = state.human.cardPhase == .faceUp ? .playerFaceUp : .playerHand

        for card in cardsToPlay {
            hiddenCardIDs.insert(card.id)
            flyingCards.append(FlyingCard(card: card, from: fromZone, to: .discardPile,
                                          rotation: Double.random(in: -12...12)))
        }
        selectedCards = []

        let prevPileCount = state.discardPile.count
        state = GameEngine.applyMove(cardsToPlay, by: .human, state: state)
        let newState = state
        let ppc = prevPileCount

        Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            flyingCards = []
            hiddenCardIDs = []
            lastPlayedCards = cardsToPlay
            finishTurn(state: newState, prevPileCount: ppc, wasBomb: wasBomb, wasSkip: wasSkip)
        }
    }

    func playBlindCard() {
        guard var state = gameState,
              state.human.cardPhase == .faceDown,
              state.currentTurn == .human else { return }
        guard let topCard = state.human.faceDown.first else { return }
        let prevPileCount = state.discardPile.count
        let canPlay = RuleValidator.canPlay([topCard], on: state.discardPile, reversalActive: state.reversalActive)
        let wasBomb = RuleValidator.isBomb(pile: state.discardPile, adding: [topCard])

        // Reveal: show the flipped card flying face-up to pile so player can see it
        flyingCards.append(FlyingCard(card: topCard, from: .playerFaceUp, to: .discardPile,
                                      rotation: Double.random(in: -10...10)))
        lastPlayedCards = [topCard]

        state = GameEngine.applyBlindDraw(by: .human, state: state)
        let newState = state

        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            flyingCards = []
            if !canPlay {
                lastPlayedCards = []
                triggerBlast(.playerPickup)
            }
            finishTurn(state: newState, prevPileCount: canPlay ? prevPileCount : 0, wasBomb: wasBomb)
        }
    }

    func pickUpPile() {
        guard var state = gameState else { return }
        if let top = state.topOfPile {
            flyingCards.append(FlyingCard(card: top, from: .discardPile, to: .playerHand,
                                          rotation: Double.random(in: -8...8)))
        }
        state = GameEngine.pickUpPile(for: .human, state: state)
        let newState = state
        Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            flyingCards = []
            lastPlayedCards = []
            triggerBlast(.playerPickup)
            finishTurn(state: newState, prevPileCount: 0)
        }
    }

    // MARK: - Turn Management

    private func finishTurn(state: GameState, prevPileCount: Int, wasBomb: Bool = false, wasSkip: Bool = false) {
        let didBurn = state.discardPile.isEmpty && prevPileCount > 0
        if didBurn {
            lastPlayedCards = []
            triggerBurn(wasBomb: wasBomb)
        }

        let didActivateReversal = state.reversalActive && !previousReversalActive
        previousReversalActive = state.reversalActive

        if !didBurn {
            if didActivateReversal {
                triggerBlast(.reversal, afterDelay: 0.7)
            } else if wasSkip {
                triggerBlast(.skip, afterDelay: 0.7)
            }
        }

        checkPhaseTransition(newState: state)

        let outcome = GameEngine.checkWinCondition(state: state)
        gameState = state
        GamePersistence.save(state)

        if case .gameOver = outcome {
            appPhase = outcome
            return
        }

        appPhase = .playing
        if state.currentTurn == .ai {
            scheduleAIMove()
        } else {
            Haptics.light()
        }
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
            guard let topCard = state.ai.faceDown.first else { return }
            let canPlay = RuleValidator.canPlay([topCard], on: state.discardPile, reversalActive: state.reversalActive)
            let wasBomb = RuleValidator.isBomb(pile: state.discardPile, adding: [topCard])

            // Reveal: show the AI's flipped card flying face-up to pile
            flyingCards.append(FlyingCard(card: topCard, from: .opponentHand, to: .discardPile,
                                          rotation: Double.random(in: -10...10)))
            lastPlayedCards = [topCard]

            state = GameEngine.applyBlindDraw(by: .ai, state: state)
            let newState = state
            let ppc = prevPileCount
            Task {
                try? await Task.sleep(nanoseconds: 450_000_000)
                flyingCards = []
                if !canPlay {
                    lastPlayedCards = []
                    triggerBlast(.cpuPickup)
                }
                finishTurn(state: newState, prevPileCount: canPlay ? ppc : 0, wasBomb: wasBomb)
            }
        } else if let move = aiPlayer.chooseMove(state: state) {
            let wasBomb = RuleValidator.isBomb(pile: state.discardPile, adding: move)
            let wasSkip = move.contains { $0.rank == .eight }
            for card in move {
                flyingCards.append(FlyingCard(card: card, from: .opponentHand, to: .discardPile,
                                              rotation: Double.random(in: -12...12)))
            }
            state = GameEngine.applyMove(move, by: .ai, state: state)
            let newState = state
            let ppc = prevPileCount
            Task {
                try? await Task.sleep(nanoseconds: 250_000_000)
                flyingCards = []
                lastPlayedCards = move
                finishTurn(state: newState, prevPileCount: ppc, wasBomb: wasBomb, wasSkip: wasSkip)
            }
        } else {
            if let top = state.topOfPile {
                flyingCards.append(FlyingCard(card: top, from: .discardPile, to: .opponentHand,
                                              rotation: Double.random(in: -8...8)))
            }
            state = GameEngine.pickUpPile(for: .ai, state: state)
            let newState = state
            Task {
                try? await Task.sleep(nanoseconds: 250_000_000)
                flyingCards = []
                lastPlayedCards = []
                triggerBlast(.cpuPickup)
                finishTurn(state: newState, prevPileCount: 0)
            }
        }
    }

    // MARK: - Blast System

    func triggerBlast(_ type: BlastType, afterDelay: Double = 0) {
        blastTask?.cancel()
        blastTask = Task {
            if afterDelay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(afterDelay * 1_000_000_000))
                guard !Task.isCancelled else { return }
            }
            withAnimation(.easeOut(duration: 0.08)) { activeBlast = type }
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.28)) { activeBlast = nil }
        }
    }

    // MARK: - UI Effects

    private func triggerBurn(wasBomb: Bool) {
        showBurnFlash = true
        triggerBlast(wasBomb ? .bomb : .burn)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
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
        case .faceUp:   showBanner("Now playing face-up cards", icon: "eye.fill", tint: .shGold)
        case .faceDown: showBanner("Playing blind!", icon: "eye.slash.fill", tint: .shCrimson)
        default: break
        }
    }

    private func showBanner(_ text: String, icon: String = "info.circle.fill", tint: Color = .shGold) {
        phaseBannerText = text
        phaseBannerIcon = icon
        phaseBannerTint = tint
        showPhaseBanner = true
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            showPhaseBanner = false
        }
    }
}
