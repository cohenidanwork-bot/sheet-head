// SheetHead/Views/HomeView.swift — Japanese Mountain Design
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var showInstructions = false

    var body: some View {
        ZStack {
            Color.shParchment.ignoresSafeArea()

            Image("home-screen-bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.90)

            // Parchment tint overlay so text stays legible
            LinearGradient(
                colors: [Color.shParchmentLight.opacity(0.30), Color.shParchmentDeep.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo block
                VStack(spacing: 4) {
                    // Main title
                    Text("SHEET HEAD")
                        .font(.custom("ShipporiMincho-ExtraBold", size: 44))
                        .foregroundStyle(Color.shInk)
                        .tracking(4)
                        .shadow(color: Color.shCrimson.opacity(0.25), radius: 0, x: 0, y: 2)

                    // Tagline
                    Text("The Card Game")
                        .font(.custom("ZenKakuGothicNew-Bold", size: 10))
                        .foregroundStyle(Color.shInkLight)
                        .tracking(6)
                        .textCase(.uppercase)

                    // Hanko seal
                    Text("SH")
                        .font(.custom("NotoSerifCJKjp-Black", size: 18))
                        .foregroundStyle(Color.shCrimson)
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.shCrimson, lineWidth: 2)
                        )
                        .rotationEffect(.degrees(-8))
                        .opacity(0.70)
                        .padding(.top, 10)
                }

                Spacer().frame(height: 32)

                // Fanned card backs
                ZStack {
                    ForEach(0..<5, id: \.self) { i in
                        CardBackView(size: .player)
                            .rotationEffect(.degrees(Double(i - 2) * 12))
                            .offset(x: CGFloat(i - 2) * 18, y: abs(Double(i - 2)) * 4)
                            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                    }
                }
                .frame(height: 100)

                Spacer()

                // Difficulty picker
                VStack(spacing: 10) {
                    Text("DIFFICULTY")
                        .font(.custom("ZenKakuGothicNew-Bold", size: 10))
                        .foregroundStyle(Color.shInkLight)
                        .tracking(3)

                    HStack(spacing: 8) {
                        ForEach([Difficulty.easy, Difficulty.hard], id: \.self) { level in
                            let isSelected = vm.difficulty == level
                            Button { vm.difficulty = level } label: {
                                Text(level.rawValue.uppercased())
                                    .font(.custom("ZenKakuGothicNew-Bold", size: 11))
                                    .foregroundStyle(isSelected ? Color.shParchmentLight : Color.shInk)
                                    .tracking(3)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(isSelected ? Color.shCrimson : Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 2)
                                                    .stroke(isSelected ? Color.shCrimson : Color.shInk,
                                                            lineWidth: 1.5)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: vm.difficulty)
                        }
                    }
                    .padding(.horizontal, 32)
                }

                Spacer().frame(height: 24)

                // Play button
                GamePlayButton(title: "PLAY") { vm.startNewGame() }
                    .padding(.horizontal, 24)

                Spacer().frame(height: 12)

                // How to Play button
                Button(action: { showInstructions = true }) {
                    Text("HOW TO PLAY")
                        .font(.custom("ZenKakuGothicNew-Bold", size: 10))
                        .foregroundStyle(Color.shInkLight)
                        .tracking(4)
                        .textCase(.uppercase)
                }
                .buttonStyle(.plain)

                Spacer().frame(height: 48)
            }
        }
        .fullScreenCover(isPresented: .constant(vm.appPhase != .home)) {
            GameFlowView(vm: vm)
        }
        .sheet(isPresented: $showInstructions) {
            InstructionsView()
        }
    }
}
