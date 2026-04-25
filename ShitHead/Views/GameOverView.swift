// SheetHead/Views/GameOverView.swift — Japanese Mountain Design
import SwiftUI

struct GameOverView: View {
    let winner: PlayerID
    let loser: PlayerID
    @ObservedObject var vm: GameViewModel

    private var isLoser: Bool { loser == .human }

    var body: some View {
        ZStack {
            if isLoser {
                // Lose screen: flat parchment
                Color.shParchment.ignoresSafeArea()
            } else {
                // Win screen: parchment with warm gradient
                LinearGradient(
                    colors: [Color.shParchmentLight, Color.shParchment, Color.shParchmentDeep],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer()

                if isLoser {
                    // LOSE
                    Text("SH")
                        .font(.custom("ShipporiMincho-ExtraBold", size: 80))
                        .foregroundStyle(Color.shInkFaint)
                        .opacity(0.28)

                    Text("Sheet Head")
                        .font(.shDisplay)
                        .foregroundStyle(Color.shInk)
                        .tracking(4)
                        .padding(.top, -16)

                    Text("You are the Sheet Head")
                        .font(.shCaption)
                        .foregroundStyle(Color.shInkLight)
                        .tracking(3)
                        .textCase(.uppercase)
                        .padding(.top, 8)

                    // Hanko seal
                    Text("SH")
                        .font(.shKanjiSm)
                        .foregroundStyle(Color.shInkFaint)
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.shInkFaint, lineWidth: 3)
                        )
                        .rotationEffect(.degrees(5))
                        .opacity(0.45)
                        .padding(.top, 24)

                } else {
                    // WIN
                    Text("勝")
                        .font(.shKanjiXL)
                        .foregroundStyle(Color.shCrimson)
                        .shadow(color: Color.shCrimson.opacity(0.25), radius: 20)

                    Text("Victory")
                        .font(.shDisplay)
                        .foregroundStyle(Color.shInk)
                        .tracking(6)
                        .padding(.top, -16)

                    Text("You cleared all your cards")
                        .font(.shCaption)
                        .foregroundStyle(Color.shInkLight)
                        .tracking(3)
                        .textCase(.uppercase)
                        .padding(.top, 8)

                    // Hanko seal
                    Text("勝")
                        .font(.shKanjiSm)
                        .foregroundStyle(Color.shCrimson)
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.shCrimson, lineWidth: 3)
                        )
                        .rotationEffect(.degrees(-12))
                        .opacity(0.70)
                        .padding(.top, 24)
                }

                Spacer()

                // Fanned card backs
                ZStack {
                    ForEach(0..<5, id: \.self) { i in
                        CardBackView(size: .player)
                            .rotationEffect(.degrees(Double(i - 2) * 10))
                            .offset(x: CGFloat(i - 2) * 16, y: abs(Double(i - 2)) * 3)
                            .shadow(color: .black.opacity(0.20), radius: 5, x: 0, y: 3)
                    }
                }
                .frame(height: 90)

                Spacer()

                // Buttons
                VStack(spacing: 10) {
                    GamePlayButton(title: isLoser ? "TRY AGAIN" : "PLAY AGAIN") {
                        Haptics.medium()
                        vm.goHome()
                    }

                    Button {
                        vm.appPhase = .home
                    } label: {
                        Text("QUIT")
                            .font(.shButtonSm)
                            .foregroundStyle(Color.shInkLight)
                            .tracking(3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.shInkLight.opacity(0.40), lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
            }
        }
        .onAppear {
            if isLoser { Haptics.error() } else { Haptics.success() }
        }
    }
}
