// ShitHead/Views/HomeView.swift
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var showInstructions = false

    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.45, blue: 0.25)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Text("💩")
                        .font(.system(size: 64))
                    Text("Shit Head")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4)
                }

                Spacer()

                VStack(spacing: 16) {
                    Text("Difficulty")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))

                    Picker("Difficulty", selection: $vm.difficulty) {
                        Text("Easy").tag(Difficulty.easy)
                        Text("Hard").tag(Difficulty.hard)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 60)
                }

                Button(action: vm.startNewGame) {
                    Text("New Game")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.orange)
                                .shadow(color: .black.opacity(0.3), radius: 6)
                        )
                }

                Button(action: { showInstructions = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                        Text("How to Play")
                    }
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 36)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }

                Spacer()
            }
        }
        .onAppear { vm.resumeIfSaved() }
        .fullScreenCover(isPresented: .constant(vm.appPhase != .home)) {
            GameFlowView(vm: vm)
        }
        .sheet(isPresented: $showInstructions) {
            InstructionsView()
        }
    }
}
