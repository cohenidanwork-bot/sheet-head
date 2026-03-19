// ShitHead/Models/Card.swift
import Foundation

enum Suit: String, CaseIterable, Codable, Hashable {
    case hearts = "♥"
    case diamonds = "♦"
    case clubs = "♣"
    case spades = "♠"
}

enum Rank: Int, CaseIterable, Codable, Comparable, Hashable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen = 12, king = 13, ace = 14

    static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var display: String {
        switch self {
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        default: return "\(rawValue)"
        }
    }
}

struct Card: Identifiable, Hashable, Codable {
    let suit: Suit
    let rank: Rank

    var id: String { "\(rank.rawValue)-\(suit.rawValue)" }

    /// Ace is treated as low (value 1) when checking the 7-reversal constraint.
    var countsAsLowForReversal: Bool {
        rank == .ace
    }

    static func fullDeck() -> [Card] {
        Suit.allCases.flatMap { suit in
            Rank.allCases.map { rank in Card(suit: suit, rank: rank) }
        }
    }
}
