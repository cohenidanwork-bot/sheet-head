// ShitHead/Persistence/GamePersistence.swift
import Foundation

enum GamePersistence {
    private static let key = "shithead.savedGame"

    static func save(_ state: GameState) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> GameState? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let state = try? JSONDecoder().decode(GameState.self, from: data)
        else { return nil }
        return state
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
