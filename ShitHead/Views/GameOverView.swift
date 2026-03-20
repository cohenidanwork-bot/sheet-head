import SwiftUI
struct GameOverView: View {
    let winner: PlayerID
    let shitHead: PlayerID
    @ObservedObject var vm: GameViewModel
    var body: some View { Text("Game Over").foregroundStyle(.white) }
}
