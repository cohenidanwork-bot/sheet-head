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

                Text(shitHead == .human
                     ? "Better luck next time."
                     : "The AI is the Shit Head.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Button("Play Again") { vm.startNewGame() }
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
