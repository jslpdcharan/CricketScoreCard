import SwiftUI
import CoreData

// MARK: – Parameters passed from the previous view
struct EnterScoreParams: Hashable {
    let match: Match
    let battingTeam: Team
    let bowlingTeam: Team
    let battingPlayers: [Player]
    let bowlingPlayers: [Player]
    let striker: Player
    let nonStriker: Player
    let currentBowler: Player
    let maxOvers: Int
    let target: Int?          // nil in first innings
    let inningsNumber: Int    // 1 or 2
}

// MARK: – Mini stat structs
fileprivate struct Bat {
    var r = 0, b = 0, f = 0, sx = 0
    var sr: Int { b == 0 ? 0 : Int(round(Double(r) * 100 / Double(b))) }
}
fileprivate struct Bowl {
    var bl = 0, ru = 0, wk = 0
    var ov: String { "\(bl / 6).\(bl % 6)" }
    var eco: Double { let o = Double(bl) / 6; return o == 0 ? 0 : Double(ru) / o }
}
fileprivate struct Snap {
    var runs: Int
    var wk: Int
    var bl: Int
    var ov: [String]
    var striker: Player
    var nonStriker: Player
    var bat: [NSManagedObjectID: Bat]
    var bowl: [NSManagedObjectID: Bowl]
    var out: [NSManagedObjectID]
    var over: Over?
}

// MARK: – Main view
struct EnterScoreView: View {
    let p: EnterScoreParams
    private let repo = CricketDataRepository.shared
    
    // live actors
    @State private var striker: Player
    @State private var nonStriker: Player
    @State private var bowler: Player
    
    // live score
    @State private var runs = 0
    @State private var wkts = 0
    @State private var legalBalls = 0
    @State private var overBalls: [String] = []
    
    // stat maps
    @State private var batMap: [NSManagedObjectID: Bat] = [:]
    @State private var bowlMap: [NSManagedObjectID: Bowl] = [:]
    @State private var outSet: Set<NSManagedObjectID> = []
    
    // modal controls
    @State private var pickBatsman = false
    @State private var pickBowler = false
    
    // navigation
    @State private var nextParams: EnterScoreParams?
    @State private var showWinner = false
    
    // undo stack
    @State private var hist: [Snap] = []
    
    // current over for persistence
    @State private var currentOver: Over?
    
    init(params: EnterScoreParams) {
        self.p = params
        _striker = State(initialValue: params.striker)
        _nonStriker = State(initialValue: params.nonStriker)
        _bowler    = State(initialValue: params.currentBowler)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                Text(statusLine).font(.caption)
                
                Text("\(p.battingTeam.teamName ?? "") vs \(p.bowlingTeam.teamName ?? "")")
                    .bold()
                
                Text("\(p.battingTeam.teamName ?? "") \(runs)/\(wkts) (\(legalBalls / 6).\(legalBalls % 6))")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // batsmen table
                VStack {
                    HStack { Text("batsman").bold(); Spacer(); Text("r(b) 4 6 sr").bold() }
                    batsmanRow(striker, onStrike: true)
                    batsmanRow(nonStriker, onStrike: false)
                }
                .padding(.horizontal)
                
                // bowler line
                let bs = bowlMap[bowler.objectID, default: .init()]
                VStack(alignment: .leading) {
                    Text("bowler").bold()
                    Text("\(bowler.playerName ?? "")  \(bs.ov)  \(bs.ru)  \(bs.wk)  \(String(format: "%.1f", bs.eco))")
                }
                .padding(.horizontal)
                
                // balls of current over
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(overBalls, id: \.self) { v in
                            Text(v)
                                .frame(width: 28, height: 28)
                                .background(Circle().stroke())
                        }
                    }.padding(.horizontal)
                }
                
                // keypad
                keypad
                    .disabled(pickBatsman || pickBowler || showWinner)
                
                Spacer()
                
                // winner nav
                NavigationLink(isActive: $showWinner) {
                    WinnerView(match: p.match,
                               winner: winnerName,
                               total: runs,
                               wickets: wkts)
                } label: { EmptyView() }
                
                // second‑innings nav
                .navigationDestination(item: $nextParams) { EnterScoreView(params: $0) }
            }
            // sheets
            .sheet(isPresented: $pickBatsman) { batsmanSheet.interactiveDismissDisabled(true) }
            .sheet(isPresented: $pickBowler)  { bowlerSheet.interactiveDismissDisabled(true)  }
            
            .onAppear {
                initStatMaps()
                ensureOver()
            }
            .navigationBarTitle("enter score", displayMode: .inline)
        }
    }
    
    // MARK: UI building blocks
    private func batsmanRow(_ p: Player, onStrike: Bool) -> some View {
        let s = batMap[p.objectID, default: .init()]
        return HStack {
            Text("\(p.playerName ?? "")\(onStrike ? "*" : "")")
            Spacer()
            Text("\(s.r)(\(s.b))  \(s.f)  \(s.sx)  \(s.sr)")
        }
    }
    
    private var keypad: some View {
        let grid = [GridItem(), GridItem(), GridItem()]
        return LazyVGrid(columns: grid, spacing: 12) {
            ForEach([0, 1, 2, 3, 4, 6], id: \.self) { v in
                Button("\(v)") { addRuns(v) }
                    .keyButton()
            }
            Button("Ex")   { addExtra() } .keyButton()
            Button("W")    { recordWicket() } .keyButton(.red)
            Button("Undo") { undo() } .keyButton(.gray)
        }
        .padding()
    }
    
    // MARK: scoring helpers
    private func addRuns(_ r: Int) {
        guard ready else { return }
        pushSnapshot()
        updateBat(r)
        updateBowl(r, legal: true, wicket: false)
        runs += r
        writeBall(runs: r, isWide: false, isNo: false, isWicket: false)
        finishBall(desc: "\(r)", runs: r, legal: true)
    }
    
    private func addExtra() {
        guard ready else { return }
        pushSnapshot()
        updateBowl(1, legal: false, wicket: false)
        runs += 1
        writeBall(runs: 0, isWide: true, isNo: false, isWicket: false)
        overBalls.append("Ex")
        if targetMet { concludeInnings() }
    }
    
    private func recordWicket() {
        guard ready else { return }
        pushSnapshot()
        updateBowl(0, legal: true, wicket: true)
        wkts += 1
        outSet.insert(striker.objectID)
        writeBall(runs: 0, isWide: false, isNo: false, isWicket: true)
        finishBall(desc: "W", runs: 0, legal: true)
        if wkts < 10 { pickBatsman = true }   // no popup after 10th wicket
    }
    
    private func undo() {
        guard let snap = hist.popLast(), ready else { return }
        restore(from: snap)
    }
    
    // MARK: stat updates
    private func updateBat(_ r: Int) {
        var s = batMap[striker.objectID, default: .init()]
        s.r += r; s.b += 1
        if r == 4 { s.f += 1 }
        if r == 6 { s.sx += 1 }
        batMap[striker.objectID] = s
    }
    private func updateBowl(_ r: Int, legal: Bool, wicket: Bool) {
        var b = bowlMap[bowler.objectID, default: .init()]
        if legal { b.bl += 1 }
        b.ru += r
        if wicket { b.wk += 1 }
        bowlMap[bowler.objectID] = b
    }
    
    // MARK: over / ball persistence
    private func ensureOver() {
        guard currentOver == nil else { return }
        let num = Int16(legalBalls / 6 + 1)
        currentOver = repo.createOver(match: p.match,
                                      overNumber: num,
                                      inningsNumber: Int16(p.inningsNumber),
                                      bowler: bowler)
    }
    private func writeBall(runs: Int, isWide: Bool, isNo: Bool, isWicket: Bool) {
        ensureOver()
        let ballNum = Int16(legalBalls % 6 + 1)
        _ = repo.recordBall(in: currentOver!,
                            ballNumber: ballNum,
                            striker: striker,
                            bowler: bowler,
                            runs: Int16(runs),
                            isWide: isWide,
                            isNoBall: isNo,
                            isWicket: isWicket)
    }
    private func closeOver() {
        if let o = currentOver {
            repo.completeOver(o, scoreAtOverEnd: Int16(runs))
            currentOver = nil
        }
    }
    
    // MARK: ball end
    private func finishBall(desc: String, runs r: Int, legal: Bool) {
        if legal { legalBalls += 1 }
        overBalls.append(desc)
        if r % 2 == 1 { swap(&striker, &nonStriker) }
        
        if inningsDone || targetMet {
            concludeInnings()
            return
        }
        
        if legal && overBalls.filter({ $0 != "Ex" }).count == 6 {
            overBalls.removeAll()
            closeOver()
            swap(&striker, &nonStriker)
            pickBowler = true
        }
    }
    
    // MARK: innings/game conclusion
    private var inningsDone: Bool { legalBalls == p.maxOvers * 6 || wkts == 10 }
    private var targetMet: Bool  { p.target != nil && runs >= p.target! }
    private var ready: Bool      { !pickBatsman && !pickBowler && !showWinner }
    
    private func concludeInnings() {
        closeOver()
        if p.target == nil {
            // build second innings params
            let bats = p.bowlingPlayers
            let bowls = p.battingPlayers
            guard bats.count >= 2 else { showWinner = true; return }
            nextParams = EnterScoreParams(
                match: p.match,
                battingTeam: p.bowlingTeam,
                bowlingTeam: p.battingTeam,
                battingPlayers: bats,
                bowlingPlayers: bowls,
                striker: bats[0],
                nonStriker: bats[1],
                currentBowler: bowls[0],
                maxOvers: p.maxOvers,
                target: runs + 1,
                inningsNumber: 2
            )
        } else {
            showWinner = true
        }
    }
    
    // MARK: undo helpers
    private func pushSnapshot() {
        hist.append(
            Snap(runs: runs, wk: wkts, bl: legalBalls, ov: overBalls,
                 striker: striker, nonStriker: nonStriker,
                 bat: batMap, bowl: bowlMap, out: Array(outSet),
                 over: currentOver)
        )
    }
    private func restore(from s: Snap) {
        runs = s.runs; wkts = s.wk; legalBalls = s.bl; overBalls = s.ov
        striker = s.striker; nonStriker = s.nonStriker
        batMap = s.bat; bowlMap = s.bowl; outSet = Set(s.out)
        currentOver = s.over
    }
    
    // MARK: status & winner
    private var statusLine: String {
        let ballsLeft = max(0, p.maxOvers * 6 - legalBalls)
        if let t = p.target {
            let runsLeft = max(0, t - runs)
            return runsLeft == 0 ? "target reached" : "\(ballsLeft) balls • \(runsLeft) runs to win"
        }
        return "\(ballsLeft) balls left"
    }
    private var winnerName: String {
        if let t = p.target {
            return runs >= t ? p.battingTeam.teamName ?? "team"
                             : p.bowlingTeam.teamName ?? "team"
        }
        return p.battingTeam.teamName ?? "team"
    }
    
    private func initStatMaps() {
        batMap[striker.objectID] = .init()
        batMap[nonStriker.objectID] = .init()
        bowlMap[bowler.objectID]   = .init()
    }
    
    // MARK: sheets
    private var batsmanSheet: some View {
        NavigationStack {
            List(p.battingPlayers) { pl in
                if !outSet.contains(pl.objectID) && pl.objectID != striker.objectID && pl.objectID != nonStriker.objectID {
                    Button(pl.playerName ?? "") {
                        striker = pl
                        batMap[pl.objectID] = batMap[pl.objectID] ?? .init()
                        pickBatsman = false
                    }
                }
            }
            .navigationTitle("select batsman")
        }
    }
    
    private var bowlerSheet: some View {
        NavigationStack {
            List(p.bowlingPlayers) { pl in
                Button(pl.playerName ?? "") {
                    bowler = pl
                    bowlMap[pl.objectID] = bowlMap[pl.objectID] ?? .init()
                    pickBowler = false
                }
            }
            .navigationTitle("select bowler")
        }
    }
}

// MARK: – View extension for keypad buttons
fileprivate extension View {
    func keyButton(_ color: Color = .blue) -> some View {
        self.frame(maxWidth: .infinity, minHeight: 44)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

