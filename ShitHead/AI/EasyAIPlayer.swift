import Foundation

struct EasyAIPlayer: PlayerProtocol {
    func chooseMove(state: GameState) -> [Card]? {
        let moves = GameEngine.legalMoves(for: .ai, in: state)
        return moves.randomElement()
    }
}
