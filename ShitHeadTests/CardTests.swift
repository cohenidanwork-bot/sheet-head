import XCTest
@testable import ShitHead

final class CardTests: XCTestCase {
    func test_rank_rawValues_are_correct() {
        XCTAssertEqual(Rank.two.rawValue, 2)
        XCTAssertEqual(Rank.ten.rawValue, 10)
        XCTAssertEqual(Rank.jack.rawValue, 11)
        XCTAssertEqual(Rank.queen.rawValue, 12)
        XCTAssertEqual(Rank.king.rawValue, 13)
        XCTAssertEqual(Rank.ace.rawValue, 14)
    }

    func test_rank_comparison() {
        XCTAssertTrue(Rank.king > Rank.queen)
        XCTAssertTrue(Rank.two < Rank.three)
        XCTAssertTrue(Rank.ace > Rank.king)
    }

    func test_card_identity_is_unique() {
        let c1 = Card(suit: .hearts, rank: .ace)
        let c2 = Card(suit: .spades, rank: .ace)
        XCTAssertNotEqual(c1.id, c2.id)
    }

    func test_full_deck_has_52_cards() {
        let deck = Card.fullDeck()
        XCTAssertEqual(deck.count, 52)
        XCTAssertEqual(Set(deck.map(\.id)).count, 52)
    }
}
