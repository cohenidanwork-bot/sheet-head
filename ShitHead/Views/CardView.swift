// SheetHead/Views/CardView.swift — Japanese Mountain Design
import SwiftUI

struct CardView: View {
    let card: Card
    var isFaceDown: Bool = false
    var isSelected: Bool = false
    var size: CardSize = .player

    var body: some View {
        Group {
            if isFaceDown {
                CardBackView(size: size)
            } else {
                CardFaceView(card: card, size: size, isSelected: isSelected)
            }
        }
        .offset(y: isSelected ? -10 : 0)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isSelected)
    }
}

// MARK: - Card Back

struct CardBackView: View {
    let size: CardSize

    var body: some View {
        Image("card-back")
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            .shadow(color: Color.black.opacity(0.45), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Card Face

struct CardFaceView: View {
    let card: Card
    let size: CardSize
    var isSelected: Bool = false

    private var suitColor: Color {
        switch card.suit {
        case .hearts, .diamonds: return Color.shCrimson
        case .clubs, .spades:    return Color.shInk
        }
    }

    private var centerSuitSize: CGFloat {
        switch size {
        case .board:    return 48
        case .player:   return 32
        case .opponent: return 22
        case .mini:     return 16
        }
    }

    private var cornerRankSize: CGFloat {
        switch size {
        case .board:    return 14
        case .player:   return 11
        case .opponent: return 8
        case .mini:     return 7
        }
    }

    private var cornerSuitSize: CGFloat { cornerRankSize * 0.85 }

    private var inset: CGFloat {
        switch size {
        case .board:    return 6
        case .player:   return 4
        case .opponent: return 3
        case .mini:     return 2
        }
    }

    // Power badges — only on player/board size cards
    private var powerBadge: (label: String, color: Color)? {
        guard size == .player || size == .board else { return nil }
        switch card.rank {
        case .two:   return ("RESET", Color.shInkMed)
        case .three: return ("THRU", Color.shInkMed)
        case .seven: return ("REVERSE", Color.shCrimsonDeep)
        case .eight: return ("SKIP", Color.shInkMed)
        case .ten:   return ("BURN", Color.shCrimson)
        default:     return nil
        }
    }

    var body: some View {
        ZStack {
            // Card surface — parchment
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(Color.shParchmentLight)
                .overlay(
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .stroke(Color.shInk, lineWidth: 2.0)
                )
                .shadow(color: Color.shInk.opacity(0.15), radius: 1, x: 0, y: 1)

            // Top-left corner
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    VStack(alignment: .center, spacing: 0) {
                        Text(card.rank.display)
                            .font(.custom("ShipporiMincho-Bold", size: cornerRankSize))
                            .foregroundStyle(suitColor)
                            .lineLimit(1)
                        Text(card.suit.rawValue)
                            .font(.system(size: cornerSuitSize))
                            .foregroundStyle(suitColor)
                    }
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
            .padding(inset)

            // Center suit
            Text(card.suit.rawValue)
                .font(.system(size: centerSuitSize))
                .foregroundStyle(suitColor)

            // Bottom-right corner (inverted)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    VStack(alignment: .center, spacing: 0) {
                        Text(card.suit.rawValue)
                            .font(.system(size: cornerSuitSize))
                            .foregroundStyle(suitColor)
                        Text(card.rank.display)
                            .font(.custom("ShipporiMincho-Bold", size: cornerRankSize))
                            .foregroundStyle(suitColor)
                            .lineLimit(1)
                    }
                    .rotationEffect(.degrees(180))
                }
            }
            .padding(inset)

            // Power badge strip at bottom
            if let badge = powerBadge {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Text(badge.label)
                        .font(.custom("ZenKakuGothicNew-Bold", size: 7))
                        .foregroundStyle(Color.shParchmentLight)
                        .tracking(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                        .background(badge.color)
                }
                .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(isSelected ? Color.shCrimson : Color.clear, lineWidth: 2.5)
        )
        .shadow(
            color: isSelected ? Color.shCrimson.opacity(0.45) : Color.black.opacity(0.15),
            radius: isSelected ? 10 : 3,
            x: 0, y: isSelected ? 4 : 1
        )
    }
}
