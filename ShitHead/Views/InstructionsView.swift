// SheetHead/Views/InstructionsView.swift — Japanese Mountain Design
import SwiftUI

struct InstructionsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.shParchment.ignoresSafeArea()

            LinearGradient(
                colors: [Color.shParchmentLight.opacity(0.6), Color.shParchmentDeep.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    VStack(spacing: 6) {
                        Text("HOW TO PLAY")
                            .font(.shLogoSm)
                            .foregroundStyle(Color.shInk)
                            .tracking(6)

                        Text("Sheet Head")
                            .font(.custom("ShipporiMincho-Bold", size: 13))
                            .foregroundStyle(Color.shInkLight)
                            .tracking(4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 64)
                    .padding(.bottom, 8)

                    Divider()
                        .background(Color.shInk.opacity(0.15))

                    // Objective
                    InstructionSection(title: "OBJECTIVE") {
                        InstructionText("Be the first player to get rid of all your cards. The last player with cards is the Sheet Head.")
                    }

                    // Setup
                    InstructionSection(title: "SETUP") {
                        InstructionText("Each player receives:")
                        BulletPoint("3 face-down cards (placed blind on the table)")
                        BulletPoint("3 face-up cards (placed on top of the face-down cards)")
                        BulletPoint("6 cards in hand")
                        InstructionText("Before the game starts, choose 3 cards from your hand to place face-up on the table.")
                    }

                    // Playing
                    InstructionSection(title: "PLAYING CARDS") {
                        InstructionText("On your turn, play one or more cards of the same rank onto the discard pile. The card you play must be equal to or higher than the top card.")
                        InstructionText("If you can't play, pick up the entire discard pile.")
                        InstructionText("After playing from your hand, draw back up to 3 cards while the deck has cards remaining.")
                    }

                    // Card Phases
                    InstructionSection(title: "CARD PHASES") {
                        BulletPoint("Hand cards — play from your hand first")
                        BulletPoint("Face-up cards — once your hand is empty")
                        BulletPoint("Face-down cards — flip blind once face-up cards are gone")
                        InstructionText("If a blind card can't be played, you pick up the pile.")
                    }

                    // Special Cards
                    InstructionSection(title: "SPECIAL CARDS") {
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
                                description: "Next player must play a card lower than 7."
                            )
                            SpecialCardRow(
                                card: Card(suit: .spades, rank: .eight),
                                title: "8 — Skip",
                                description: "The next player's turn is skipped. You play again immediately."
                            )
                            SpecialCardRow(
                                card: Card(suit: .hearts, rank: .ten),
                                title: "10 — Burn",
                                description: "Clears the entire discard pile. You get a bonus turn immediately after."
                            )
                        }
                    }

                    // Bomb
                    InstructionSection(title: "BOMB — 4 OF A KIND") {
                        HStack(spacing: -10) {
                            ForEach([Suit.hearts, .diamonds, .clubs, .spades], id: \.self) { suit in
                                CardView(card: Card(suit: suit, rank: .king), size: .player)
                            }
                        }
                        .padding(.vertical, 4)
                        InstructionText("Playing four cards of the same rank clears the discard pile and gives you a bonus turn, just like a 10.")
                    }

                    // Tips
                    InstructionSection(title: "TIPS") {
                        BulletPoint("Place your best special cards (10s, 8s) face-up on the table.")
                        BulletPoint("Save low cards for when you need to play after a reversal.")
                        BulletPoint("Use skip (8) when your opponent is close to winning.")
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }

            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.shInkMed)
                    .frame(width: 32, height: 32)
                    .background(Color.shInk.opacity(0.08), in: RoundedRectangle(cornerRadius: 2))
            }
            .padding(.top, 56)
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
                .font(.shNavLabel)
                .foregroundStyle(Color.shInk)
                .tracking(3)

            Rectangle()
                .fill(Color.shInk.opacity(0.12))
                .frame(height: 1)

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.shParchmentLight.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.shInk.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

private struct InstructionText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.shButtonSm)
            .foregroundStyle(Color.shInkMed)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct BulletPoint: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("—")
                .foregroundStyle(Color.shCrimson.opacity(0.7))
                .font(.shCaption)
            Text(text)
                .font(.shButtonSm)
                .foregroundStyle(Color.shInkMed)
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
            CardView(card: card, size: .player)
                .fixedSize()

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.shNavLabel)
                    .foregroundStyle(Color.shInk)
                    .tracking(1)
                Text(description)
                    .font(.shCaption)
                    .foregroundStyle(Color.shInkMed)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
