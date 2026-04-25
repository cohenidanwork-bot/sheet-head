// SheetHead/Audio/SoundManager.swift
import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    enum SFX: String, CaseIterable {
        case cardPlay   = "sfx_card_play"
        case cardFlip   = "sfx_card_flip"
        case cardPickup = "sfx_card_pickup"
        case burn       = "sfx_burn"
        case skip       = "sfx_skip"
        case reversal   = "sfx_reversal"
        case shuffle    = "sfx_shuffle"
        case win        = "sfx_win"
        case lose       = "sfx_lose"
    }

    private let prefs = UserPreferences.shared
    private var musicPlayer: AVAudioPlayer?
    private var sfxPlayers: [SFX: AVAudioPlayer] = [:]

    private init() {
        configureSession()
        preload()
    }

    private func configureSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func preload() {
        for sfx in SFX.allCases {
            guard let url = Bundle.main.url(forResource: sfx.rawValue, withExtension: "mp3"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.prepareToPlay()
            sfxPlayers[sfx] = player
        }

        if let url = Bundle.main.url(forResource: "bgm_ambient", withExtension: "mp3"),
           let player = try? AVAudioPlayer(contentsOf: url) {
            player.numberOfLoops = -1
            player.volume = 0.35
            player.prepareToPlay()
            musicPlayer = player
        }
    }

    func play(_ sfx: SFX) {
        guard prefs.soundEnabled, let player = sfxPlayers[sfx] else { return }
        if player.isPlaying { player.currentTime = 0 }
        player.play()
    }

    func startMusic() {
        guard prefs.musicEnabled, let player = musicPlayer else { return }
        player.currentTime = 0
        player.play()
    }

    func stopMusic() {
        musicPlayer?.stop()
    }

    func pauseMusic() {
        musicPlayer?.pause()
    }

    func resumeMusic() {
        guard prefs.musicEnabled, let player = musicPlayer, !player.isPlaying else { return }
        player.play()
    }

    func setMusicEnabled(_ enabled: Bool) {
        if enabled {
            musicPlayer?.play()
        } else {
            musicPlayer?.pause()
        }
    }
}
