import SwiftUI
import CoreData

private struct MatchCardView: View {
    let match: Match
    
    private var teams: [Team] {
        (match.teams as? Set<Team>)?
            .sorted { ($0.teamName ?? "") < ($1.teamName ?? "") } ?? []
    }
    private var teamA: String {
        teams.first?.teamName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? teams[0].teamName! : "Unnamed"
    }
    private var teamB: String {
        teams.dropFirst().first?.teamName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? teams[1].teamName! : "Unnamed"
    }
    
    private var winner: String {
        let repo = CricketDataRepository.shared
        let a = repo.calculateScore(in: match, innings: 1)
        let b = repo.calculateScore(in: match, innings: 2)
        return a == b ? "Tie" : (a > b ? teamA : teamB)
    }
    
    private var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: match.dateStarted ?? Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(teamA) vs \(teamB)")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    
                    Text("🏆 Winner: \(winner)")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    
                    Text(dateString)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.vertical, 4)
    }
}

struct PreviousMatchesView: View {
    @Environment(\.managedObjectContext) private var ctx
    private let repo = CricketDataRepository.shared
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "dateStarted", ascending: false)],
        predicate: NSPredicate(format: "isCompleted == YES"),
        animation: .default
    )
    private var matches: FetchedResults<Match>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(matches) { match in
                        NavigationLink {
                            MatchResultsView(match: match)
                        } label: {
                            MatchCardView(match: match)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                repo.deleteMatch(match)
                            } label: {
                                Label("Delete Match", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Previous Matches")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}
