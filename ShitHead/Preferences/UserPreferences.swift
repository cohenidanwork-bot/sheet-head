// SheetHead/Preferences/UserPreferences.swift
import SwiftUI

final class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    @AppStorage("pref.soundEnabled")   var soundEnabled:   Bool   = true
    @AppStorage("pref.musicEnabled")   var musicEnabled:   Bool   = true
    @AppStorage("pref.hapticsEnabled") var hapticsEnabled: Bool   = true
    @AppStorage("pref.difficulty")     private var difficultyRaw: String = Difficulty.easy.rawValue

    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .easy }
        set { difficultyRaw = newValue.rawValue; objectWillChange.send() }
    }
}
