// ShitHead/Views/CardView.swift
import SwiftUI

struct CardView: View {
    let card: Card
    var isFaceDown: Bool = false
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isFaceDown ? Color.blue.gradient : Color.white.gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.yellow : Color.gray.opacity(0.3),
                                lineWidth: isSelected ? 2.5 : 1)
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
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }

    private var suitColor: Color {
        switch card.suit {
        case .hearts, .diamonds: return .red
        case .clubs, .spades: return .black
        }
    }
}
