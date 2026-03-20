import XCTest
@testable import ShitHead

final class AIPlayerTests: XCTestCase {
    func makeState(aiHand: [Card], pile: [Card] = [], deck: [Card] = []) -> GameState {
        GameState(
            deck: deck,
            discardPile: pile,
            human: PlayerState(hand: [Card(suit: .clubs, rank: .five)], faceUp: [], faceDown: []),
            ai: PlayerState(hand: aiHand, faceUp: [], faceDown: []),
            currentTurn: .ai,
            reversalActive: false,
            bonusTurn: false
        )
    }

    func test_easyAI_returns_legal_move_when_available() {
        let ai = EasyAIPlayer()
        let state = makeState(
            aiHand: [Card(suit: .hearts, rank: .six)],
            pile: [Card(suit: .hearts, rank: .five)]
        )
        XCTAssertNotNil(ai.chooseMove(state: state))
    }

    func test_easyAI_returns_nil_when_no_legal_move() {
        let ai = EasyAIPlayer()
        let state = makeState(
            aiHand: [Card(suit: .hearts, rank: .five)],
            pile: [Card(suit: .hearts, rank: .ace)]
        )
        XCTAssertNil(ai.chooseMove(state: state))
    }

    func test_hardAI_saves_ten_when_other_option_available() {
        let ai = HardAIPlayer()
        let state = makeState(
            aiHand: [Card(suit: .hearts, rank: .ten), Card(suit: .spades, rank: .king)],
            pile: [Card(suit: .hearts, rank: .nine)]
        )
        // Hard AI should play King and save 10
        let move = ai.chooseMove(state: state)
        XCTAssertEqual(move?.first?.rank, .king)
    }

    func test_hardAI_uses_ten_when_only_option() {
        let ai = HardAIPlayer()
        let state = makeState(
            aiHand: [Card(suit: .hearts, rank: .ten)],
            pile: [Card(suit: .hearts, rank: .ace)]
        )
        let move = ai.chooseMove(state: state)
        XCTAssertEqual(move?.first?.rank, .ten)
    }
}
