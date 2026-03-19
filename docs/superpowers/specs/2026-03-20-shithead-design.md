# Shit Head — iOS Game Design Spec
**Date:** 2026-03-20

---

## Overview

A single-player iOS card game called "Shit Head" built with SwiftUI. The player competes against one AI opponent. The last player left holding cards loses and is crowned the Shit Head.

---

## Screens & Navigation

### 1. Home Screen
- App title: "Shit Head"
- "New Game" button
- Difficulty selector: Easy / Hard

### 2. Setup Screen (within Game flow)
- Player sees 6 cards dealt to them
- Player taps 3 cards to designate as face-up table cards (selected cards are highlighted/lifted)
- A "Confirm" button appears once exactly 3 are selected
- Remaining 3 automatically become the starting hand
- AI picks its best 3 face-up cards automatically (no UI shown for AI setup)

### 3. Game Screen
- The main gameplay table (see layout section below)

### 4. Game Over Screen
- Shows winner and who is the Shit Head
- "Play Again" button returns to Home Screen

---

## Game Screen Layout (top to bottom)

| Zone | Content |
|------|---------|
| Top | AI's 3 face-down cards, AI's 3 face-up cards on top of them, AI hand shown as card backs |
| Middle | Draw pile (left), active discard pile (center), burn flash indicator when pile clears |
| Bottom | Player's 3 face-down cards, player's 3 face-up cards, player's hand (tappable) |

- Background: green felt texture
- Cards: standard playing card style
- Portrait orientation only (v1)

### UI States & Feedback
- **Selected card**: tapped card lifts and highlights before confirming play
- **Illegal move**: tapped card shakes briefly, no action taken
- **Pile pick-up animation**: pile slides into player's hand area
- **Pile burn**: brief flash/sparkle on discard area, pile disappears
- **Phase transition**: subtle banner ("Playing face-up cards" / "Playing blind cards") when player moves to a new phase
- **AI thinking**: 0.8–1.2 second delay with a subtle animated indicator before AI plays
- **Empty discard pile**: empty placeholder shown in center after a burn

---

## Game Rules

### Setup Phase
1. 3 face-down table cards are dealt to each player automatically (never revealed until blind phase).
2. Each player receives 6 additional cards.
3. **Player** chooses 3 of those 6 to place face-up on top of their face-down cards (Setup Screen).
4. The remaining 3 become the player's starting hand.
5. **AI** automatically selects its 3 highest-value cards as face-up (or best strategic selection in Hard mode).
6. **Human player always goes first.**

### Normal Play
- Active player must play a card equal to or higher than the top card of the discard pile.
- Multiple cards of the same value can be played together in a single turn.
- After playing, the game **automatically draws** from the deck to refill the hand to 3 cards. Auto-draw stops when the deck is empty.
- If the player cannot play (no legal card and no applicable special card), they pick up the entire discard pile into their hand.

### Card Progression (phases)
1. **Hand cards** — played first while deck has cards (hand refills to 3 automatically)
2. **Face-up table cards** — used when hand is empty (no more drawing)
3. **Face-down table cards** — blind draw, no peeking (last phase)

Phase transitions are detected automatically by the game engine. A banner notifies the player when their phase changes.

### Special Cards

| Card | Name | Rule |
|------|------|------|
| 2 | The Reset | Can be played on **any** card regardless of value. Resets the effective pile value to 0 — next player can play any card. |
| 3 | The Transparent | Can be played on **any** card. The pile's effective value remains the card **beneath** the 3 (resolved recursively if multiple 3s are stacked). If played on an empty pile (after a burn), treated like a Reset — next player can play anything. |
| 7 | The Reverser | Can only be played on a card with value **lower than 7** (i.e., A, 2, 3, 4, 5, 6). After a 7, the next player must play a card with value **lower than 7**. Note: 2 and 3 always override (can be played regardless). Multiple 7s played together toggle the reversal: each additional 7 flips the state once (odd number = reversal active, even number = reversal cancelled out). |
| 8 | The Skip | Can be played in turn (on equal or higher card). Next player is skipped. In a **2-player game**, skip = current player takes an extra turn. Two 8s played together = skip 2 players (= current player plays twice in 2-player game). |
| 10 | The Joker | Can be played on **any** card. Burns the pile (pile is removed from the game). Same player takes an extra turn with an empty pile. Draw to refill hand before the bonus turn begins. |
| 4 of a kind | The Bomb | Four cards of the same rank on the pile (built across turns or played at once). Burns the pile. Same player takes an extra turn. Draw to refill hand before the bonus turn. |

### 4-of-a-Kind Bomb Clarification
- Can be accumulated across turns: if three 6s are on the pile and a player adds a 4th 6, the bomb triggers.
- The four cards do not need to be played in a single action.
- In a 2-player game, only the current player can add to the pile — no "speed" mechanic in v1.
- **Bomb vs. 7-constraint**: the bomb check (4 of a kind) is evaluated **before** the 7-constraint legality check. If a player completes a bomb, it always triggers regardless of an active 7-reversal state. The reversal state is cleared by the burn.

### 3 (Transparent) Chaining
- If multiple 3s are stacked, the effective value is the first non-3 card beneath them, resolved recursively.
- Example: pile is [King, 3, 3] → effective value is King. Next player must play King or higher (or a special card).

### Pile Burning
- Triggered by: playing a 10, or completing 4 of a kind on the pile.
- The discard pile is removed from the game entirely (cards gone).
- The player who triggered the burn takes an extra turn; the pile is effectively empty (any card is legal).
- Draw to refill hand to 3 before the bonus turn if deck is not empty. If the deck is empty, proceed to the bonus turn with the current hand size (no draw occurs).

### Can't Play
- If the active player has no legal card and no applicable special card, they pick up the entire discard pile into their hand.
- Play passes to the opponent.
- The opponent then starts with an empty pile (can play anything).

### Unplayable Face-Down Card
- When playing blind (face-down phase), the card is flipped face-up.
- If the revealed card **cannot legally be played** on the current pile, the player picks up the entire discard pile into their hand AND keeps the flipped card.
- If the revealed card **can be played**, it is placed normally.

### Winning & Losing
- A player who empties all cards (hand + face-up + face-down) **wins** immediately and exits the game.
- With only 2 players, the remaining player is the **Shit Head** (loser).
- Game Over Screen is shown.

---

## AI Behavior

### Easy Mode
- Plays a random legal card from available options.
- Randomly selects face-up cards during setup.

### Hard Mode
- **Setup**: places 3 highest-value cards face-up (10 > A > K > Q …).
- **Saves** 10s and 2s for difficult situations (plays them only when stuck or to escape a bad pile).
- **Dumps** high cards (K, A) early to thin out dangerous cards.
- **Uses 8** strategically when opponent has few cards left (to skip their winning turn).
- **Uses 7** when opponent has only high cards in hand.
- Prefers playing multiple same-value cards to get rid of duplicates faster.

---

## Architecture

### 3-Layer Structure

```
┌─────────────────────────────────┐
│         SwiftUI Views           │  ← Displays table, animates cards, handles taps
│   HomeView, SetupView,          │
│   GameView, GameOverView        │
├─────────────────────────────────┤
│         GameViewModel           │  ← Owns UI state (ObservableObject)
│   (selected cards, phase        │
│    banners, AI delay timer)     │
├─────────────────────────────────┤
│    Game Engine  |  AI Player    │  ← Pure logic, no UI dependencies
│  (game state,   | (move picker) │
│   rule engine)  |               │
└─────────────────────────────────┘
```

### Game Engine (pure logic, owns game state)
Responsible for:
- `GameState`: deck, discard pile, each player's hand / face-up / face-down cards, current phase, whose turn it is
- Card validation: `canPlay(card, onPile:) → Bool`
- Applying moves: `applyMove(cards, by: player) → GameState`
- Special card effects (2, 3, 7, 8, 10, bomb)
- Turn management and phase transitions (hand → face-up → face-down)
- Win/lose detection

### GameViewModel (owns UI state, bridges engine ↔ views)
Responsible for:
- Currently selected cards (before confirming play)
- AI thinking delay (timer before AI move executes)
- Phase transition banner visibility
- Animation triggers (burn flash, pile slide, card shake)
- Calling Game Engine methods in response to user taps
- Persisting game state to disk (app backgrounding)

### AI Player (pure logic, no UI)
- Protocol: `PlayerProtocol { func chooseMove(state: GameState) -> [Card] }`
- `EasyAIPlayer` and `HardAIPlayer` both conform to this protocol
- Future `NetworkPlayer` will also conform — the GameViewModel calls only the protocol, never a concrete type directly

### Card Model
```swift
struct Card: Identifiable, Hashable {
    let suit: Suit       // hearts, diamonds, clubs, spades
    let rank: Rank       // 2–10, J, Q, K, A (with raw Int value for comparison)
    var id: String { "\(rank)-\(suit)" }
}
```

### State Persistence
- Game state is serialized (Codable) and saved to disk when the app backgrounds.
- On relaunch, the saved state is restored so the player can continue mid-game.
- Setup phase state is not persisted. If the app is backgrounded or killed during setup, on relaunch the player is returned to the **start of the Setup Screen** (not Home) so they can complete card selection without losing the dealt cards.

---

## Out of Scope (v1)
- Android / cross-platform
- Online multiplayer
- Leaderboards / stats / history
- Sound effects and haptics
- Game Center integration
- Landscape orientation
- Undo / misplay recovery
- Accessibility (VoiceOver, dynamic type) — deferred to v2
