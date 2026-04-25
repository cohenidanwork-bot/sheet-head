// SheetHead/Engine/GameEngine.swift
import Foundation

enum Difficulty: String, Codable {
    case easy, hard
}

enum GameEngine {
    static func setupGame(difficulty: Difficulty) -> GameState {
        var deck = Card.fullDeck().shuffled()

        func deal(_ n: Int) -> [Card] {
            let cards = Array(deck.prefix(n))
            deck.removeFirst(n)
            return cards
        }

        let humanFaceDown = deal(3)
        let aiFaceDown = deal(3)
        let humanSixCards = deal(6)
        let aiSixCards = deal(6)

        let aiFaceUp: [Card]
        let aiHand: [Card]
        switch difficulty {
        case .easy:
            aiFaceUp = Array(aiSixCards.prefix(3))
            aiHand = Array(aiSixCards.suffix(3))
        case .hard:
            let sorted = aiSixCards.sorted { $0.rank > $1.rank }
            aiFaceUp = Array(sorted.prefix(3))
            aiHand = Array(sorted.suffix(3))
        }

        return GameState(
            deck: deck,
            discardPile: [],
            human: PlayerState(hand: humanSixCards, faceUp: [], faceDown: humanFaceDown),
            ai: PlayerState(hand: aiHand, faceUp: aiFaceUp, faceDown: aiFaceDown),
            currentTurn: .human,
            reversalActive: false,
            bonusTurn: false
        )
    }

    static func confirmPlayerSetup(state: GameState, faceUpCards: [Card]) -> GameState {
        var s = state
        let remaining = state.human.hand.filter { !faceUpCards.contains($0) }
        s.human.faceUp = faceUpCards
        s.human.hand = remaining

        let humanMin = s.human.hand.map(\.rank).min()
        let aiMin = s.ai.hand.map(\.rank).min()
        if let h = humanMin, let a = aiMin {
            s.currentTurn = h <= a ? .human : .ai
        }
        return s
    }

    static func legalMoves(for player: PlayerID, in state: GameState) -> [[Card]] {
        let playerState = player == .human ? state.human : state.ai
        let available: [Card]
        switch playerState.cardPhase {
        case .hand: available = playerState.hand
        case .faceUp: available = playerState.faceUp
        case .faceDown: return []
        }

        var byRank: [Rank: [Card]] = [:]
        for card in available {
            byRank[card.rank, default: []].append(card)
        }

        var moves: [[Card]] = []
        for (_, cards) in byRank {
            guard RuleValidator.canPlay([cards[0]], on: state.discardPile, reversalActive: state.reversalActive) else { continue }
            for size in 1...cards.count {
                let combo = Array(cards.prefix(size))
                moves.append(combo)
            }
        }
        return moves
    }

    static func applyMove(_ cards: [Card], by player: PlayerID, state: GameState) -> GameState {
        var s = state
        var played = player == .human ? s.human : s.ai

        switch played.cardPhase {
        case .hand: played.hand.removeAll { cards.contains($0) }
        case .faceUp: played.faceUp.removeAll { cards.contains($0) }
        case .faceDown: played.faceDown.removeAll { cards.contains($0) }
        }

        if player == .human { s.human = played } else { s.ai = played }

        let isBomb = RuleValidator.isBomb(pile: s.discardPile, adding: cards)
        s.discardPile.append(contentsOf: cards)

        let rank = cards.first!.rank

        if isBomb || rank == .ten {
            s.discardPile = []
            s.reversalActive = false
            s.bonusTurn = true
            s.currentTurn = player
        } else if rank == .eight {
            s.reversalActive = false
            s.bonusTurn = true
            s.currentTurn = player
        } else if rank == .seven {
            s.reversalActive = true   // 7 always forces next player to play below 7
            s.bonusTurn = false
            s.currentTurn = player == .human ? .ai : .human
        } else if rank == .three {
            // 3 is transparent: preserves the current reversal state
            s.bonusTurn = false
            s.currentTurn = player == .human ? .ai : .human
        } else {
            s.reversalActive = false
            s.bonusTurn = false
            s.currentTurn = player == .human ? .ai : .human
        }

        s = drawCards(for: player, state: s)
        return s
    }

    static func applyBlindDraw(by player: PlayerID, state: GameState) -> GameState {
        var s = state
        var played = player == .human ? s.human : s.ai
        guard !played.faceDown.isEmpty else { return s }

        let flippedCard = played.faceDown.removeFirst()
        if player == .human { s.human = played } else { s.ai = played }

        let canPlay = RuleValidator.canPlay([flippedCard], on: s.discardPile, reversalActive: s.reversalActive)
        if canPlay {
            return applyMove([flippedCard], by: player, state: s)
        } else {
            var updated = player == .human ? s.human : s.ai
            updated.hand.append(contentsOf: s.discardPile)
            updated.hand.append(flippedCard)
            s.discardPile = []
            s.reversalActive = false
            if player == .human { s.human = updated } else { s.ai = updated }
            s.currentTurn = player == .human ? .ai : .human
            s.bonusTurn = false
            return s
        }
    }

    static func pickUpPile(for player: PlayerID, state: GameState) -> GameState {
        var s = state
        var updated = player == .human ? s.human : s.ai
        updated.hand.append(contentsOf: s.discardPile)
        s.discardPile = []
        s.reversalActive = false
        if player == .human { s.human = updated } else { s.ai = updated }
        s.currentTurn = player == .human ? .ai : .human
        s.bonusTurn = false
        return s
    }

    static func drawCards(for player: PlayerID, state: GameState) -> GameState {
        var s = state
        var updated = player == .human ? s.human : s.ai
        guard updated.cardPhase == .hand else { return s }
        while updated.hand.count < 3 && !s.deck.isEmpty {
            updated.hand.append(s.deck.removeFirst())
        }
        if player == .human { s.human = updated } else { s.ai = updated }
        return s
    }

    static func checkWinCondition(state: GameState) -> AppPhase {
        if !state.human.hasCards { return .gameOver(winner: .human, loser: .ai) }
        if !state.ai.hasCards { return .gameOver(winner: .ai, loser: .human) }
        return .playing
    }
}
