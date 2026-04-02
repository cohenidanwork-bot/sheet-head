// SheetHead/Views/SplashView.swift
import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.shParchment.ignoresSafeArea()

            Image("launch-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 260, height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 48))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.6)) {
                opacity = 1
            }
        }
    }
}
