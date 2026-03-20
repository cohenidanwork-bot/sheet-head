// ShitHead/Views/SetupView.swift
import SwiftUI

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
