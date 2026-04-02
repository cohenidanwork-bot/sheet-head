// SheetHead/Views/GameView.swift — Japanese Mountain Design
import SwiftUI

// MARK: - Blast Overlay

struct BlastOverlay: View {
    let type: BlastType
    var opponentName: String = "CPU"
    @State private var kanjiVisible   = false
    @State private var subVisible     = false

    private var displayIcon: String {
        switch type {
        case .burn:         return "燃"
        case .bomb:         return "爆"
        case .playerPickup: return "拾"
        case .cpuPickup:    return "逃"
        case .reversal:     return "逆"
        case .skip:         return "飛"
        }
    }

    private var displayHeadline: String {
        type == .cpuPickup ? "\(opponentName) BAILS" : type.headline
    }
    private var displaySubline: String {
        type == .cpuPickup ? "TAKES THE PILE" : type.subline
    }

    var body: some View {
        ZStack {
            Color.shInk.opacity(0.85).ignoresSafeArea()

            RadialGradient(
                colors: [type.accentColor.opacity(0.20), .clear],
                center: .center, startRadius: 0, endRadius: 280
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                Text(displayIcon)
                    .font(.shKanjiXL)
                    .foregroundStyle(type.accentColor)
                    .shadow(color: type.accentColor.opacity(0.45), radius: 40)
                    .scaleEffect(kanjiVisible ? 1.0 : 0.1)
                    .opacity(kanjiVisible ? 1 : 0)

                Text(displayHeadline)
                    .font(.shButton)
                    .foregroundStyle(Color.shParchment)
                    .tracking(8)
                    .textCase(.uppercase)
                    .offset(y: subVisible ? 0 : 8)
                    .opacity(subVisible ? 1 : 0)

                Text(displaySubline)
                    .font(.shCaption)
                    .foregroundStyle(Color.shParchmentDark)
                    .tracking(4)
                    .textCase(.uppercase)
                    .offset(y: subVisible ? 0 : 6)
                    .opacity(subVisible ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.55)) {
                kanjiVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeOut(duration: 0.20)) { subVisible = true }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Blast Badge (compact pile-level popup)

struct BlastBadge: View {
    let type: BlastType
    var opponentName: String = "CPU"
    @State private var visible = false

    private var displayIcon: String {
        switch type {
        case .burn:         return "燃"
        case .bomb:         return "爆"
        case .playerPickup: return "拾"
        case .cpuPickup:    return "逃"
        case .reversal:     return "逆"
        case .skip:         return "飛"
        }
    }
    private var displayHeadline: String {
        type == .cpuPickup ? "\(opponentName) BAILS" : type.headline
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(displayIcon)
                .font(.shKanjiMd)
                .foregroundStyle(type.accentColor)
                .shadow(color: type.accentColor.opacity(0.6), radius: 8)

            Text(displayHeadline)
                .font(.shButtonSm)
                .foregroundStyle(Color.shParchment)
                .tracking(3)
                .textCase(.uppercase)
                .lineLimit(1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.shInk.opacity(0.90))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(type.accentColor.opacity(0.55), lineWidth: 1.5)
                )
        )
        .shadow(color: type.accentColor.opacity(0.40), radius: 14, y: 4)
        .scaleEffect(visible ? 1.0 : 0.1)
        .opacity(visible ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.52)) { visible = true }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Game View

struct GameView: View {
    @ObservedObject var vm: GameViewModel
    @State private var showPauseMenu = false
    @State private var flyAnimating  = false

    @State private var drawPileCenter:    CGPoint = .zero
    @State private var discardPileCenter: CGPoint = .zero
    @State private var playerHandCenter:  CGPoint = .zero
    @State private var playerTableCenter: CGPoint = .zero
    @State private var opponentCenter:    CGPoint = .zero

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                BoardBackground()

                VStack(spacing: 0) {
                    navBar
                        .padding(.horizontal, 16)
                        .padding(.top, proxy.safeAreaInsets.top + 6)
                        .padding(.bottom, 10)

                    opponentZone
                        .padding(.horizontal, 16)

                    Spacer(minLength: 12)
                    pileZone
                    Spacer(minLength: 12)

                    playerZone
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)

                    actionButtons
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, max(proxy.safeAreaInsets.bottom, 8))
                        .background {
                            Color.shParchmentDeep.opacity(0.95)
                                .overlay(alignment: .top) {
                                    Rectangle()
                                        .fill(Color.shInk.opacity(0.12))
                                        .frame(height: 1)
                                }
                        }
                }

                flyingCardOverlay

                if vm.showBurnFlash {
                    Color.shCrimson.opacity(0.20)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                        .animation(.easeOut(duration: 0.3), value: vm.showBurnFlash)
                }

                if vm.showPhaseBanner {
                    VStack {
                        GameToast(
                            message: vm.phaseBannerText,
                            icon: vm.phaseBannerIcon,
                            tint: vm.phaseBannerTint
                        )
                        .padding(.top, proxy.safeAreaInsets.top + 44)
                        Spacer()
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .animation(.toastIn, value: vm.showPhaseBanner)
                    .allowsHitTesting(false)
                }

                if let blast = vm.activeBlast {
                    BlastBadge(type: blast, opponentName: vm.opponentName)
                        .position(x: discardPileCenter.x, y: discardPileCenter.y - 80)
                        .transition(.scale(scale: 0.1).combined(with: .opacity))
                        .zIndex(50)
                        .id(blast)
                }

                if showPauseMenu { pauseMenuOverlay }
            }
            .ignoresSafeArea()
            .coordinateSpace(name: "game")
            .onChange(of: vm.flyingCards.count) { newCount in
                if newCount > 0 {
                    flyAnimating = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                        withAnimation(.cardFlight) { flyAnimating = true }
                    }
                } else {
                    flyAnimating = false
                }
            }
        }
    }

    // MARK: - Flying Card Overlay

    @ViewBuilder
    private var flyingCardOverlay: some View {
        ZStack {
            ForEach(vm.flyingCards) { fc in
                let from = position(for: fc.from)
                let to   = position(for: fc.to)
                let pos  = flyAnimating ? to : from

                let scale:         CGFloat = flyAnimating ? 1.0 : 0.88
                let rotation:      Double  = flyAnimating ? 0    : fc.rotation
                let shadowRadius:  CGFloat = flyAnimating ? 4    : 16
                let shadowY:       CGFloat = flyAnimating ? 2    : 8
                let shadowOpacity: Double  = flyAnimating ? 0.20 : 0.55

                CardView(card: fc.card, size: .board)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .shadow(color: Color.black.opacity(shadowOpacity),
                            radius: shadowRadius, x: 0, y: shadowY)
                    .position(pos)
                    .allowsHitTesting(false)
            }
        }
        .drawingGroup()
        .ignoresSafeArea()
    }

    private func position(for zone: FlyingCard.FlyZone) -> CGPoint {
        switch zone {
        case .drawPile:     return drawPileCenter
        case .discardPile:  return discardPileCenter
        case .playerHand:   return playerHandCenter
        case .playerFaceUp: return playerTableCenter
        case .opponentHand: return opponentCenter
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button { showPauseMenu = true } label: {
                Text("← QUIT")
                    .font(.shNavLabel)
                    .foregroundStyle(Color.shInk)
                    .tracking(2)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Sheet Head")
                .font(.custom("ShipporiMincho-Bold", size: 15))
                .foregroundStyle(Color.shInk)
                .tracking(4)

            Spacer()

            HStack(spacing: 6) {
                if vm.gameState?.reversalActive == true {
                    Text("逆")
                        .font(.shKanjiXS)
                        .foregroundStyle(Color.shCrimson)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: vm.gameState?.reversalActive)
                }

                Text(vm.gameState?.currentTurn == .human ? "YOUR TURN" : "\(vm.opponentName)'S TURN")
                    .font(.shNavLabel)
                    .foregroundStyle(
                        vm.gameState?.currentTurn == .human ? Color.shCrimson : Color.shInkLight
                    )
                    .tracking(2)
                    .animation(.uiSnap, value: vm.gameState?.currentTurn)
            }
        }
    }

    // MARK: - Opponent Zone

    private var opponentZone: some View {
        let aiPhase     = vm.gameState?.ai.cardPhase ?? .hand
        let tableActive = aiPhase != .hand
        let tableSize: CardSize = tableActive ? .opponent : .mini
        let aiHand      = vm.gameState?.ai.hand.count ?? 0

        return VStack(spacing: tableActive ? 8 : 4) {
            Text(vm.opponentName.uppercased())
                .font(.shCaption)
                .foregroundStyle(Color.shInkMed)
                .tracking(3)

            if aiHand > 0 {
                HStack(spacing: -8) {
                    ForEach(0..<min(aiHand, 6), id: \.self) { _ in
                        CardBackView(size: .opponent)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    ScoreBadge(count: aiHand).offset(x: 8, y: -6)
                }
                .background(GeometryReader { g in
                    Color.clear
                        .onAppear {
                            let f = g.frame(in: .named("game"))
                            opponentCenter = CGPoint(x: f.midX, y: f.midY)
                        }
                        .onChange(of: aiHand) { _ in
                            let f = g.frame(in: .named("game"))
                            opponentCenter = CGPoint(x: f.midX, y: f.midY)
                        }
                })
            }

            HStack(spacing: tableActive ? 8 : 4) {
                ForEach(0..<3, id: \.self) { i in
                    let fd = vm.gameState?.ai.faceDown.count ?? 0
                    let fu = vm.gameState?.ai.faceUp ?? []
                    ZStack {
                        if i < fd {
                            CardView(card: Card(suit: .clubs, rank: .two), isFaceDown: true, size: tableSize)
                        } else {
                            emptySlot(size: tableSize)
                        }
                        if i < fu.count {
                            CardView(card: fu[i], size: tableSize)
                                .offset(y: tableActive ? 4 : 2)
                        }
                    }
                }
            }
            .animation(.cardPlay, value: tableActive)
        }
        .opacity(vm.gameState?.currentTurn == .ai ? 1.0 : 0.75)
        .animation(.easeInOut(duration: 0.25), value: vm.gameState?.currentTurn)
    }

    // MARK: - Pile Zone

    private var pileZone: some View {
        HStack(spacing: 32) {
            // Draw pile
            VStack(spacing: 6) {
                ZStack {
                    if let count = vm.gameState?.deck.count, count > 0 {
                        if count > 2 { CardBackView(size: .board).offset(x: 2, y: 2).opacity(0.50) }
                        if count > 1 { CardBackView(size: .board).offset(x: 1, y: 1).opacity(0.75) }
                        CardBackView(size: .board)
                        ScoreBadge(count: count)
                            .offset(x: CardSize.board.width / 2 - 3,
                                    y: -(CardSize.board.height / 2 - 3))
                    } else {
                        emptySlot(size: .board)
                    }
                }
                .background(GeometryReader { g in
                    Color.clear.onAppear {
                        let f = g.frame(in: .named("game"))
                        drawPileCenter = CGPoint(x: f.midX, y: f.midY)
                    }
                })
                pileLabel("DRAW")
            }

            // Discard pile
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: CardSize.board.cornerRadius)
                        .stroke(Color.shInk.opacity(0.25),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        .frame(width: CardSize.board.width, height: CardSize.board.height)

                    let played = vm.lastPlayedCards
                    if played.count > 1 {
                        ZStack {
                            ForEach(Array(played.enumerated()), id: \.offset) { i, card in
                                let n = Double(played.count)
                                let center = (n - 1) / 2.0
                                let angle  = (Double(i) - center) * 7.0
                                let xOff   = (CGFloat(i) - CGFloat(center)) * 22.0
                                CardView(card: card, size: .board)
                                    .rotationEffect(.degrees(angle))
                                    .offset(x: xOff)
                                    .zIndex(Double(i))
                            }
                        }
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: played.count)
                    } else if played.count == 1, let card = played.first {
                        CardView(card: card, size: .board)
                    } else if let top = vm.gameState?.topOfPile {
                        if let pile = vm.gameState?.discardPile, pile.count >= 2 {
                            CardView(card: pile[pile.count - 2], size: .board)
                                .opacity(0.25).offset(x: -2, y: -2).scaleEffect(0.96)
                        }
                        CardView(card: top, size: .board)
                    }

                    // Transparent-3 effective rank badge
                    if let pile = vm.gameState?.discardPile,
                       let top = pile.last, top.rank == .three,
                       let eff = RuleValidator.effectiveTopRank(of: pile) {
                        Text("= \(eff.display)")
                            .font(.shCaption)
                            .foregroundStyle(Color.shParchment)
                            .tracking(1)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.shInk.opacity(0.88), in: Capsule())
                            .offset(x: CardSize.board.width / 2 + 4,
                                    y: -(CardSize.board.height / 2 - 10))
                    }
                }
                .background(GeometryReader { g in
                    Color.clear.onAppear {
                        let f = g.frame(in: .named("game"))
                        discardPileCenter = CGPoint(x: f.midX, y: f.midY)
                    }
                })
                .onLongPressGesture(minimumDuration: 0.5) {
                    guard vm.gameState?.currentTurn == .human,
                          vm.gameState?.discardPile.isEmpty == false else { return }
                    Haptics.medium()
                    vm.pickUpPile()
                }
                pileLabel("DISCARD")
            }
        }
    }

    private func pileLabel(_ text: String) -> some View {
        Text(text)
            .font(.shCaption)
            .foregroundStyle(Color.shInkMed)
            .tracking(3)
    }

    // MARK: - Player Zone

    private var playerZone: some View {
        let hand        = (vm.gameState?.human.hand ?? []).filter { !vm.hiddenCardIDs.contains($0.id) }.sorted { $0.rank < $1.rank }
        let isMyTurn    = vm.gameState?.currentTurn == .human
        let phase       = vm.gameState?.human.cardPhase ?? .hand
        let tableActive = phase != .hand
        let tableSize: CardSize = tableActive ? .player : .mini

        return VStack(spacing: tableActive ? 8 : 4) {
            Text("YOU")
                .font(.shCaption)
                .foregroundStyle(Color.shInkMed)
                .tracking(3)

            HStack(spacing: tableActive ? 10 : 4) {
                let fd = vm.gameState?.human.faceDown.count ?? 0
                let fu = vm.gameState?.human.faceUp ?? []
                ForEach(0..<3, id: \.self) { i in
                    ZStack {
                        if i < fd {
                            CardView(card: Card(suit: .clubs, rank: .two), isFaceDown: true, size: tableSize)
                                .onTapGesture {
                                    guard phase == .faceDown && isMyTurn else { return }
                                    Haptics.light(); vm.playBlindCard()
                                }
                        } else {
                            emptySlot(size: tableSize)
                        }
                        if i < fu.count && !vm.hiddenCardIDs.contains(fu[i].id) {
                            let card = fu[i]
                            CardView(card: card, isSelected: vm.selectedCards.contains(card), size: tableSize)
                                .offset(y: tableActive ? -5 : -2)
                                .onTapGesture {
                                    guard phase == .faceUp && isMyTurn else { return }
                                    Haptics.light(); vm.toggleCard(card)
                                }
                        }
                    }
                }
            }
            .animation(.cardPlay, value: tableActive)
            .background(GeometryReader { g in
                Color.clear
                    .onAppear {
                        let f = g.frame(in: .named("game"))
                        playerTableCenter = CGPoint(x: f.midX, y: f.midY)
                    }
                    .onChange(of: tableActive) { _ in
                        let f = g.frame(in: .named("game"))
                        playerTableCenter = CGPoint(x: f.midX, y: f.midY)
                    }
            })

            if !hand.isEmpty {
                let count = hand.count
                let spacing: CGFloat = {
                    if count <= 3  { return 10 }
                    if count <= 5  { return 2  }
                    if count <= 7  { return -8 }
                    if count <= 10 { return -18 }
                    return -26
                }()

                handCards(hand: hand, spacing: spacing, scrollable: count > 7, isMyTurn: isMyTurn)
                    .animation(.spring(response: 0.25, dampingFraction: 0.82), value: hand.count)
                    .background(GeometryReader { g in
                        Color.clear
                            .onAppear {
                                let f = g.frame(in: .named("game"))
                                playerHandCenter = CGPoint(x: f.midX, y: f.midY)
                            }
                            .onChange(of: count) { _ in
                                let f = g.frame(in: .named("game"))
                                playerHandCenter = CGPoint(x: f.midX, y: f.midY)
                            }
                    })
            }
        }
        .opacity(isMyTurn ? 1.0 : 0.70)
        .animation(.easeInOut(duration: 0.2), value: vm.gameState?.currentTurn)
    }

    @ViewBuilder
    private func handCards(hand: [Card], spacing: CGFloat, scrollable: Bool, isMyTurn: Bool) -> some View {
        let cardRow = HStack(spacing: spacing) {
            ForEach(hand) { card in
                CardView(card: card, isSelected: vm.selectedCards.contains(card), size: .player)
                    .zIndex(vm.selectedCards.contains(card) ? 10 : 0)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                    .onTapGesture {
                        guard isMyTurn else { return }
                        Haptics.light(); vm.toggleCard(card)
                    }
            }
        }

        if scrollable {
            ScrollView(.horizontal, showsIndicators: false) {
                cardRow
                    .padding(.horizontal, 10)
                    .padding(.top, 18)
                    .padding(.bottom, 4)
            }
            .frame(height: CardSize.player.height + 26)
        } else {
            cardRow
                .padding(.top, 18)
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity)
                .frame(height: CardSize.player.height + 26)
        }
    }

    // MARK: - Action Bar

    private var actionButtons: some View {
        HStack(spacing: 10) {
            if !vm.selectedCards.isEmpty {
                GamePlayButton(title: primaryButtonLabel) {
                    Haptics.medium()
                    vm.playSelectedCards()
                }
                IconButton(systemName: "xmark") { vm.selectedCards = [] }
            } else if vm.mustPickUp {
                GamePlayButton(title: "PICK UP PILE") {
                    Haptics.medium()
                    vm.pickUpPile()
                }
            } else {
                Text(vm.gameState?.currentTurn == .human ? "Select a card" : "\(vm.opponentName) is thinking...")
                    .font(.shButtonSm)
                    .foregroundStyle(Color.shInkFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            IconButton(systemName: "line.3.horizontal") { showPauseMenu = true }
        }
    }

    private var primaryButtonLabel: String {
        let cards = vm.selectedCards
        if cards.count == 1, let c = cards.first {
            return "PLAY \(c.rank.display)\(c.suit.rawValue)"
        }
        return "PLAY \(cards.count) CARDS"
    }

    // MARK: - Helpers

    private func emptySlot(size: CardSize) -> some View {
        RoundedRectangle(cornerRadius: size.cornerRadius)
            .stroke(Color.shInk.opacity(0.20),
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            .frame(width: size.width, height: size.height)
    }

    // MARK: - Pause Menu

    private var pauseMenuOverlay: some View {
        ZStack {
            Color.shInk.opacity(0.60).ignoresSafeArea()
                .onTapGesture { showPauseMenu = false }

            VStack(spacing: 0) {
                // Hanko-style header
                VStack(spacing: 4) {
                    Text("SH")
                        .font(.shKanjiSm)
                        .foregroundStyle(Color.shCrimson.opacity(0.7))
                    Text("PAUSED")
                        .font(.shNavLabel)
                        .foregroundStyle(Color.shInk)
                        .tracking(6)
                }
                .padding(.top, 28).padding(.bottom, 20)

                Divider()
                    .background(Color.shInk.opacity(0.12))

                VStack(spacing: 0) {
                    pauseBtn("Resume",    icon: "play.fill")  { showPauseMenu = false }
                    Divider().background(Color.shInk.opacity(0.08))
                    pauseBtn("Main Menu", icon: "house.fill") {
                        showPauseMenu = false; vm.goHome()
                    }
                }
                .padding(.bottom, 24)
            }
            .frame(width: 270)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.shParchmentLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.shInk.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.6), radius: 24, y: 10)
        }
    }

    private func pauseBtn(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                    .foregroundStyle(Color.shInkLight)
                Text(title)
                    .foregroundStyle(Color.shInk)
                Spacer()
            }
            .font(.shButtonSm)
            .tracking(2)
            .padding(.horizontal, 20).padding(.vertical, 16)
        }
    }
}

// MARK: - Board Background

struct BoardBackground: View {
    var body: some View {
        ZStack {
            Color.shParchment.ignoresSafeArea()

            Image("game-board-bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Subtle edge darkening for card readability — NOT a dark overlay
            RadialGradient(
                colors: [Color.clear, Color.shInk.opacity(0.08)],
                center: .center,
                startRadius: 200,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Game Play Button

struct GamePlayButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.shButtonSm)
                .foregroundStyle(Color.shParchmentLight)
                .tracking(3)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.shCrimson, in: RoundedRectangle(cornerRadius: 2))
                .shadow(color: Color.shCrimson.opacity(0.40), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared Components

struct ScoreBadge: View {
    let count: Int
    var body: some View {
        Text("\(count)")
            .font(.shScore)
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(Color.shCrimson, in: Circle())
            .overlay(Circle().stroke(Color.shParchmentLight, lineWidth: 1.5))
            .contentTransition(.numericText())
    }
}

struct IconButton: View {
    let systemName: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.shInkMed)
                .frame(width: 36, height: 36)
                .background(
                    Color.shInk.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

struct GameToast: View {
    let message: String
    let icon: String
    let tint: Color
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
            Text(message)
                .font(.shButtonSm)
                .foregroundStyle(Color.shParchment)
                .tracking(2)
        }
        .padding(.horizontal, 18).padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.shBoardMid.opacity(0.96))
                .overlay(Capsule().stroke(Color.shParchment.opacity(0.15), lineWidth: 1))
        )
        .shadow(color: Color.black.opacity(0.40), radius: 10, y: 4)
    }
}
