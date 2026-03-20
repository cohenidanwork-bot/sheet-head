import Foundation

struct HardAIPlayer: PlayerProtocol {
    func chooseMove(state: GameState) -> [Card]? {
        let moves = GameEngine.legalMoves(for: .ai, in: state)
        guard !moves.isEmpty else { return nil }

        let humanCardCount = state.human.hand.count + state.human.faceUp.count + state.human.faceDown.count
        let specialRanks: Set<Rank> = [.two, .ten]
        let sortedBySize = moves.sorted { $0.count > $1.count }
        let nonSpecialMoves = sortedBySize.filter { !specialRanks.contains($0.first!.rank) }
        let specialMoves = sortedBySize.filter { specialRanks.contains($0.first!.rank) }

        // Use 8 to skip when human has few cards
        if humanCardCount <= 3, let skipMove = moves.first(where: { $0.first?.rank == .eight }) {
            return skipMove
        }

        // Use 7 if human only has high cards
        let humanHand = state.human.hand
        let humanAllHigh = !humanHand.isEmpty && humanHand.allSatisfy { $0.rank.rawValue >= 8 }
        if humanAllHigh, let sevenMove = moves.first(where: { $0.first?.rank == .seven }) {
            return sevenMove
        }

        // Dump high cards (K, A) first
        if let high = nonSpecialMoves.first(where: { $0.first!.rank >= .king }) { return high }

        // Play any non-special move
        if let normal = nonSpecialMoves.first { return normal }

        // Fall back to specials
        return specialMoves.first
    }
}
