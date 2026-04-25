// SheetHeadTests/GameEngineTests.swift
import XCTest
@testable import SheetHead

final class GameEngineTests: XCTestCase {

    // MARK: - Setup

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

    // MARK: - Legal Moves

    func test_legalMoves_returns_playable_cards() {
        var state = makeSimpleState()
        state.discardPile = [Card(suit: .hearts, rank: .five)]
        state.human.hand = [Card(suit: .hearts, rank: .six), Card(suit: .hearts, rank: .three)]
        let moves = GameEngine.legalMoves(for: .human, in: state)
        XCTAssertFalse(moves.isEmpty)
    }

    func test_legalMoves_empty_when_no_playable_card() {
        var state = makeSimpleState()
        state.discardPile = [Card(suit: .hearts, rank: .ace)]
        state.human.hand = [Card(suit: .hearts, rank: .five)]
        let moves = GameEngine.legalMoves(for: .human, in: state)
        XCTAssertTrue(moves.isEmpty)
    }

    func test_legalMoves_during_reversal_blocks_high_cards() {
        var state = makeSimpleState()
        state.reversalActive = true
        state.discardPile = [Card(suit: .hearts, rank: .seven)]
        state.ai.hand = [
            Card(suit: .hearts, rank: .eight),  // BLOCKED
            Card(suit: .hearts, rank: .king),    // BLOCKED
            Card(suit: .hearts, rank: .ace),     // BLOCKED
        ]
        let moves = GameEngine.legalMoves(for: .ai, in: state)
        XCTAssertTrue(moves.isEmpty, "AI should have NO legal moves — all cards >= 7")
    }

    func test_legalMoves_during_reversal_allows_low_and_special() {
        var state = makeSimpleState()
        state.reversalActive = true
        state.discardPile = [Card(suit: .hearts, rank: .seven)]
        state.ai.hand = [
            Card(suit: .hearts, rank: .five),    // OK (< 7)
            Card(suit: .hearts, rank: .two),     // OK (special)
            Card(suit: .hearts, rank: .ten),     // OK (special)
            Card(suit: .hearts, rank: .eight),   // BLOCKED
        ]
        let moves = GameEngine.legalMoves(for: .ai, in: state)
        let playableRanks = Set(moves.flatMap { $0 }.map { $0.rank })
        XCTAssertTrue(playableRanks.contains(.five))
        XCTAssertTrue(playableRanks.contains(.two))
        XCTAssertTrue(playableRanks.contains(.ten))
        XCTAssertFalse(playableRanks.contains(.eight), "8 must be blocked during reversal")
    }

    func test_legalMoves_during_reversal_allows_seven_chain() {
        var state = makeSimpleState()
        state.reversalActive = true
        state.discardPile = [Card(suit: .hearts, rank: .seven)]
        state.ai.hand = [Card(suit: .clubs, rank: .seven)]
        let moves = GameEngine.legalMoves(for: .ai, in: state)
        XCTAssertFalse(moves.isEmpty, "7 should be playable during reversal (chains)")
    }

    // MARK: - Apply Move

    func test_applyMove_places_card_on_pile() {
        var state = makeSimpleState()
        let card = Card(suit: .hearts, rank: .six)
        state.human.hand = [card, Card(suit: .spades, rank: .two), Card(suit: .clubs, rank: .two)]
        state.discardPile = [Card(suit: .hearts, rank: .five)]
        let result = GameEngine.applyMove([card], by: .human, state: state)
        XCTAssertEqual(result.discardPile.last?.rank, .six)
        XCTAssertFalse(result.human.hand.contains(card))
    }

    func test_applyMove_ten_burns_pile() {
        var state = makeSimpleState()
        let ten = Card(suit: .hearts, rank: .ten)
        state.human.hand = [ten]
        state.discardPile = [Card(suit: .spades, rank: .king)]
        let result = GameEngine.applyMove([ten], by: .human, state: state)
        XCTAssertTrue(result.discardPile.isEmpty, "10 should burn the pile")
        XCTAssertTrue(result.bonusTurn)
        XCTAssertEqual(result.currentTurn, .human, "Same player gets another turn after burn")
    }

    func test_applyMove_eight_skips() {
        var state = makeSimpleState()
        let eight = Card(suit: .hearts, rank: .eight)
        state.human.hand = [eight]
        state.discardPile = [Card(suit: .hearts, rank: .seven)]
        let result = GameEngine.applyMove([eight], by: .human, state: state)
        XCTAssertEqual(result.currentTurn, .human, "8 skips opponent, same player goes")
        XCTAssertTrue(result.bonusTurn)
        XCTAssertFalse(result.reversalActive, "8 should clear reversal")
    }

    func test_applyMove_seven_activates_reversal() {
        var state = makeSimpleState()
        let seven = Card(suit: .hearts, rank: .seven)
        state.human.hand = [seven]
        state.discardPile = [Card(suit: .hearts, rank: .six)]
        let result = GameEngine.applyMove([seven], by: .human, state: state)
        XCTAssertTrue(result.reversalActive, "Playing 7 should activate reversal")
        XCTAssertEqual(result.currentTurn, .ai, "Turn passes to opponent")
    }

    func test_applyMove_seven_chain_keeps_reversal() {
        var state = makeSimpleState()
        state.reversalActive = true
        state.currentTurn = .ai
        let seven = Card(suit: .clubs, rank: .seven)
        state.ai.hand = [seven]
        state.discardPile = [Card(suit: .hearts, rank: .seven)]
        let result = GameEngine.applyMove([seven], by: .ai, state: state)
        XCTAssertTrue(result.reversalActive, "Playing 7 on reversal should keep it active")
        XCTAssertEqual(result.currentTurn, .human)
    }

    func test_applyMove_normal_card_clears_reversal() {
        var state = makeSimpleState()
        state.reversalActive = true
        state.currentTurn = .ai
        let five = Card(suit: .clubs, rank: .five)
        state.ai.hand = [five]
        state.discardPile = [Card(suit: .hearts, rank: .seven)]
        let result = GameEngine.applyMove([five], by: .ai, state: state)
        XCTAssertFalse(result.reversalActive, "Normal card should clear reversal")
    }

    func test_applyMove_three_preserves_reversal() {
        var state = makeSimpleState()
        state.reversalActive = true
        state.currentTurn = .ai
        let three = Card(suit: .clubs, rank: .three)
        state.ai.hand = [three]
        state.discardPile = [Card(suit: .hearts, rank: .seven)]
        let result = GameEngine.applyMove([three], by: .ai, state: state)
        XCTAssertTrue(result.reversalActive, "3 (transparent) should preserve reversal")
    }

    func test_applyMove_two_clears_reversal() {
        var state = makeSimpleState()
        state.reversalActive = true
        state.currentTurn = .ai
        let two = Card(suit: .clubs, rank: .two)
        state.ai.hand = [two]
        state.discardPile = [Card(suit: .hearts, rank: .seven)]
        let result = GameEngine.applyMove([two], by: .ai, state: state)
        XCTAssertFalse(result.reversalActive, "2 (reset) should clear reversal")
    }

    // MARK: - Full scenario: Human plays 7, AI must play < 7

    func test_scenario_human_plays_7_ai_cannot_play_8() {
        var state = makeSimpleState()
        // Human plays 7
        let seven = Card(suit: .hearts, rank: .seven)
        state.human.hand = [seven, Card(suit: .spades, rank: .four), Card(suit: .clubs, rank: .four)]
        state.discardPile = [Card(suit: .hearts, rank: .five)]
        state = GameEngine.applyMove([seven], by: .human, state: state)

        // Now it's AI's turn with reversal active
        XCTAssertTrue(state.reversalActive)
        XCTAssertEqual(state.currentTurn, .ai)

        // AI has only 8 — should have NO legal moves
        state.ai.hand = [Card(suit: .diamonds, rank: .eight)]
        let moves = GameEngine.legalMoves(for: .ai, in: state)
        XCTAssertTrue(moves.isEmpty, "AI with only 8 should have no moves during reversal")

        // Verify 8 specifically is blocked
        let canPlay8 = RuleValidator.canPlay(
            [Card(suit: .diamonds, rank: .eight)],
            on: state.discardPile,
            reversalActive: state.reversalActive
        )
        XCTAssertFalse(canPlay8, "8 MUST be blocked when reversal is active")
    }

    // MARK: - Pickup & Win

    func test_pickUpPile_moves_pile_to_hand() {
        var state = makeSimpleState()
        state.discardPile = [Card(suit: .hearts, rank: .five), Card(suit: .spades, rank: .nine)]
        state.human.hand = [Card(suit: .hearts, rank: .two)]
        let result = GameEngine.pickUpPile(for: .human, state: state)
        XCTAssertTrue(result.discardPile.isEmpty)
        XCTAssertEqual(result.human.hand.count, 3)
        XCTAssertEqual(result.currentTurn, .ai)
    }

    func test_checkWinCondition_detects_empty() {
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

    // MARK: - Helper

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
