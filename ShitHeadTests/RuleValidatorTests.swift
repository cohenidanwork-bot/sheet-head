// ShitHeadTests/RuleValidatorTests.swift
import XCTest
@testable import ShitHead

final class RuleValidatorTests: XCTestCase {
    func card(_ rank: Rank, _ suit: Suit = .hearts) -> Card { Card(suit: suit, rank: rank) }
    func pile(_ ranks: Rank...) -> [Card] { ranks.map { card($0) } }

    func test_canPlay_on_empty_pile_always_true() {
        XCTAssertTrue(RuleValidator.canPlay([card(.five)], on: [], reversalActive: false))
        XCTAssertTrue(RuleValidator.canPlay([card(.ace)], on: [], reversalActive: false))
    }

    func test_canPlay_higher_card() {
        XCTAssertTrue(RuleValidator.canPlay([card(.king)], on: pile(.queen), reversalActive: false))
    }

    func test_canPlay_equal_card() {
        XCTAssertTrue(RuleValidator.canPlay([card(.nine)], on: pile(.nine), reversalActive: false))
    }

    func test_cannot_play_lower_card() {
        XCTAssertFalse(RuleValidator.canPlay([card(.five)], on: pile(.nine), reversalActive: false))
    }

    func test_two_always_playable_on_any_card() {
        XCTAssertTrue(RuleValidator.canPlay([card(.two)], on: pile(.ace), reversalActive: false))
        XCTAssertTrue(RuleValidator.canPlay([card(.two)], on: pile(.king), reversalActive: false))
    }

    func test_two_always_playable_in_reversal() {
        XCTAssertTrue(RuleValidator.canPlay([card(.two)], on: pile(.ace), reversalActive: true))
    }

    func test_three_always_playable() {
        XCTAssertTrue(RuleValidator.canPlay([card(.three)], on: pile(.ace), reversalActive: false))
        XCTAssertTrue(RuleValidator.canPlay([card(.three)], on: pile(.king), reversalActive: false))
    }

    func test_ten_always_playable() {
        XCTAssertTrue(RuleValidator.canPlay([card(.ten)], on: pile(.ace), reversalActive: false))
    }

    func test_effectiveTopRank_skips_threes() {
        XCTAssertEqual(RuleValidator.effectiveTopRank(of: pile(.king, .three, .three)), .king)
    }

    func test_effectiveTopRank_all_threes_returns_nil() {
        XCTAssertNil(RuleValidator.effectiveTopRank(of: pile(.three, .three)))
    }

    func test_effectiveTopRank_empty_pile_returns_nil() {
        XCTAssertNil(RuleValidator.effectiveTopRank(of: []))
    }

    func test_canPlay_respects_card_under_three() {
        XCTAssertTrue(RuleValidator.canPlay([card(.ace)], on: pile(.king, .three), reversalActive: false))
        XCTAssertFalse(RuleValidator.canPlay([card(.queen)], on: pile(.king, .three), reversalActive: false))
    }

    func test_seven_can_be_played_on_card_lower_than_seven() {
        XCTAssertTrue(RuleValidator.canPlay([card(.seven)], on: pile(.six), reversalActive: false))
        XCTAssertTrue(RuleValidator.canPlay([card(.seven)], on: pile(.two), reversalActive: false))
    }

    func test_seven_cannot_be_played_on_card_higher_than_seven() {
        XCTAssertFalse(RuleValidator.canPlay([card(.seven)], on: pile(.eight), reversalActive: false))
        XCTAssertFalse(RuleValidator.canPlay([card(.seven)], on: pile(.king), reversalActive: false))
    }

    func test_seven_cannot_be_played_on_another_seven() {
        XCTAssertFalse(RuleValidator.canPlay([card(.seven)], on: pile(.seven), reversalActive: false))
    }

    func test_seven_can_be_played_on_ace_low() {
        XCTAssertTrue(RuleValidator.canPlay([card(.seven)], on: pile(.ace), reversalActive: false))
    }

    func test_reversal_requires_lower_than_seven() {
        XCTAssertTrue(RuleValidator.canPlay([card(.six)], on: pile(.seven), reversalActive: true))
        XCTAssertFalse(RuleValidator.canPlay([card(.eight)], on: pile(.seven), reversalActive: true))
        XCTAssertFalse(RuleValidator.canPlay([card(.seven)], on: pile(.seven), reversalActive: true))
    }

    func test_reversal_ace_counts_as_low() {
        XCTAssertTrue(RuleValidator.canPlay([card(.ace)], on: pile(.seven), reversalActive: true))
    }

    func test_two_overrides_reversal() {
        XCTAssertTrue(RuleValidator.canPlay([card(.two)], on: pile(.seven), reversalActive: true))
    }

    func test_three_overrides_reversal() {
        XCTAssertTrue(RuleValidator.canPlay([card(.three)], on: pile(.seven), reversalActive: true))
    }

    func test_multicard_play_must_be_same_rank() {
        let cards = [card(.five, .hearts), card(.five, .spades)]
        XCTAssertTrue(RuleValidator.canPlay(cards, on: pile(.four), reversalActive: false))
    }

    func test_multicard_mixed_rank_is_illegal() {
        let cards = [card(.five), card(.six)]
        XCTAssertFalse(RuleValidator.canPlay(cards, on: pile(.four), reversalActive: false))
    }

    func test_isBomb_triggers_on_fourth_card() {
        let existingPile = pile(.six, .six, .six)
        let adding = [card(.six, .spades)]
        XCTAssertTrue(RuleValidator.isBomb(pile: existingPile, adding: adding))
    }

    func test_isBomb_false_on_three_cards() {
        let existingPile = pile(.six, .six)
        let adding = [card(.six, .spades)]
        XCTAssertFalse(RuleValidator.isBomb(pile: existingPile, adding: adding))
    }

    func test_isBomb_four_played_at_once() {
        let adding = [card(.six, .hearts), card(.six, .spades), card(.six, .diamonds), card(.six, .clubs)]
        XCTAssertTrue(RuleValidator.isBomb(pile: [], adding: adding))
    }
}
