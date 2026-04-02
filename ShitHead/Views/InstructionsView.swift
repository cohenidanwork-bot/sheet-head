// ShitHead/Views/InstructionsView.swift
import SwiftUI

struct InstructionsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(red: 0.13, green: 0.45, blue: 0.25)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Header
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            Text("💩")
                                .font(.system(size: 44))
                            Text("How to Play")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.4), radius: 4)
                        }
                        Spacer()
                    }
                    .padding(.top, 60)

                    // Objective
                    InstructionSection(title: "Objective") {
                        InstructionText("Be the first player to get rid of all your cards. The last player with cards is the Shit Head 💩")
                    }

                    // Setup
                    InstructionSection(title: "Setup") {
                        InstructionText("Each player receives:")
                        BulletPoint("3 face-down cards (placed blind on the table)")
                        BulletPoint("3 face-up cards (placed on top of the face-down cards)")
                        BulletPoint("6 cards in hand")
                        InstructionText("Before the game starts, choose 3 cards from your hand to place face-up on the table.")
                    }

                    // How to Play
                    InstructionSection(title: "Playing Cards") {
                        InstructionText("On your turn, play one or more cards of the same rank onto the discard pile. The card you play must be equal to or higher than the top card of the pile.")
                        InstructionText("If you can't play, pick up the entire discard pile and add it to your hand.")
                        InstructionText("After playing from your hand, draw back up to 3 cards while the deck has cards remaining.")
                    }

                    // Card Phases
                    InstructionSection(title: "Card Phases") {
                        BulletPoint("Hand cards → play from your hand first")
                        BulletPoint("Face-up cards → once your hand is empty")
                        BulletPoint("Face-down cards → flip blind once face-up cards are gone")
                        InstructionText("If a blind card can't be played, you pick up the pile.")
                    }

                    // Special Cards
                    InstructionSection(title: "Special Cards") {
                        VStack(spacing: 16) {
                            SpecialCardRow(
                                card: Card(suit: .hearts, rank: .two),
                                title: "2 — Wildcard",
                                description: "Can always be played on anything. Resets the pile value; next player can play any card."
                            )
                            SpecialCardRow(
                                card: Card(suit: .clubs, rank: .three),
                                title: "3 — Transparent",
                                description: "Can always be played. The pile value is unchanged — the 3 is skipped when determining what can be played next."
                            )
                            SpecialCardRow(
                                card: Card(suit: .diamonds, rank: .seven),
                                title: "7 — Reversal",
                                description: "Next player must play a card lower than 7. Aces count as 1 (low) during reversal. Playing an even number of 7s cancels the reversal."
                            )
                            SpecialCardRow(
                                card: Card(suit: .spades, rank: .eight),
                                title: "8 — Skip",
                                description: "The next player's turn is skipped. You get to play again immediately."
                            )
                            SpecialCardRow(
                                card: Card(suit: .hearts, rank: .ten),
                                title: "10 — Burn",
                                description: "Clears the entire discard pile (burn!). You get a bonus turn immediately after."
                            )
                        }
                    }

                    // Bomb
                    InstructionSection(title: "Bomb (4 of a Kind)") {
                        HStack(spacing: -16) {
                            ForEach([Suit.hearts, .diamonds, .clubs, .spades], id: \.self) { suit in
                                CardView(card: Card(suit: suit, rank: .king))
                            }
                        }
                        .padding(.vertical, 4)
                        InstructionText("Playing four cards of the same rank at once is a Bomb 💣 — it clears the discard pile and gives you a bonus turn, just like a 10.")
                    }

                    // Tips
                    InstructionSection(title: "Tips") {
                        BulletPoint("Place your best special cards (10s, 8s) face-up on the table.")
                        BulletPoint("Save low cards for when you need to play after a reversal.")
                        BulletPoint("Watch how many cards your opponent has — use skip (8) when they're close to winning.")
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }

            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.3), radius: 4)
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
    }
}

// MARK: - Sub-components

private struct InstructionSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 2)

            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(height: 1)

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.2))
        )
    }
}

private struct InstructionText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundStyle(.white.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct BulletPoint: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(.white.opacity(0.7))
                .font(.system(size: 15))
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SpecialCardRow: View {
    let card: Card
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            CardView(card: card)
                .fixedSize()

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
