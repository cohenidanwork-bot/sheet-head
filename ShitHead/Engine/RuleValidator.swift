// SheetHead/Engine/RuleValidator.swift
import Foundation

enum RuleValidator {
    static func effectiveTopRank(of pile: [Card]) -> Rank? {
        for card in pile.reversed() {
            if card.rank != .three { return card.rank }
        }
        return nil
    }

    static func isBomb(pile: [Card], adding cards: [Card]) -> Bool {
        guard let rank = cards.first?.rank else { return false }
        let countInPile = pile.filter { $0.rank == rank }.count
        let countAdding = cards.filter { $0.rank == rank }.count
        return countInPile + countAdding >= 4
    }

    static func canPlay(_ cards: [Card], on pile: [Card], reversalActive: Bool) -> Bool {
        guard !cards.isEmpty else { return false }
        guard let rank = cards.first?.rank else { return false }
        guard cards.allSatisfy({ $0.rank == rank }) else { return false }

        // 2, 3, 10 can always be played
        if rank == .two || rank == .three || rank == .ten { return true }

        let effectiveTop = effectiveTopRank(of: pile)

        // Reversal active: must play < 7. 7 itself chains the reversal. Ace is high (14) so blocked.
        if reversalActive {
            if rank == .seven { return true }
            return rank.rawValue < 7
        }

        // 7 can only be played on a card with effective value <= 7 (ace is high = 14, blocked)
        if rank == .seven {
            guard let top = effectiveTop else { return true }
            return top.rawValue <= 7
        }

        // Normal play: must be >= effective top
        guard let top = effectiveTop else { return true }
        return rank >= top
    }
}
