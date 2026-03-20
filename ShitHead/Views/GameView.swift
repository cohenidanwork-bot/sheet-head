// ShitHead/Views/GameView.swift
import SwiftUI

struct GameView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.45, blue: 0.25).ignoresSafeArea()

            // Subtle felt dot texture
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

            VStack(spacing: 8) {
                aiZone.padding(.top, 8)
                Spacer()
                middleZone
                Spacer()
                playerZone.padding(.bottom, 8)
            }
            .padding(.horizontal, 12)

            // Burn flash overlay
            if vm.showBurnFlash {
                Color.yellow.opacity(0.35)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.6), value: vm.showBurnFlash)
            }

            // Phase transition banner
            if vm.showPhaseBanner {
                VStack {
                    Spacer()
                    Text(vm.phaseBannerText)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.75)))
                        .padding(.bottom, 120)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: vm.showPhaseBanner)
            }
        }
    }

    // MARK: - AI Zone (top)

    private var aiZone: some View {
        VStack(spacing: 6) {
            HStack {
                Text("AI")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                if vm.gameState?.currentTurn == .ai {
                    HStack(spacing: 4) {
                        Circle().fill(Color.yellow).frame(width: 6, height: 6)
                        Text("thinking...")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
            }

            // AI table cards (face-down slots with face-up on top)
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    ZStack {
                        CardView(card: Card(suit: .clubs, rank: .two), isFaceDown: true)
                        if let faceUp = vm.gameState?.ai.faceUp, i < faceUp.count {
                            CardView(card: faceUp[i]).offset(y: -4)
                        }
                    }
                }
            }

            // AI hand (backs only)
            HStack(spacing: -20) {
                ForEach(0..<(vm.gameState?.ai.hand.count ?? 0), id: \.self) { _ in
                    CardView(card: Card(suit: .clubs, rank: .two), isFaceDown: true)
                }
            }
        }
    }

    // MARK: - Middle Zone

    private var middleZone: some View {
        HStack(spacing: 32) {
            // Draw pile
            VStack(spacing: 4) {
                ZStack {
                    if let count = vm.gameState?.deck.count, count > 0 {
                        ForEach(0..<min(3, count), id: \.self) { i in
                            CardView(card: Card(suit: .clubs, rank: .two), isFaceDown: true)
                                .offset(x: CGFloat(i) * 0.5, y: CGFloat(-i) * 0.5)
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.25),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [5]))
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
                    .stroke(Color.white.opacity(0.2),
                            style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .frame(width: 52, height: 76)
                if let top = vm.gameState?.topOfPile {
                    CardView(card: top)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: vm.gameState?.topOfPile?.id)
        }
    }

    // MARK: - Player Zone (bottom)

    private var playerZone: some View {
        VStack(spacing: 8) {
            // Player hand (scrollable)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -10) {
                    ForEach(vm.gameState?.human.hand ?? []) { card in
                        CardView(
                            card: card,
                            isSelected: vm.selectedCards.contains(card)
                        )
                        .onTapGesture { vm.toggleCard(card) }
                    }
                }
                .padding(.horizontal, 8)
            }

            // Player table cards
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    ZStack {
                        // Face-down slot — tappable during blind phase
                        CardView(card: Card(suit: .clubs, rank: .two), isFaceDown: true)
                            .onTapGesture {
                                if vm.gameState?.human.cardPhase == .faceDown {
                                    vm.playBlindCard()
                                }
                            }
                        // Face-up card on top (if available)
                        if let faceUp = vm.gameState?.human.faceUp, i < faceUp.count {
                            let card = faceUp[i]
                            CardView(card: card, isSelected: vm.selectedCards.contains(card))
                                .offset(y: -4)
                                .onTapGesture {
                                    if vm.gameState?.human.cardPhase == .faceUp {
                                        vm.toggleCard(card)
                                    }
                                }
                        }
                    }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                if !vm.selectedCards.isEmpty {
                    Button("Play") { vm.playSelectedCards() }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.orange))
                }

                let noMoves: Bool = {
                    guard let state = vm.gameState, state.currentTurn == .human else { return false }
                    return vm.selectedCards.isEmpty && GameEngine.legalMoves(for: .human, in: state).isEmpty
                }()

                if noMoves {
                    Button("Pick Up") { vm.pickUpPile() }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.8)))
                }
            }
            .frame(height: 44)
        }
    }
}
