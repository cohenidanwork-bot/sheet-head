// ShitHeadTests/GameEngineTests.swift
import XCTest
@testable import ShitHead

final class GameEngineTests: XCTestCase {
    func test_setupGame_deals_correct_cards() {
        let state = GameEngine.setupGame(difficulty: .easy)
        XCTAssertEqual(state.human.faceDown.count, 3)
        XCTAssertEqual(state.human.faceUp.count, 0)
        XCTAssertEqual(state.human.hand.count, 6)
        XCTAssertEqual(state.ai.faceDown.count, 3)
        XCTAssertEqual(state.deck.count, 52 - 6 - 6 - 3 - 3) // 34
        XCTAssertEqual(state.currentTurn, .human)
    }

    func test_confirmSetup_splits_six_into_threeUp_threeHand() {
        var state = GameEngine.setupGame(difficulty: .easy)
        let chosen = Array(state.human.hand.prefix(3))
        state = GameEngine.confirmPlayerSetup(state: state, faceUpCards: chosen)
        XCTAssertEqual(state.human.faceUp.count, 3)
        XCTAssertEqual(state.human.hand.count, 3)
        XCTAssertTrue(chosen.allSatisfy { state.human.faceUp.contains($0) })
    }

    func test_legalMoves_returns_playable_cards() {
        var state = makeSimpleState()
        state.discardPile = [Card(suit: .hearts, rank: .five)]
        state.human.hand = [Card(suit: .hearts, rank: .six), Card(suit: .hearts, rank: .three)]
        let moves = GameEngine.legalMoves(for: .human, in: state)
        XCTAssertFalse(moves.isEmpty)
        let ranks = moves.flatMap { $0 }.map { $0.rank }
        XCTAssertTrue(ranks.contains(.six) || ranks.contains(.three))
    }

    func test_legalMoves_empty_when_no_playable_card() {
        var state = makeSimpleState()
        state.discardPile = [Card(suit: .hearts, rank: .ace)]
        state.human.hand = [Card(suit: .hearts, rank: .five)]
        let moves = GameEngine.legalMoves(for: .human, in: state)
        XCTAssertTrue(moves.isEmpty)
    }

    func test_applyMove_places_card_on_pile() {
        var state = makeSimpleState()
        let card = Card(suit: .hearts, rank: .six)
        state.human.hand = [card, Card(suit: .spades, rank: .two), Card(suit: .clubs, rank: .two)]
        state.discardPile = [Card(suit: .hearts, rank: .five)]
        state.deck = Array(Card.fullDeck().filter { $0.rank != .six && $0.rank != .two }.prefix(5))
        let result = GameEngine.applyMove([card], by: .human, state: state)
        XCTAssertEqual(result.discardPile.last?.rank, .six)
        XCTAssertFalse(result.human.hand.contains(card))
    }

    func test_applyMove_ten_burns_pile_and_gives_bonus_turn() {
        var state = makeSimpleState()
        let ten = Card(suit: .hearts, rank: .ten)
        state.human.hand = [ten]
        state.discardPile = [Card(suit: .spades, rank: .king)]
        let result = GameEngine.applyMove([ten], by: .human, state: state)
        XCTAssertTrue(result.discardPile.isEmpty)
        XCTAssertTrue(result.bonusTurn)
        XCTAssertEqual(result.currentTurn, .human)
    }

    func test_applyMove_eight_skip_gives_bonus_turn_in_two_player() {
        var state = makeSimpleState()
        let eight = Card(suit: .hearts, rank: .eight)
        state.human.hand = [eight]
        state.discardPile = [Card(suit: .hearts, rank: .seven)]
        let result = GameEngine.applyMove([eight], by: .human, state: state)
        XCTAssertEqual(result.currentTurn, .human)
        XCTAssertTrue(result.bonusTurn)
    }

    func test_applyMove_seven_activates_reversal() {
        var state = makeSimpleState()
        let seven = Card(suit: .hearts, rank: .seven)
        state.human.hand = [seven]
        state.discardPile = [Card(suit: .hearts, rank: .six)]
        let result = GameEngine.applyMove([seven], by: .human, state: state)
        XCTAssertTrue(result.reversalActive)
        XCTAssertEqual(result.currentTurn, .ai)
    }

    func test_pickUpPile_moves_pile_to_hand() {
        var state = makeSimpleState()
        let pileCards = [Card(suit: .hearts, rank: .five), Card(suit: .spades, rank: .nine)]
        state.discardPile = pileCards
        state.human.hand = [Card(suit: .hearts, rank: .two)]
        let result = GameEngine.pickUpPile(for: .human, state: state)
        XCTAssertTrue(result.discardPile.isEmpty)
        XCTAssertEqual(result.human.hand.count, 3)
        XCTAssertEqual(result.currentTurn, .ai)
    }

    func test_checkWinCondition_detects_empty_hand() {
        var state = makeSimpleState()
        state.human.hand = []
        state.human.faceUp = []
        state.human.faceDown = []
        let result = GameEngine.checkWinCondition(state: state)
        if case .gameOver(let winner, let loser) = result {
            XCTAssertEqual(winner, .human)
            XCTAssertEqual(loser, .ai)
        } else {
            XCTFail("Expected gameOver")
        }
    }

    private func makeSimpleState() -> GameState {
        GameState(
            deck: [],
            discardPile: [],
            human: PlayerState(hand: [], faceUp: [], faceDown: []),
            ai: PlayerState(hand: [Card(suit: .clubs, rank: .three)], faceUp: [], faceDown: []),
            currentTurn: .human,
            reversalActive: false,
            bonusTurn: false
        )
    }
}
