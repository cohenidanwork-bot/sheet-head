// SheetHead/Views/SetupView.swift — Japanese Mountain Design
import SwiftUI

struct GameFlowView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        switch vm.appPhase {
        case .setup:
            SetupView(vm: vm)
        case .playing:
            GameView(vm: vm)
        case .gameOver(let winner, let loser):
            GameOverView(winner: winner, loser: loser, vm: vm)
        case .home:
            EmptyView()
        }
    }
}

struct SetupView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            Color.shParchment.ignoresSafeArea()

            LinearGradient(
                colors: [Color.shParchmentLight.opacity(0.8), Color.shParchmentDeep.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 6) {
                    Text("PICK THREE")
                        .font(.shLogoSm)
                        .foregroundStyle(Color.shInk)
                        .tracking(6)
                        .padding(.top, 52)

                    Text("Choose your face-up cards")
                        .font(.shCaption)
                        .foregroundStyle(Color.shInkLight)
                        .tracking(3)
                        .textCase(.uppercase)
                }

                Spacer().frame(height: 20)

                // Counter badge
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i < vm.chosenFaceUp.count ? Color.shGold : Color.shParchment.opacity(0.15))
                            .frame(width: 8, height: 8)
                    }
                }
                .animation(.spring(response: 0.22, dampingFraction: 0.7), value: vm.chosenFaceUp.count)

                Spacer().frame(height: 20)

                // Card grid
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(CardSize.player.width + 16)), count: 3),
                    spacing: 16
                ) {
                    ForEach(vm.setupCards) { card in
                        CardView(
                            card: card,
                            isSelected: vm.chosenFaceUp.contains(card),
                            size: .player
                        )
                        .onTapGesture {
                            Haptics.light()
                            toggleSetupCard(card)
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Confirm button
                GamePlayButton(title: "CONFIRM") {
                    Haptics.medium()
                    vm.confirmSetup()
                }
                .padding(.horizontal, 24)
                .opacity(vm.chosenFaceUp.count == 3 ? 1.0 : 0.30)
                .disabled(vm.chosenFaceUp.count != 3)
                .padding(.bottom, 48)
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
