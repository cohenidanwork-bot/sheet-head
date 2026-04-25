// SheetHead/Views/SettingsView.swift — Japanese Mountain Design
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var prefs = UserPreferences.shared

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.shParchment.ignoresSafeArea()

            LinearGradient(
                colors: [Color.shParchmentLight.opacity(0.6), Color.shParchmentDeep.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    VStack(spacing: 6) {
                        Text("SETTINGS")
                            .font(.shLogoSm)
                            .foregroundStyle(Color.shInk)
                            .tracking(6)

                        Text("Sheet Head")
                            .font(.custom("ShipporiMincho-Bold", size: 13))
                            .foregroundStyle(Color.shInkLight)
                            .tracking(4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 64)
                    .padding(.bottom, 8)

                    Divider()
                        .background(Color.shInk.opacity(0.15))

                    // Audio
                    SettingsSection(title: "AUDIO") {
                        SettingsToggleRow(
                            label: "Background Music",
                            icon: "music.note",
                            isOn: $prefs.musicEnabled
                        )
                        .onChange(of: prefs.musicEnabled) { _, enabled in
                            SoundManager.shared.setMusicEnabled(enabled)
                        }

                        Divider()
                            .background(Color.shInk.opacity(0.08))
                            .padding(.vertical, 4)

                        SettingsToggleRow(
                            label: "Sound Effects",
                            icon: "speaker.wave.2",
                            isOn: $prefs.soundEnabled
                        )
                    }

                    // Haptics
                    SettingsSection(title: "FEEL") {
                        SettingsToggleRow(
                            label: "Haptics",
                            icon: "hand.tap",
                            isOn: $prefs.hapticsEnabled
                        )
                    }

                    // Difficulty
                    SettingsSection(title: "DIFFICULTY") {
                        HStack(spacing: 8) {
                            ForEach([Difficulty.easy, Difficulty.hard], id: \.self) { level in
                                let isSelected = prefs.difficulty == level
                                Button { prefs.difficulty = level } label: {
                                    Text(level.rawValue.uppercased())
                                        .font(.shNavLabel)
                                        .foregroundStyle(isSelected ? Color.shParchmentLight : Color.shInk)
                                        .tracking(3)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(isSelected ? Color.shCrimson : Color.clear)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .stroke(
                                                            isSelected ? Color.shCrimson : Color.shInk.opacity(0.35),
                                                            lineWidth: 1.5
                                                        )
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                                .animation(.spring(response: 0.22, dampingFraction: 0.7), value: prefs.difficulty)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }

            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.shInkMed)
                    .frame(width: 32, height: 32)
                    .background(Color.shInk.opacity(0.08), in: RoundedRectangle(cornerRadius: 2))
            }
            .padding(.top, 56)
            .padding(.trailing, 20)
        }
    }
}

// MARK: - Sub-components

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.shNavLabel)
                .foregroundStyle(Color.shInk)
                .tracking(3)

            Rectangle()
                .fill(Color.shInk.opacity(0.12))
                .frame(height: 1)

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.shParchmentLight.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.shInk.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

private struct SettingsToggleRow: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.shCrimson)
                .frame(width: 20)

            Text(label)
                .font(.shButtonSm)
                .foregroundStyle(Color.shInkMed)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.shCrimson)
        }
    }
}
