// SheetHead/Models/GameState.swift
import Foundation

enum PlayerID: String, Codable, Hashable {
    case human, ai
}

/// Which pool of cards the player is currently drawing from
enum CardPhase: Codable, Equatable {
    case hand       // Playing from hand (deck refills hand)
    case faceUp     // Hand empty; playing face-up table cards
    case faceDown   // All visible cards gone; blind draw from face-down
}

enum AppPhase: Codable, Equatable {
    case home
    case setup      // Player selecting face-up cards
    case playing
    case gameOver(winner: PlayerID, loser: PlayerID)
}

struct PlayerState: Codable, Equatable {
    var hand: [Card]
    var faceUp: [Card]      // 3 face-up table cards (visible to all)
    var faceDown: [Card]    // 3 face-down table cards (blind)

    var cardPhase: CardPhase {
        if !hand.isEmpty { return .hand }
        if !faceUp.isEmpty { return .faceUp }
        return .faceDown
    }

    var hasCards: Bool {
        !hand.isEmpty || !faceUp.isEmpty || !faceDown.isEmpty
    }
}

struct GameState: Codable, Equatable {
    var deck: [Card]
    var discardPile: [Card]     // top of pile = last element
    var human: PlayerState
    var ai: PlayerState
    var currentTurn: PlayerID
    var reversalActive: Bool    // 7 effect: next player must play < 7
    var bonusTurn: Bool         // 10 / bomb: same player goes again

    var topOfPile: Card? { discardPile.last }
}
