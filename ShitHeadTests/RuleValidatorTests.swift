// SheetHeadTests/RuleValidatorTests.swift
import XCTest
@testable import SheetHead

final class RuleValidatorTests: XCTestCase {
    func card(_ rank: Rank, _ suit: Suit = .hearts) -> Card { Card(suit: suit, rank: rank) }
    func pile(_ ranks: Rank...) -> [Card] { ranks.map { card($0) } }

    // MARK: - Basic play rules

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

    func test_six_cannot_play_on_seven_normal() {
        // In NORMAL mode (no reversal), 6 < 7, so blocked
        XCTAssertFalse(RuleValidator.canPlay([card(.six)], on: pile(.seven), reversalActive: false))
    }

    func test_eight_cannot_play_on_nine() {
        XCTAssertFalse(RuleValidator.canPlay([card(.eight)], on: pile(.nine), reversalActive: false))
    }

    func test_eight_cannot_play_on_king() {
        XCTAssertFalse(RuleValidator.canPlay([card(.eight)], on: pile(.king), reversalActive: false))
    }

    func test_eight_can_play_on_lower() {
        XCTAssertTrue(RuleValidator.canPlay([card(.eight)], on: pile(.five), reversalActive: false))
        XCTAssertTrue(RuleValidator.canPlay([card(.eight)], on: pile(.eight), reversalActive: false))
    }

    // MARK: - Special card: 2 (always playable, resets)

    func test_two_always_playable_on_any_card() {
        XCTAssertTrue(RuleValidator.canPlay([card(.two)], on: pile(.ace), reversalActive: false))
        XCTAssertTrue(RuleValidator.canPlay([card(.two)], on: pile(.king), reversalActive: false))
    }

    func test_two_always_playable_in_reversal() {
        XCTAssertTrue(RuleValidator.canPlay([card(.two)], on: pile(.ace), reversalActive: true))
    }

    // MARK: - Special card: 3 (always playable, transparent)

    func test_three_always_playable() {
        XCTAssertTrue(RuleValidator.canPlay([card(.three)], on: pile(.ace), reversalActive: false))
        XCTAssertTrue(RuleValidator.canPlay([card(.three)], on: pile(.king), reversalActive: false))
    }

    func test_three_playable_during_reversal() {
        XCTAssertTrue(RuleValidator.canPlay([card(.three)], on: pile(.seven), reversalActive: true))
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

    // MARK: - Special card: 10 (always playable, burns)

    func test_ten_always_playable() {
        XCTAssertTrue(RuleValidator.canPlay([card(.ten)], on: pile(.ace), reversalActive: false))
    }

    func test_ten_playable_during_reversal() {
        XCTAssertTrue(RuleValidator.canPlay([card(.ten)], on: pile(.seven), reversalActive: true))
    }

    // MARK: - Special card: 7 (reversal trigger)

    func test_seven_can_be_played_on_lower() {
        XCTAssertTrue(RuleValidator.canPlay([card(.seven)], on: pile(.six), reversalActive: false))
        XCTAssertTrue(RuleValidator.canPlay([card(.seven)], on: pile(.four), reversalActive: false))
    }

    func test_seven_can_be_played_on_seven() {
        XCTAssertTrue(RuleValidator.canPlay([card(.seven)], on: pile(.seven), reversalActive: false),
                      "7 on 7 should be allowed (equal)")
    }

    func test_seven_cannot_be_played_on_higher() {
        XCTAssertFalse(RuleValidator.canPlay([card(.seven)], on: pile(.eight), reversalActive: false))
        XCTAssertFalse(RuleValidator.canPlay([card(.seven)], on: pile(.king), reversalActive: false))
        XCTAssertFalse(RuleValidator.canPlay([card(.seven)], on: pile(.ace), reversalActive: false))
    }

    func test_seven_playable_on_empty_pile() {
        XCTAssertTrue(RuleValidator.canPlay([card(.seven)], on: [], reversalActive: false))
    }

    // MARK: - Reversal (after a 7)

    func test_reversal_allows_lower_than_seven() {
        XCTAssertTrue(RuleValidator.canPlay([card(.four)], on: pile(.seven), reversalActive: true))
        XCTAssertTrue(RuleValidator.canPlay([card(.five)], on: pile(.seven), reversalActive: true))
        XCTAssertTrue(RuleValidator.canPlay([card(.six)], on: pile(.seven), reversalActive: true))
    }

    func test_reversal_allows_seven_to_chain() {
        XCTAssertTrue(RuleValidator.canPlay([card(.seven, .clubs)], on: pile(.seven), reversalActive: true),
                      "7 chains reversal to next player")
    }

    func test_reversal_blocks_eight() {
        XCTAssertFalse(RuleValidator.canPlay([card(.eight)], on: pile(.seven), reversalActive: true),
                       "8 is NOT lower than 7")
    }

    func test_reversal_blocks_nine() {
        XCTAssertFalse(RuleValidator.canPlay([card(.nine)], on: pile(.seven), reversalActive: true))
    }

    func test_reversal_blocks_jack() {
        XCTAssertFalse(RuleValidator.canPlay([card(.jack)], on: pile(.seven), reversalActive: true))
    }

    func test_reversal_blocks_queen() {
        XCTAssertFalse(RuleValidator.canPlay([card(.queen)], on: pile(.seven), reversalActive: true))
    }

    func test_reversal_blocks_king() {
        XCTAssertFalse(RuleValidator.canPlay([card(.king)], on: pile(.seven), reversalActive: true))
    }

    func test_reversal_blocks_ace() {
        XCTAssertFalse(RuleValidator.canPlay([card(.ace)], on: pile(.seven), reversalActive: true),
                       "Ace is HIGH (14), not playable during reversal")
    }

    func test_reversal_allows_special_cards() {
        XCTAssertTrue(RuleValidator.canPlay([card(.two)], on: pile(.seven), reversalActive: true))
        XCTAssertTrue(RuleValidator.canPlay([card(.three)], on: pile(.seven), reversalActive: true))
        XCTAssertTrue(RuleValidator.canPlay([card(.ten)], on: pile(.seven), reversalActive: true))
    }

    // MARK: - 4-of-a-kind bomb

    func test_isBomb_triggers_on_fourth_card() {
        let existingPile = pile(.six, .six, .six)
        XCTAssertTrue(RuleValidator.isBomb(pile: existingPile, adding: [card(.six, .spades)]))
    }

    func test_isBomb_false_on_three_cards() {
        let existingPile = pile(.six, .six)
        XCTAssertFalse(RuleValidator.isBomb(pile: existingPile, adding: [card(.six, .spades)]))
    }

    func test_isBomb_four_played_at_once() {
        let adding = [card(.six, .hearts), card(.six, .spades), card(.six, .diamonds), card(.six, .clubs)]
        XCTAssertTrue(RuleValidator.isBomb(pile: [], adding: adding))
    }

    // MARK: - Multi-card plays

    func test_multicard_play_same_rank() {
        let cards = [card(.five, .hearts), card(.five, .spades)]
        XCTAssertTrue(RuleValidator.canPlay(cards, on: pile(.four), reversalActive: false))
    }

    func test_multicard_mixed_rank_blocked() {
        let cards = [card(.five), card(.six)]
        XCTAssertFalse(RuleValidator.canPlay(cards, on: pile(.four), reversalActive: false))
    }

    func test_empty_cards_cannot_play() {
        XCTAssertFalse(RuleValidator.canPlay([], on: [], reversalActive: false))
    }
}
