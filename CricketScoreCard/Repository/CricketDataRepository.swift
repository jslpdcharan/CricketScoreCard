import CoreData
import Foundation

class CricketDataRepository {
    static let shared = CricketDataRepository()
    private init() {}
    
    private var context: NSManagedObjectContext {
        fatalError("Set your NSPersistentContainer.viewContext here.")
    }
    
    func createUser(username: String, password: String) -> User? {
        let user = User(context: context)
        user.userID = UUID()
        user.username = username
        user.password = password
        saveContext()
        return user
    }
    
    func createMatch(for user: User, tossResult: String? = nil) -> Match {
        let match = Match(context: context)
        match.matchID = UUID()
        match.dateStarted = Date()
        match.isCompleted = false
        match.tossResult = tossResult
        match.user = user
        saveContext()
        return match
    }
    
    func createTeam(match: Match, teamName: String) -> Team {
        let team = Team(context: context)
        team.teamID = UUID()
        team.teamName = teamName
        team.match = match
        saveContext()
        return team
    }
    
    func createPlayer(team: Team, name: String) -> Player {
        let player = Player(context: context)
        player.playerID = UUID()
        player.playerName = name
        player.team = team
        saveContext()
        return player
    }
    
    func createOver(match: Match,
                    overNumber: Int16,
                    inningsNumber: Int16,
                    bowler: Player? = nil,
                    startTime: Date? = Date()) -> Over {
        let over = Over(context: context)
        over.overID = UUID()
        over.overNumber = (overNumber)
        over.inningsNumber = (inningsNumber)
        over.isComplete = false
        over.scoreAtOverEnd = 0
        over.startTime = startTime
        over.match = match
        over.bowler = bowler
        saveContext()
        return over
    }
    
    func recordBall(in over: Over,
                    ballNumber: Int16,
                    striker: Player?,
                    bowler: Player?,
                    runs: Int16,
                    isWide: Bool,
                    isNoBall: Bool,
                    isWicket: Bool) -> BallEvent {
        let ball = BallEvent(context: context)
        ball.ballID = UUID()
        ball.ballNumber = (ballNumber)
        ball.runs = (runs)
        ball.isWide = isWide
        ball.isNoBall = isNoBall
        ball.isWicket = isWicket
        ball.timestamp = Date()
        ball.over = over
        ball.striker = striker
        ball.bowler = bowler
        saveContext()
        return ball
    }
    
    func completeOver(_ over: Over, scoreAtOverEnd: Int16, endDate: Date? = Date()) {
        over.isComplete = true
        over.scoreAtOverEnd = scoreAtOverEnd
        over.endDate = endDate
        saveContext()
    }
    
    func completeMatch(_ match: Match) {
        match.isCompleted = true
        saveContext()
    }
    
    func fetchOvers(for match: Match, innings: Int) -> [Over] {
        let req: NSFetchRequest<Over> = Over.fetchRequest()
        req.predicate = NSPredicate(format: "match == %@ AND inningsNumber == %d", match, innings)
        req.sortDescriptors = [NSSortDescriptor(key: "overNumber", ascending: true)]
        return (try? context.fetch(req)) ?? []
    }
    
    func fetchBalls(for over: Over) -> [BallEvent] {
        let req: NSFetchRequest<BallEvent> = BallEvent.fetchRequest()
        req.predicate = NSPredicate(format: "over == %@", over)
        req.sortDescriptors = [NSSortDescriptor(key: "ballNumber", ascending: true)]
        return (try? context.fetch(req)) ?? []
    }
    
    func fetchRunsFor(player: Player, in match: Match, innings: Int? = nil) -> Int {
        var totalRuns = 0
        let req: NSFetchRequest<Over> = Over.fetchRequest()
        if let i = innings {
            req.predicate = NSPredicate(format: "match == %@ AND inningsNumber == %d", match, i)
        } else {
            req.predicate = NSPredicate(format: "match == %@", match)
        }
        let overs = (try? context.fetch(req)) ?? []
        for over in overs {
            let balls = fetchBalls(for: over)
            for b in balls where b.striker == player {
                if b.isWide || b.isNoBall { totalRuns += 1 }
                totalRuns += Int(b.runs)
            }
        }
        return totalRuns
    }
    
    func fetchWicketsFor(bowler: Player, in match: Match, innings: Int? = nil) -> Int {
        var totalWickets = 0
        let req: NSFetchRequest<Over> = Over.fetchRequest()
        if let i = innings {
            req.predicate = NSPredicate(format: "match == %@ AND inningsNumber == %d", match, i)
        } else {
            req.predicate = NSPredicate(format: "match == %@", match)
        }
        let overs = (try? context.fetch(req)) ?? []
        for over in overs {
            let balls = fetchBalls(for: over)
            for b in balls where b.isWicket && b.bowler == bowler {
                totalWickets += 1
            }
        }
        return totalWickets
    }
    
    func fetchTotalExtras(in match: Match, innings: Int? = nil) -> Int {
        var extras = 0
        let req: NSFetchRequest<Over> = Over.fetchRequest()
        if let i = innings {
            req.predicate = NSPredicate(format: "match == %@ AND inningsNumber == %d", match, i)
        } else {
            req.predicate = NSPredicate(format: "match == %@", match)
        }
        let overs = (try? context.fetch(req)) ?? []
        for over in overs {
            let balls = fetchBalls(for: over)
            for b in balls {
                if b.isWide || b.isNoBall { extras += 1 }
            }
        }
        return extras
    }
    
    func calculateScore(in match: Match, innings: Int? = nil) -> Int {
        var total = 0
        let req: NSFetchRequest<Over> = Over.fetchRequest()
        if let i = innings {
            req.predicate = NSPredicate(format: "match == %@ AND inningsNumber == %d", match, i)
        } else {
            req.predicate = NSPredicate(format: "match == %@", match)
        }
        let overs = (try? context.fetch(req)) ?? []
        for over in overs {
            let balls = fetchBalls(for: over)
            for b in balls {
                if b.isWide || b.isNoBall { total += 1 }
                total += Int(b.runs)
            }
        }
        return total
    }
    
    func fetchTopBatsman(in match: Match, innings: Int? = nil) -> Player? {
        var maxRuns = 0
        var topPlayer: Player?
        let req: NSFetchRequest<Player> = Player.fetchRequest()
        req.predicate = NSPredicate(format: "team.match == %@", match)
        let players = (try? context.fetch(req)) ?? []
        for p in players {
            let r = fetchRunsFor(player: p, in: match, innings: innings)
            if r > maxRuns {
                maxRuns = r
                topPlayer = p
            }
        }
        return topPlayer
    }
    
    func fetchTopBowler(in match: Match, innings: Int? = nil) -> Player? {
        var maxWickets = 0
        var topPlayer: Player?
        let req: NSFetchRequest<Player> = Player.fetchRequest()
        req.predicate = NSPredicate(format: "team.match == %@", match)
        let players = (try? context.fetch(req)) ?? []
        for p in players {
            let w = fetchWicketsFor(bowler: p, in: match, innings: innings)
            if w > maxWickets {
                maxWickets = w
                topPlayer = p
            }
        }
        return topPlayer
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }
}
