import SwiftUI
struct GameView: View {
    @ObservedObject var vm: GameViewModel
    var body: some View { Text("Game").foregroundStyle(.white) }
}
