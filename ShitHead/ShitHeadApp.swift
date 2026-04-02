// SheetHead/SheetHeadApp.swift
import SwiftUI

@main
struct SheetHeadApp: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var vm = GameViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(vm)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background, let state = vm.gameState {
                GamePersistence.save(state)
            }
        }
    }
}
