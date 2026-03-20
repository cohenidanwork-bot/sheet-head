import Foundation

protocol PlayerProtocol {
    func chooseMove(state: GameState) -> [Card]?
}
