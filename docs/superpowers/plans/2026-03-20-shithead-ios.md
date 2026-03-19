# Shit Head iOS Game — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a fully playable iOS card game "Shit Head" with SwiftUI — 1 human vs 1 AI opponent, Easy/Hard difficulty, green felt UI, all special card rules implemented.

**Architecture:** Pure-logic Game Engine + AI Player at the bottom, GameViewModel bridging to SwiftUI views at the top. Layers communicate through well-defined interfaces so the AI can be replaced with a network player in future.

**Tech Stack:** Swift 5.9, SwiftUI, XCTest, xcodegen (project scaffolding)

---

## File Map

```
ShitHead/
├── project.yml                        # xcodegen project definition
├── ShitHead/
│   ├── ShitHeadApp.swift              # @main entry point, app lifecycle
│   ├── Models/
│   │   ├── Card.swift                 # Suit, Rank enums + Card struct
│   │   └── GameState.swift            # GameState, PlayerState, PlayerID, GamePhase, CardPhase
│   ├── Engine/
│   │   ├── RuleValidator.swift        # canPlay(), effectiveTopRank(), isBomb()
│   │   └── GameEngine.swift           # applyMove(), setupGame(), drawCards(), win detection
│   ├── AI/
│   │   ├── PlayerProtocol.swift       # PlayerProtocol definition
│   │   ├── EasyAIPlayer.swift         # Random legal move picker
│   │   └── HardAIPlayer.swift         # Strategic AI
│   ├── ViewModels/
│   │   └── GameViewModel.swift        # ObservableObject, bridges engine ↔ views, AI timer
│   ├── Views/
│   │   ├── HomeView.swift             # Title, difficulty picker, New Game button
│   │   ├── SetupView.swift            # Pick 3 face-up cards from 6
│   │   ├── GameView.swift             # Main table layout
│   │   ├── GameOverView.swift         # Result screen
│   │   └── CardView.swift             # Reusable card component
│   └── Persistence/
│       └── GamePersistence.swift      # Codable save/load via UserDefaults
└── ShitHeadTests/
    ├── CardTests.swift
    ├── RuleValidatorTests.swift
    ├── GameEngineTests.swift
    └── AIPlayerTests.swift
```

---

## Prerequisites

Ensure Xcode is installed (`xcode-select -p` should return a path).
Install xcodegen if not present: `brew install xcodegen`
Test runner command used throughout:
```bash
xcodebuild test -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(passed|failed|error:|warning:)"
```

---

## Task 1: Project Scaffold

**Files:**
- Create: `project.yml`
- Create: `ShitHead/ShitHeadApp.swift`
- Create: `ShitHead/Info.plist`
- Create: `ShitHeadTests/ShitHeadTests.swift` (placeholder)

- [ ] **Step 1: Create project.yml**

```yaml
name: ShitHead
options:
  bundleIdPrefix: com.idancoh
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "16"
settings:
  base:
    SWIFT_VERSION: "5.9"
    MARKETING_VERSION: "1.0"
    CURRENT_PROJECT_VERSION: "1"
targets:
  ShitHead:
    type: application
    platform: iOS
    sources:
      - path: ShitHead
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.idancoh.shithead
        INFOPLIST_FILE: ShitHead/Info.plist
  ShitHeadTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: ShitHeadTests
    dependencies:
      - target: ShitHead
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.idancoh.shithead.tests
```

- [ ] **Step 2: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 3: Create ShitHeadApp.swift**

```swift
import SwiftUI

@main
struct ShitHeadApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
```

- [ ] **Step 4: Create ShitHeadTests/ShitHeadTests.swift**

```swift
import XCTest
@testable import ShitHead
```

- [ ] **Step 5: Create all required directories and generate Xcode project**

```bash
cd "/Users/idancoh/Sheet Head"
mkdir -p ShitHead/Models ShitHead/Engine ShitHead/AI ShitHead/ViewModels ShitHead/Views ShitHead/Persistence ShitHeadTests
xcodegen generate
```

Expected: `ShitHead.xcodeproj` created with no errors.

- [ ] **Step 6: Verify project builds**

```bash
xcodebuild build -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 7: Commit**

```bash
cd "/Users/idancoh/Sheet Head"
git init
git add .
git commit -m "feat: initial Xcode project scaffold via xcodegen"
```

---

## Task 2: Card Model

**Files:**
- Create: `ShitHead/Models/Card.swift`
- Create: `ShitHeadTests/CardTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
// ShitHeadTests/CardTests.swift
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
        XCTAssertEqual(Set(deck.map(\.id)).count, 52) // all unique
    }
}
```

- [ ] **Step 2: Run tests — expect FAIL (types not defined)**

```bash
xcodebuild test -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(passed|failed|error:)"
```

- [ ] **Step 3: Implement Card.swift**

```swift
// ShitHead/Models/Card.swift
import Foundation

enum Suit: String, CaseIterable, Codable, Hashable {
    case hearts = "♥"
    case diamonds = "♦"
    case clubs = "♣"
    case spades = "♠"
}

enum Rank: Int, CaseIterable, Codable, Comparable, Hashable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen = 12, king = 13, ace = 14

    static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var display: String {
        switch self {
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        default: return "\(rawValue)"
        }
    }
}

struct Card: Identifiable, Hashable, Codable {
    let suit: Suit
    let rank: Rank

    var id: String { "\(rank.rawValue)-\(suit.rawValue)" }

    /// Ace is treated as low (value 1) when checking the 7-reversal constraint.
    var countsAsLowForReversal: Bool {
        rank == .ace
    }

    static func fullDeck() -> [Card] {
        Suit.allCases.flatMap { suit in
            Rank.allCases.map { rank in Card(suit: suit, rank: rank) }
        }
    }
}
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
xcodebuild test -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(passed|failed|error:)"
```

- [ ] **Step 5: Commit**

```bash
git add ShitHead/Models/Card.swift ShitHeadTests/CardTests.swift
git commit -m "feat: Card model with Suit, Rank, full deck generation"
```

---

## Task 3: Game State Model

**Files:**
- Create: `ShitHead/Models/GameState.swift`

No unit tests needed — this is a pure data container with no logic.

- [ ] **Step 1: Create GameState.swift**

```swift
// ShitHead/Models/GameState.swift
import Foundation

enum PlayerID: String, Codable, Hashable {
    case human, ai
}

/// Which pool of cards the player is currently drawing from
enum CardPhase: Codable, Equatable {
    case hand       // Playing from hand (deck refills hand)
    case faceUp     // Hand empty; playing face-up table cards
    case faceDown   // All visible cards gone; blind draw from face-down
}

enum AppPhase: Codable, Equatable {
    case home
    case setup      // Player selecting face-up cards
    case playing
    case gameOver(winner: PlayerID, shitHead: PlayerID)
}

struct PlayerState: Codable, Equatable {
    var hand: [Card]
    var faceUp: [Card]      // 3 face-up table cards (visible to all)
    var faceDown: [Card]    // 3 face-down table cards (blind)

    var cardPhase: CardPhase {
        if !hand.isEmpty { return .hand }
        if !faceUp.isEmpty { return .faceUp }
        return .faceDown
    }

    var hasCards: Bool {
        !hand.isEmpty || !faceUp.isEmpty || !faceDown.isEmpty
    }
}

struct GameState: Codable, Equatable {
    var deck: [Card]
    var discardPile: [Card]     // top of pile = last element
    var human: PlayerState
    var ai: PlayerState
    var currentTurn: PlayerID
    var reversalActive: Bool    // 7 effect: next player must play < 7
    var bonusTurn: Bool         // 10 / bomb: same player goes again

    var topOfPile: Card? { discardPile.last }
}
```

- [ ] **Step 2: Build to verify no compile errors**

```bash
xcodebuild build -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(error:|BUILD)"
```

- [ ] **Step 3: Commit**

```bash
git add ShitHead/Models/GameState.swift
git commit -m "feat: GameState, PlayerState, PlayerID, CardPhase models"
```

---

## Task 4: Rule Validator

**Files:**
- Create: `ShitHead/Engine/RuleValidator.swift`
- Create: `ShitHeadTests/RuleValidatorTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
// ShitHeadTests/RuleValidatorTests.swift
import XCTest
@testable import ShitHead

final class RuleValidatorTests: XCTestCase {
    // MARK: - Helpers
    func card(_ rank: Rank, _ suit: Suit = .hearts) -> Card { Card(suit: suit, rank: rank) }
    func pile(_ ranks: Rank...) -> [Card] { ranks.map { card($0) } }

    // MARK: - Empty pile
    func test_canPlay_on_empty_pile_always_true() {
        XCTAssertTrue(RuleValidator.canPlay([card(.five)], on: [], reversalActive: false))
        XCTAssertTrue(RuleValidator.canPlay([card(.ace)], on: [], reversalActive: false))
    }

    // MARK: - Normal play (higher or equal)
    func test_canPlay_higher_card() {
        XCTAssertTrue(RuleValidator.canPlay([card(.king)], on: pile(.queen), reversalActive: false))
    }

    func test_canPlay_equal_card() {
        XCTAssertTrue(RuleValidator.canPlay([card(.nine)], on: pile(.nine), reversalActive: false))
    }

    func test_cannot_play_lower_card() {
        XCTAssertFalse(RuleValidator.canPlay([card(.five)], on: pile(.nine), reversalActive: false))
    }

    // MARK: - Special 2 (always playable)
    func test_two_always_playable_on_any_card() {
        XCTAssertTrue(RuleValidator.canPlay([card(.two)], on: pile(.ace), reversalActive: false))
        XCTAssertTrue(RuleValidator.canPlay([card(.two)], on: pile(.king), reversalActive: false))
    }

    func test_two_always_playable_in_reversal() {
        XCTAssertTrue(RuleValidator.canPlay([card(.two)], on: pile(.ace), reversalActive: true))
    }

    // MARK: - Special 3 (transparent — always playable)
    func test_three_always_playable() {
        XCTAssertTrue(RuleValidator.canPlay([card(.three)], on: pile(.ace), reversalActive: false))
        XCTAssertTrue(RuleValidator.canPlay([card(.three)], on: pile(.king), reversalActive: false))
    }

    // MARK: - Special 10 (always playable)
    func test_ten_always_playable() {
        XCTAssertTrue(RuleValidator.canPlay([card(.ten)], on: pile(.ace), reversalActive: false))
    }

    // MARK: - Effective top rank (3 transparency)
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
        // Pile: [king, 3] — effective top is king. Must play >= king
        XCTAssertTrue(RuleValidator.canPlay([card(.ace)], on: pile(.king, .three), reversalActive: false))
        XCTAssertFalse(RuleValidator.canPlay([card(.queen)], on: pile(.king, .three), reversalActive: false))
    }

    // MARK: - Special 7 (reverser)
    func test_seven_can_be_played_on_card_lower_than_seven() {
        XCTAssertTrue(RuleValidator.canPlay([card(.seven)], on: pile(.six), reversalActive: false))
        XCTAssertTrue(RuleValidator.canPlay([card(.seven)], on: pile(.two), reversalActive: false))
    }

    func test_seven_cannot_be_played_on_card_higher_than_seven() {
        XCTAssertFalse(RuleValidator.canPlay([card(.seven)], on: pile(.eight), reversalActive: false))
        XCTAssertFalse(RuleValidator.canPlay([card(.seven)], on: pile(.king), reversalActive: false))
    }

    func test_seven_can_be_played_on_another_seven() {
        // 7 on 7: 7 == 7, not lower — should be false per spec (must be lower than 7)
        XCTAssertFalse(RuleValidator.canPlay([card(.seven)], on: pile(.seven), reversalActive: false))
    }

    func test_seven_can_be_played_on_ace_low() {
        // Ace counts as low for the 7 constraint
        XCTAssertTrue(RuleValidator.canPlay([card(.seven)], on: pile(.ace), reversalActive: false))
    }

    // MARK: - Reversal active (after a 7)
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

    // MARK: - Multi-card plays
    func test_multicard_play_must_be_same_rank() {
        let cards = [card(.five, .hearts), card(.five, .spades)]
        XCTAssertTrue(RuleValidator.canPlay(cards, on: pile(.four), reversalActive: false))
    }

    func test_multicard_mixed_rank_is_illegal() {
        let cards = [card(.five), card(.six)]
        XCTAssertFalse(RuleValidator.canPlay(cards, on: pile(.four), reversalActive: false))
    }

    // MARK: - Bomb detection
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
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
xcodebuild test -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(passed|failed|error:)"
```

- [ ] **Step 3: Implement RuleValidator.swift**

```swift
// ShitHead/Engine/RuleValidator.swift
import Foundation

enum RuleValidator {
    /// Returns the effective top rank of the pile, skipping transparent 3s.
    /// Returns nil if pile is empty or all cards are 3s.
    static func effectiveTopRank(of pile: [Card]) -> Rank? {
        for card in pile.reversed() {
            if card.rank != .three { return card.rank }
        }
        return nil
    }

    /// Returns true if adding `cards` to `pile` completes a 4-of-a-kind bomb.
    static func isBomb(pile: [Card], adding cards: [Card]) -> Bool {
        guard let rank = cards.first?.rank else { return false }
        let countInPile = pile.filter { $0.rank == rank }.count
        let countAdding = cards.filter { $0.rank == rank }.count
        return countInPile + countAdding >= 4
    }

    /// Returns true if `cards` can legally be played on the current `pile`.
    static func canPlay(_ cards: [Card], on pile: [Card], reversalActive: Bool) -> Bool {
        guard !cards.isEmpty else { return false }
        guard let rank = cards.first?.rank else { return false }
        // All cards must share the same rank
        guard cards.allSatisfy({ $0.rank == rank }) else { return false }

        // 2, 3, 10 can always be played
        if rank == .two || rank == .three || rank == .ten { return true }

        let effectiveTop = effectiveTopRank(of: pile)

        // Reversal active (7 was played): must play < 7, ace counts as low
        if reversalActive {
            if rank == .ace { return true }   // ace counts as 1 (low)
            if rank == .seven { return false } // 7 cannot be played during reversal
            return rank.rawValue < 7
        }

        // 7 can only be played on a card with effective value < 7 (ace counts as low)
        if rank == .seven {
            guard let top = effectiveTop else { return true } // empty pile ok
            if top == .ace { return true } // ace is low for this check
            return top.rawValue < 7
        }

        // Normal play: must be >= effective top
        guard let top = effectiveTop else { return true } // empty pile, anything goes
        return rank >= top
    }
}
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
xcodebuild test -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(passed|failed|error:)"
```

- [ ] **Step 5: Commit**

```bash
git add ShitHead/Engine/RuleValidator.swift ShitHeadTests/RuleValidatorTests.swift
git commit -m "feat: RuleValidator with full special card and reversal logic"
```

---

## Task 5: Game Engine

**Files:**
- Create: `ShitHead/Engine/GameEngine.swift`
- Create: `ShitHeadTests/GameEngineTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
// ShitHeadTests/GameEngineTests.swift
import XCTest
@testable import ShitHead

final class GameEngineTests: XCTestCase {
    // MARK: - Setup
    func test_setupGame_deals_correct_cards() {
        let state = GameEngine.setupGame(difficulty: .easy)
        XCTAssertEqual(state.human.faceDown.count, 3)
        XCTAssertEqual(state.human.faceUp.count, 0)   // not set until setup screen
        XCTAssertEqual(state.human.hand.count, 6)      // 6 to choose from
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

    // MARK: - Legal moves
    func test_legalMoves_returns_playable_cards() {
        var state = makeSimpleState()
        // pile has a 5, hand has a 6 and a 3
        state.discardPile = [Card(suit: .hearts, rank: .five)]
        state.human.hand = [Card(suit: .hearts, rank: .six), Card(suit: .hearts, rank: .three)]
        let moves = GameEngine.legalMoves(for: .human, in: state)
        XCTAssertTrue(moves.contains(where: { $0 == [Card(suit: .hearts, rank: .six)] }))
        XCTAssertTrue(moves.contains(where: { $0 == [Card(suit: .hearts, rank: .three)] }))
    }

    func test_legalMoves_empty_when_no_playable_card() {
        var state = makeSimpleState()
        state.discardPile = [Card(suit: .hearts, rank: .ace)]
        state.human.hand = [Card(suit: .hearts, rank: .five)]
        let moves = GameEngine.legalMoves(for: .human, in: state)
        XCTAssertTrue(moves.isEmpty)
    }

    // MARK: - Normal play
    func test_applyMove_places_card_on_pile() {
        var state = makeSimpleState()
        let card = Card(suit: .hearts, rank: .six)
        state.human.hand = [card]
        state.discardPile = [Card(suit: .hearts, rank: .five)]
        let result = GameEngine.applyMove([card], by: .human, state: state)
        XCTAssertEqual(result.discardPile.last?.rank, .six)
        XCTAssertFalse(result.human.hand.contains(card))
    }

    func test_applyMove_draws_after_playing() {
        var state = makeSimpleState()
        let card = Card(suit: .hearts, rank: .six)
        state.human.hand = [card]
        state.deck = Array(Card.fullDeck().filter { $0.id != card.id }.prefix(5))
        state.discardPile = [Card(suit: .hearts, rank: .five)]
        let result = GameEngine.applyMove([card], by: .human, state: state)
        XCTAssertEqual(result.human.hand.count, min(3, result.deck.count + 1))
    }

    // MARK: - Special: 10 burns
    func test_applyMove_ten_burns_pile_and_gives_bonus_turn() {
        var state = makeSimpleState()
        let ten = Card(suit: .hearts, rank: .ten)
        state.human.hand = [ten]
        state.discardPile = [Card(suit: .spades, rank: .king)]
        let result = GameEngine.applyMove([ten], by: .human, state: state)
        XCTAssertTrue(result.discardPile.isEmpty)
        XCTAssertTrue(result.bonusTurn)
        XCTAssertEqual(result.currentTurn, .human) // still human's turn
    }

    // MARK: - Special: 8 skip
    func test_applyMove_eight_skips_opponent_in_two_player() {
        var state = makeSimpleState()
        let eight = Card(suit: .hearts, rank: .eight)
        state.human.hand = [eight]
        state.discardPile = [Card(suit: .hearts, rank: .seven)]
        let result = GameEngine.applyMove([eight], by: .human, state: state)
        // In 2-player, skip = same player's bonus turn
        XCTAssertEqual(result.currentTurn, .human)
        XCTAssertTrue(result.bonusTurn)
    }

    // MARK: - Special: 7 activates reversal
    func test_applyMove_seven_activates_reversal() {
        var state = makeSimpleState()
        let seven = Card(suit: .hearts, rank: .seven)
        state.human.hand = [seven]
        state.discardPile = [Card(suit: .hearts, rank: .six)]
        let result = GameEngine.applyMove([seven], by: .human, state: state)
        XCTAssertTrue(result.reversalActive)
        XCTAssertEqual(result.currentTurn, .ai)
    }

    // MARK: - Pick up pile
    func test_pickUpPile_moves_pile_to_hand() {
        var state = makeSimpleState()
        let pileCards = [Card(suit: .hearts, rank: .five), Card(suit: .spades, rank: .nine)]
        state.discardPile = pileCards
        state.human.hand = [Card(suit: .hearts, rank: .two)]
        let result = GameEngine.pickUpPile(for: .human, state: state)
        XCTAssertTrue(result.discardPile.isEmpty)
        XCTAssertEqual(result.human.hand.count, 3) // 1 original + 2 from pile
        XCTAssertEqual(result.currentTurn, .ai)
    }

    // MARK: - Win detection
    func test_checkWin_detects_empty_hand() {
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

    // MARK: - Helpers
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
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
xcodebuild test -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(passed|failed|error:)"
```

- [ ] **Step 3: Implement GameEngine.swift**

```swift
// ShitHead/Engine/GameEngine.swift
import Foundation

enum Difficulty: String, Codable {
    case easy, hard
}

enum GameEngine {
    // MARK: - Setup

    static func setupGame(difficulty: Difficulty) -> GameState {
        var deck = Card.fullDeck().shuffled()

        func deal(_ n: Int) -> [Card] {
            let cards = Array(deck.prefix(n))
            deck.removeFirst(n)
            return cards
        }

        let humanFaceDown = deal(3)
        let aiFaceDown = deal(3)
        let humanSixCards = deal(6)
        let aiSixCards = deal(6)

        // AI picks its best face-up cards immediately
        let aiFaceUp: [Card]
        let aiHand: [Card]
        switch difficulty {
        case .easy:
            aiFaceUp = Array(aiSixCards.prefix(3))
            aiHand = Array(aiSixCards.suffix(3))
        case .hard:
            let sorted = aiSixCards.sorted { $0.rank > $1.rank }
            aiFaceUp = Array(sorted.prefix(3))
            aiHand = Array(sorted.suffix(3))
        }

        return GameState(
            deck: deck,
            discardPile: [],
            human: PlayerState(hand: humanSixCards, faceUp: [], faceDown: humanFaceDown),
            ai: PlayerState(hand: aiHand, faceUp: aiFaceUp, faceDown: aiFaceDown),
            currentTurn: .human,
            reversalActive: false,
            bonusTurn: false
        )
    }

    /// Called after player selects 3 face-up cards from their 6
    static func confirmPlayerSetup(state: GameState, faceUpCards: [Card]) -> GameState {
        var s = state
        let remaining = state.human.hand.filter { !faceUpCards.contains($0) }
        s.human.faceUp = faceUpCards
        s.human.hand = remaining
        return s
    }

    // MARK: - Move Queries

    /// All legal single-card and multi-card moves for a player in the current state.
    static func legalMoves(for player: PlayerID, in state: GameState) -> [[Card]] {
        let playerState = player == .human ? state.human : state.ai
        let available: [Card]
        switch playerState.cardPhase {
        case .hand: available = playerState.hand
        case .faceUp: available = playerState.faceUp
        case .faceDown: return [] // face-down: no legal move query (blind draw)
        }

        // Group by rank
        var byRank: [Rank: [Card]] = [:]
        for card in available {
            byRank[card.rank, default: []].append(card)
        }

        var moves: [[Card]] = []
        for (_, cards) in byRank {
            // Single card
            if RuleValidator.canPlay([cards[0]], on: state.discardPile, reversalActive: state.reversalActive) {
                for i in 0..<cards.count {
                    // Generate all subset sizes (1 to count) for same rank
                    for size in 1...cards.count {
                        let combo = Array(cards[0..<size])
                        if combo.count == size && !moves.contains(combo) {
                            if RuleValidator.canPlay(combo, on: state.discardPile, reversalActive: state.reversalActive) {
                                moves.append(combo)
                            }
                        }
                        _ = i // suppress warning
                    }
                    break // already iterated all sizes
                }
            }
        }
        return moves
    }

    // MARK: - Apply Move

    static func applyMove(_ cards: [Card], by player: PlayerID, state: GameState) -> GameState {
        var s = state
        var played = player == .human ? s.human : s.ai

        // Remove cards from player's pool
        switch played.cardPhase {
        case .hand:
            played.hand.removeAll { cards.contains($0) }
        case .faceUp:
            played.faceUp.removeAll { cards.contains($0) }
        case .faceDown:
            played.faceDown.removeAll { cards.contains($0) }
        }

        if player == .human { s.human = played } else { s.ai = played }

        // Check bomb before adding to pile
        let isBomb = RuleValidator.isBomb(pile: s.discardPile, adding: cards)
        s.discardPile.append(contentsOf: cards)

        // Determine effect
        let rank = cards.first!.rank
        s.reversalActive = false // cleared unless 7 re-applies

        if isBomb || rank == .ten {
            // Burn the pile
            s.discardPile = []
            s.bonusTurn = true
            s.currentTurn = player
        } else if rank == .eight {
            // Skip — in 2-player, same player plays again
            s.bonusTurn = true
            s.currentTurn = player
        } else if rank == .seven {
            // Reversal
            // Count 7s played to determine net effect
            let sevenCount = cards.filter { $0.rank == .seven }.count
            s.reversalActive = sevenCount % 2 == 1
            s.bonusTurn = false
            s.currentTurn = player == .human ? .ai : .human
        } else {
            s.bonusTurn = false
            s.currentTurn = player == .human ? .ai : .human
        }

        // Auto-draw to refill hand to 3
        s = drawCards(for: player, state: s)

        return s
    }

    /// Player plays a blind face-down card. Returns state after flip attempt.
    static func applyBlindDraw(by player: PlayerID, state: GameState) -> GameState {
        var s = state
        var played = player == .human ? s.human : s.ai
        guard !played.faceDown.isEmpty else { return s }

        let flippedCard = played.faceDown.removeFirst()
        if player == .human { s.human = played } else { s.ai = played }

        let canPlay = RuleValidator.canPlay([flippedCard], on: s.discardPile, reversalActive: s.reversalActive)
        if canPlay {
            return applyMove([flippedCard], by: player, state: s)
        } else {
            // Can't play: pick up pile + keep flipped card
            var updated = player == .human ? s.human : s.ai
            updated.hand.append(contentsOf: s.discardPile)
            updated.hand.append(flippedCard)
            s.discardPile = []
            s.reversalActive = false
            if player == .human { s.human = updated } else { s.ai = updated }
            s.currentTurn = player == .human ? .ai : .human
            s.bonusTurn = false
            return s
        }
    }

    /// Player picks up the whole pile (can't play situation).
    static func pickUpPile(for player: PlayerID, state: GameState) -> GameState {
        var s = state
        var updated = player == .human ? s.human : s.ai
        updated.hand.append(contentsOf: s.discardPile)
        s.discardPile = []
        s.reversalActive = false
        if player == .human { s.human = updated } else { s.ai = updated }
        s.currentTurn = player == .human ? .ai : .human
        s.bonusTurn = false
        return s
    }

    // MARK: - Drawing

    /// Auto-draw from deck to refill player hand to 3.
    static func drawCards(for player: PlayerID, state: GameState) -> GameState {
        var s = state
        var updated = player == .human ? s.human : s.ai
        guard updated.cardPhase == .hand else { return s }
        while updated.hand.count < 3 && !s.deck.isEmpty {
            updated.hand.append(s.deck.removeFirst())
        }
        if player == .human { s.human = updated } else { s.ai = updated }
        return s
    }

    // MARK: - Win Detection

    static func checkWinCondition(state: GameState) -> AppPhase {
        let humanDone = !state.human.hasCards
        let aiDone = !state.ai.hasCards
        if humanDone {
            return .gameOver(winner: .human, shitHead: .ai)
        }
        if aiDone {
            return .gameOver(winner: .ai, shitHead: .human)
        }
        return .playing
    }
}
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
xcodebuild test -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(passed|failed|error:)"
```

- [ ] **Step 5: Commit**

```bash
git add ShitHead/Engine/GameEngine.swift ShitHeadTests/GameEngineTests.swift
git commit -m "feat: GameEngine with setup, moves, special cards, win detection"
```

---

## Task 6: AI Players

**Files:**
- Create: `ShitHead/AI/PlayerProtocol.swift`
- Create: `ShitHead/AI/EasyAIPlayer.swift`
- Create: `ShitHead/AI/HardAIPlayer.swift`
- Create: `ShitHeadTests/AIPlayerTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
// ShitHeadTests/AIPlayerTests.swift
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

    func test_easyAI_returns_legal_move_or_nil() {
        let ai = EasyAIPlayer()
        let state = makeState(
            aiHand: [Card(suit: .hearts, rank: .six)],
            pile: [Card(suit: .hearts, rank: .five)]
        )
        let move = ai.chooseMove(state: state)
        XCTAssertNotNil(move)
    }

    func test_easyAI_returns_nil_when_no_legal_move() {
        let ai = EasyAIPlayer()
        let state = makeState(
            aiHand: [Card(suit: .hearts, rank: .five)],
            pile: [Card(suit: .hearts, rank: .ace)]
        )
        let move = ai.chooseMove(state: state)
        XCTAssertNil(move)
    }

    func test_hardAI_saves_ten_when_not_stuck() {
        let ai = HardAIPlayer()
        // AI has a 10 and a King. Pile is a 9. Hard AI should play King, save 10.
        let state = makeState(
            aiHand: [Card(suit: .hearts, rank: .ten), Card(suit: .spades, rank: .king)],
            pile: [Card(suit: .hearts, rank: .nine)]
        )
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
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
xcodebuild test -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(passed|failed|error:)"
```

- [ ] **Step 3: Implement PlayerProtocol.swift**

```swift
// ShitHead/AI/PlayerProtocol.swift
import Foundation

protocol PlayerProtocol {
    /// Returns the cards to play this turn, or nil if the player must pick up the pile.
    func chooseMove(state: GameState) -> [Card]?
}
```

- [ ] **Step 4: Implement EasyAIPlayer.swift**

```swift
// ShitHead/AI/EasyAIPlayer.swift
import Foundation

struct EasyAIPlayer: PlayerProtocol {
    func chooseMove(state: GameState) -> [Card]? {
        let moves = GameEngine.legalMoves(for: .ai, in: state)
        return moves.randomElement()
    }
}
```

- [ ] **Step 5: Implement HardAIPlayer.swift**

```swift
// ShitHead/AI/HardAIPlayer.swift
import Foundation

struct HardAIPlayer: PlayerProtocol {
    func chooseMove(state: GameState) -> [Card]? {
        let moves = GameEngine.legalMoves(for: .ai, in: state)
        guard !moves.isEmpty else { return nil }

        let humanCardCount = state.human.hand.count + state.human.faceUp.count + state.human.faceDown.count
        let aiHand = state.ai.hand

        // Prefer larger groups (get rid of duplicates faster)
        let sortedBySize = moves.sorted { $0.count > $1.count }

        // Categorize available moves
        let specialRanks: Set<Rank> = [.two, .ten]
        let nonSpecialMoves = sortedBySize.filter { !specialRanks.contains($0.first!.rank) }
        let specialMoves = sortedBySize.filter { specialRanks.contains($0.first!.rank) }

        // Use 8 strategically: skip when human has few cards
        if humanCardCount <= 3, let skipMove = moves.first(where: { $0.first?.rank == .eight }) {
            return skipMove
        }

        // Use 7 if human only has high cards (all >= 8)
        let humanHand = state.human.hand
        let humanAllHigh = !humanHand.isEmpty && humanHand.allSatisfy { $0.rank.rawValue >= 8 }
        if humanAllHigh, let sevenMove = moves.first(where: { $0.first?.rank == .seven }) {
            return sevenMove
        }

        // Dump high cards first (K, A) if not stuck
        let highCardMove = nonSpecialMoves.first { $0.first!.rank >= .king }
        if let high = highCardMove { return high }

        // Play any non-special move
        if let normal = nonSpecialMoves.first { return normal }

        // Only specials remain — use them
        return specialMoves.first
    }
}
```

- [ ] **Step 6: Run tests — expect PASS**

```bash
xcodebuild test -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(passed|failed|error:)"
```

- [ ] **Step 7: Commit**

```bash
git add ShitHead/AI/ ShitHeadTests/AIPlayerTests.swift
git commit -m "feat: EasyAIPlayer and HardAIPlayer conforming to PlayerProtocol"
```

---

## Task 7: Persistence

**Files:**
- Create: `ShitHead/Persistence/GamePersistence.swift`

No separate tests — tested implicitly through ViewModel integration.

- [ ] **Step 1: Implement GamePersistence.swift**

```swift
// ShitHead/Persistence/GamePersistence.swift
import Foundation

enum GamePersistence {
    private static let key = "shithead.savedGame"

    static func save(_ state: GameState) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> GameState? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let state = try? JSONDecoder().decode(GameState.self, from: data)
        else { return nil }
        return state
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(error:|BUILD)"
```

- [ ] **Step 3: Commit**

```bash
git add ShitHead/Persistence/GamePersistence.swift
git commit -m "feat: GamePersistence saves/restores GameState via UserDefaults"
```

---

## Task 8: GameViewModel

**Files:**
- Create: `ShitHead/ViewModels/GameViewModel.swift`

- [ ] **Step 1: Implement GameViewModel.swift**

```swift
// ShitHead/ViewModels/GameViewModel.swift
import SwiftUI
import Combine

@MainActor
final class GameViewModel: ObservableObject {
    // MARK: - Published state
    @Published var gameState: GameState?
    @Published var appPhase: AppPhase = .home
    @Published var selectedCards: [Card] = []
    @Published var setupCards: [Card] = []         // 6 cards shown during setup
    @Published var chosenFaceUp: [Card] = []       // 3 chosen during setup
    @Published var showPhaseBanner: Bool = false
    @Published var phaseBannerText: String = ""
    @Published var showBurnFlash: Bool = false
    @Published var shakeCardID: String? = nil
    @Published var difficulty: Difficulty = .easy

    private var aiPlayer: any PlayerProtocol = EasyAIPlayer()
    private var aiTimer: Task<Void, Never>?
    private var previousCardPhase: CardPhase?

    // MARK: - Game Start

    func startNewGame() {
        GamePersistence.clear()
        var state = GameEngine.setupGame(difficulty: difficulty)
        setupCards = state.human.hand
        chosenFaceUp = []
        gameState = state
        appPhase = .setup
        aiPlayer = difficulty == .easy ? EasyAIPlayer() : HardAIPlayer()
    }

    func confirmSetup() {
        guard chosenFaceUp.count == 3, var state = gameState else { return }
        state = GameEngine.confirmPlayerSetup(state: state, faceUpCards: chosenFaceUp)
        gameState = state
        previousCardPhase = .hand
        appPhase = .playing
        GamePersistence.save(state)
    }

    func resumeIfSaved() {
        guard let saved = GamePersistence.load() else { return }
        gameState = saved
        appPhase = .playing
        aiPlayer = saved.currentTurn == .ai ? (difficulty == .easy ? EasyAIPlayer() : HardAIPlayer()) : aiPlayer
        if saved.currentTurn == .ai { scheduleAIMove() }
    }

    // MARK: - Player Actions

    func toggleCard(_ card: Card) {
        guard appPhase == .playing,
              gameState?.currentTurn == .human else { return }
        if selectedCards.contains(card) {
            selectedCards.removeAll { $0 == card }
        } else {
            selectedCards.append(card)
        }
    }

    func playSelectedCards() {
        guard var state = gameState, !selectedCards.isEmpty else { return }
        guard RuleValidator.canPlay(selectedCards, on: state.discardPile, reversalActive: state.reversalActive) else {
            // Shake all selected cards
            for card in selectedCards { shakeCardID = card.id }
            selectedCards = []
            return
        }
        state = GameEngine.applyMove(selectedCards, by: .human, state: state)
        selectedCards = []
        finishTurn(state: state)
    }

    func playBlindCard() {
        guard var state = gameState,
              state.human.cardPhase == .faceDown,
              state.currentTurn == .human else { return }
        state = GameEngine.applyBlindDraw(by: .human, state: state)
        finishTurn(state: state)
    }

    func pickUpPile() {
        guard var state = gameState else { return }
        state = GameEngine.pickUpPile(for: .human, state: state)
        finishTurn(state: state)
    }

    // MARK: - Turn Management

    private func finishTurn(state: GameState) {
        // Check burn
        if state.discardPile.isEmpty && gameState?.discardPile.isEmpty == false {
            triggerBurnFlash()
        }

        // Check phase transition
        checkPhaseTransition(state: state)

        // Check win
        let outcome = GameEngine.checkWinCondition(state: state)
        gameState = state
        GamePersistence.save(state)

        if case .gameOver = outcome {
            appPhase = outcome
            return
        }

        appPhase = .playing
        if state.currentTurn == .ai {
            scheduleAIMove()
        }
    }

    private func scheduleAIMove() {
        aiTimer?.cancel()
        aiTimer = Task {
            let delay = Double.random(in: 0.8...1.2)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await executeAITurn()
        }
    }

    @MainActor
    private func executeAITurn() {
        guard var state = gameState, state.currentTurn == .ai else { return }
        if state.ai.cardPhase == .faceDown {
            state = GameEngine.applyBlindDraw(by: .ai, state: state)
        } else if let move = aiPlayer.chooseMove(state: state) {
            state = GameEngine.applyMove(move, by: .ai, state: state)
        } else {
            state = GameEngine.pickUpPile(for: .ai, state: state)
        }
        finishTurn(state: state)
    }

    // MARK: - UI Effects

    private func triggerBurnFlash() {
        showBurnFlash = true
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            showBurnFlash = false
        }
    }

    private func checkPhaseTransition(state: GameState) {
        let current = state.human.cardPhase
        guard let prev = previousCardPhase, prev != current else {
            previousCardPhase = state.human.cardPhase
            return
        }
        previousCardPhase = current
        switch current {
        case .faceUp: showBanner("Playing face-up cards")
        case .faceDown: showBanner("Playing blind cards")
        default: break
        }
    }

    private func showBanner(_ text: String) {
        phaseBannerText = text
        showPhaseBanner = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showPhaseBanner = false
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(error:|BUILD)"
```

- [ ] **Step 3: Commit**

```bash
git add ShitHead/ViewModels/GameViewModel.swift
git commit -m "feat: GameViewModel bridging engine to views with AI timer and animations"
```

---

## Task 9: CardView

**Files:**
- Create: `ShitHead/Views/CardView.swift`

- [ ] **Step 1: Implement CardView.swift**

```swift
// ShitHead/Views/CardView.swift
import SwiftUI

struct CardView: View {
    let card: Card
    var isFaceDown: Bool = false
    var isSelected: Bool = false
    var isPlayable: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isFaceDown ? Color.blue.gradient : Color.white.gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.yellow : Color.gray.opacity(0.3), lineWidth: isSelected ? 2.5 : 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)

            if isFaceDown {
                Image(systemName: "suit.diamond.fill")
                    .foregroundStyle(.white.opacity(0.3))
                    .font(.title)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text(card.rank.display)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(suitColor)
                    Text(card.suit.rawValue)
                        .font(.system(size: 12))
                        .foregroundStyle(suitColor)
                    Spacer()
                }
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(width: 52, height: 76)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .offset(y: isSelected ? -8 : 0)
        .opacity(isPlayable ? 1.0 : 0.5)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }

    private var suitColor: Color {
        switch card.suit {
        case .hearts, .diamonds: return .red
        case .clubs, .spades: return .black
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(error:|BUILD)"
```

- [ ] **Step 3: Commit**

```bash
git add ShitHead/Views/CardView.swift
git commit -m "feat: CardView with face-up, face-down, selected states"
```

---

## Task 10: HomeView

**Files:**
- Create: `ShitHead/Views/HomeView.swift`

- [ ] **Step 1: Implement HomeView.swift**

```swift
// ShitHead/Views/HomeView.swift
import SwiftUI

struct HomeView: View {
    @StateObject private var vm = GameViewModel()

    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.45, blue: 0.25)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Text("💩")
                        .font(.system(size: 64))
                    Text("Shit Head")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4)
                }

                Spacer()

                VStack(spacing: 16) {
                    Text("Difficulty")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))

                    Picker("Difficulty", selection: $vm.difficulty) {
                        Text("Easy").tag(Difficulty.easy)
                        Text("Hard").tag(Difficulty.hard)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 60)
                    .tint(.white)
                }

                Button(action: vm.startNewGame) {
                    Text("New Game")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.orange)
                                .shadow(color: .black.opacity(0.3), radius: 6)
                        )
                }

                Spacer()
            }
        }
        .fullScreenCover(isPresented: .constant(vm.appPhase != .home)) {
            GameFlowView(vm: vm)
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(error:|BUILD)"
```

- [ ] **Step 3: Commit**

```bash
git add ShitHead/Views/HomeView.swift
git commit -m "feat: HomeView with difficulty picker and New Game button"
```

---

## Task 11: SetupView + GameFlowView

**Files:**
- Create: `ShitHead/Views/SetupView.swift`

- [ ] **Step 1: Implement SetupView.swift** (includes GameFlowView router)

```swift
// ShitHead/Views/SetupView.swift
import SwiftUI

/// Routes between Setup, Game, and GameOver based on appPhase
struct GameFlowView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        switch vm.appPhase {
        case .setup:
            SetupView(vm: vm)
        case .playing:
            GameView(vm: vm)
        case .gameOver(let winner, let shitHead):
            GameOverView(winner: winner, shitHead: shitHead, vm: vm)
        case .home:
            EmptyView()
        }
    }
}

struct SetupView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.45, blue: 0.25).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Choose 3 face-up cards")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 40)

                Text("These will be visible on the table.\nChoose your best cards.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .font(.subheadline)

                Text("\(vm.chosenFaceUp.count) / 3 selected")
                    .font(.headline)
                    .foregroundStyle(vm.chosenFaceUp.count == 3 ? .yellow : .white.opacity(0.7))

                // 6 cards in a 2-row grid
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(60)), count: 3), spacing: 16) {
                    ForEach(vm.setupCards) { card in
                        CardView(
                            card: card,
                            isSelected: vm.chosenFaceUp.contains(card)
                        )
                        .onTapGesture { toggleSetupCard(card) }
                    }
                }
                .padding(.horizontal)

                Spacer()

                Button(action: vm.confirmSetup) {
                    Text("Confirm")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(vm.chosenFaceUp.count == 3 ? Color.orange : Color.gray)
                        )
                }
                .disabled(vm.chosenFaceUp.count != 3)
                .padding(.bottom, 40)
            }
        }
    }

    private func toggleSetupCard(_ card: Card) {
        if vm.chosenFaceUp.contains(card) {
            vm.chosenFaceUp.removeAll { $0 == card }
        } else if vm.chosenFaceUp.count < 3 {
            vm.chosenFaceUp.append(card)
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(error:|BUILD)"
```

- [ ] **Step 3: Commit**

```bash
git add ShitHead/Views/SetupView.swift
git commit -m "feat: SetupView for choosing 3 face-up cards + GameFlowView router"
```

---

## Task 12: GameView

**Files:**
- Create: `ShitHead/Views/GameView.swift`

- [ ] **Step 1: Implement GameView.swift**

```swift
// ShitHead/Views/GameView.swift
import SwiftUI

struct GameView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            // Green felt background
            Color(red: 0.13, green: 0.45, blue: 0.25).ignoresSafeArea()
            feltTexture

            VStack(spacing: 8) {
                // AI zone
                aiZone
                    .padding(.top, 8)

                Spacer()

                // Middle zone
                middleZone

                Spacer()

                // Player zone
                playerZone
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 12)

            // Overlays
            if vm.showBurnFlash {
                burnFlashOverlay
            }
            if vm.showPhaseBanner {
                phaseBanner
            }
        }
    }

    // MARK: - AI Zone
    private var aiZone: some View {
        VStack(spacing: 6) {
            Text("AI")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.7))

            // Face-down + face-up table cards
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    ZStack {
                        if let _ = vm.gameState?.ai.faceDown.indices.contains(i), true {
                            CardView(card: Card(suit: .hearts, rank: .two), isFaceDown: true)
                        }
                        if let faceUp = vm.gameState?.ai.faceUp, i < faceUp.count {
                            CardView(card: faceUp[i])
                                .offset(y: -4)
                        }
                    }
                }
            }

            // AI hand (backs only)
            HStack(spacing: -18) {
                ForEach(0..<(vm.gameState?.ai.hand.count ?? 0), id: \.self) { _ in
                    CardView(card: Card(suit: .hearts, rank: .two), isFaceDown: true)
                }
            }
        }
    }

    // MARK: - Middle Zone
    private var middleZone: some View {
        HStack(spacing: 24) {
            // Draw pile
            VStack(spacing: 4) {
                ZStack {
                    ForEach(0..<min(3, vm.gameState?.deck.count ?? 0), id: \.self) { i in
                        CardView(card: Card(suit: .hearts, rank: .two), isFaceDown: true)
                            .offset(x: CGFloat(i) * 0.5, y: CGFloat(-i) * 0.5)
                    }
                    if vm.gameState?.deck.isEmpty == true {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                            .frame(width: 52, height: 76)
                    }
                }
                Text("\(vm.gameState?.deck.count ?? 0)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Discard pile
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .frame(width: 52, height: 76)

                if let top = vm.gameState?.topOfPile {
                    CardView(card: top)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: vm.gameState?.topOfPile?.id)
        }
    }

    // MARK: - Player Zone
    private var playerZone: some View {
        VStack(spacing: 6) {
            // Player hand
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -12) {
                    ForEach(vm.gameState?.human.hand ?? []) { card in
                        let isSelected = vm.selectedCards.contains(card)
                        CardView(card: card, isSelected: isSelected)
                            .onTapGesture { handlePlayerTap(card: card) }
                    }
                }
                .padding(.horizontal, 8)
            }

            // Face-down + face-up table cards
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    ZStack {
                        CardView(card: Card(suit: .hearts, rank: .two), isFaceDown: true)
                        if let faceUp = vm.gameState?.human.faceUp, i < faceUp.count {
                            CardView(card: faceUp[i])
                                .offset(y: -4)
                        }
                    }
                    .onTapGesture {
                        if vm.gameState?.human.cardPhase == .faceDown {
                            vm.playBlindCard()
                        }
                    }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                if !vm.selectedCards.isEmpty {
                    Button("Play") { vm.playSelectedCards() }
                        .buttonStyle(ActionButtonStyle(color: .orange))
                }

                if vm.selectedCards.isEmpty,
                   let state = vm.gameState,
                   state.currentTurn == .human,
                   GameEngine.legalMoves(for: .human, in: state).isEmpty {
                    Button("Pick Up") { vm.pickUpPile() }
                        .buttonStyle(ActionButtonStyle(color: .red.opacity(0.8)))
                }
            }
            .frame(height: 44)
        }
    }

    private func handlePlayerTap(card: Card) {
        guard vm.gameState?.currentTurn == .human else { return }
        guard vm.gameState?.human.cardPhase == .hand else { return }
        vm.toggleCard(card)
    }

    // MARK: - Overlays
    private var burnFlashOverlay: some View {
        Color.yellow.opacity(0.3)
            .ignoresSafeArea()
            .transition(.opacity)
            .animation(.easeOut(duration: 0.6), value: vm.showBurnFlash)
    }

    private var phaseBanner: some View {
        VStack {
            Spacer()
            Text(vm.phaseBannerText)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.black.opacity(0.7)))
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 120)
        }
        .animation(.spring(), value: vm.showPhaseBanner)
    }

    private var feltTexture: some View {
        // Subtle felt texture overlay using repeating dots
        Canvas { ctx, size in
            let spacing: CGFloat = 6
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                             with: .color(.black.opacity(0.08)))
                    x += spacing
                }
                y += spacing
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct ActionButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10).fill(color))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(error:|BUILD)"
```

- [ ] **Step 3: Commit**

```bash
git add ShitHead/Views/GameView.swift
git commit -m "feat: GameView with AI zone, middle pile, player hand, action buttons"
```

---

## Task 13: GameOverView

**Files:**
- Create: `ShitHead/Views/GameOverView.swift`

- [ ] **Step 1: Implement GameOverView.swift**

```swift
// ShitHead/Views/GameOverView.swift
import SwiftUI

struct GameOverView: View {
    let winner: PlayerID
    let shitHead: PlayerID
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.45, blue: 0.25).ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Text(shitHead == .human ? "💩" : "🎉")
                    .font(.system(size: 80))

                Text(shitHead == .human ? "You're the Shit Head!" : "You Win!")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(shitHead == .human ? "The AI destroyed you." : "The AI is the Shit Head.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Button("Play Again") {
                    vm.startNewGame()
                }
                .font(.title2.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.orange))
                .padding(.bottom, 48)
            }
            .padding(.horizontal)
        }
    }
}
```

- [ ] **Step 2: Build entire app — expect BUILD SUCCEEDED**

```bash
xcodebuild build -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(error:|BUILD)"
```

- [ ] **Step 3: Run all tests — expect all PASS**

```bash
xcodebuild test -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(passed|failed|error:)"
```

- [ ] **Step 4: Commit**

```bash
git add ShitHead/Views/GameOverView.swift
git commit -m "feat: GameOverView with winner/loser display and Play Again"
```

---

## Task 14: Wire up ShitHeadApp + Resume Support

**Files:**
- Modify: `ShitHead/ShitHeadApp.swift`

- [ ] **Step 1: Update ShitHeadApp.swift**

```swift
// ShitHead/ShitHeadApp.swift
import SwiftUI

@main
struct ShitHeadApp: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var vm = GameViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(vm)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background, let state = vm.gameState {
                GamePersistence.save(state)
            }
        }
    }
}
```

- [ ] **Step 2: Replace HomeView.swift completely** (now uses environment object and resume support)

```swift
// ShitHead/Views/HomeView.swift
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.45, blue: 0.25)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Text("💩")
                        .font(.system(size: 64))
                    Text("Shit Head")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4)
                }

                Spacer()

                VStack(spacing: 16) {
                    Text("Difficulty")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))

                    Picker("Difficulty", selection: $vm.difficulty) {
                        Text("Easy").tag(Difficulty.easy)
                        Text("Hard").tag(Difficulty.hard)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 60)
                }

                Button(action: vm.startNewGame) {
                    Text("New Game")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.orange)
                                .shadow(color: .black.opacity(0.3), radius: 6)
                        )
                }

                Spacer()
            }
        }
        .onAppear { vm.resumeIfSaved() }
        .fullScreenCover(isPresented: .constant(vm.appPhase != .home)) {
            GameFlowView(vm: vm)
        }
    }
}
```

- [ ] **Step 2: Final full build + test run**

```bash
xcodebuild build -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(error:|BUILD)"
xcodebuild test -scheme ShitHead -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(passed|failed|error:)"
```

Expected: `BUILD SUCCEEDED`, all tests PASS.

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: complete Shit Head v1 — player vs AI with all rules, setup, persistence"
```

---

## Completion Checklist

- [ ] All 4 test files pass (CardTests, RuleValidatorTests, GameEngineTests, AIPlayerTests)
- [ ] App runs in iOS Simulator: home → setup → game → game over → play again
- [ ] Special cards work: 2 (reset), 3 (transparent), 7 (reversal), 8 (skip/extra turn), 10 (burn), bomb
- [ ] AI Easy plays randomly; AI Hard saves 10s and dumps high cards
- [ ] Phase transitions show banner (hand → face-up → blind)
- [ ] Burn flash triggers on 10 and bomb
- [ ] Game state saves on backgrounding, resumes on relaunch
