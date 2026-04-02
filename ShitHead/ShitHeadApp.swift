// SheetHead/SheetHeadApp.swift
import SwiftUI

@main
struct SheetHeadApp: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var vm = GameViewModel()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                } else {
                    HomeView()
                        .environmentObject(vm)
                        .transition(.opacity)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background, let state = vm.gameState {
                GamePersistence.save(state)
            }
        }
    }
}
