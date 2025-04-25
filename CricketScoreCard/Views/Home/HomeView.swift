import SwiftUI

struct HomeView: View {
    @State private var showEnterPlayers = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "cricket.ball.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.accentColor)
                        
                        Text("Cricket Scorecard")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Track and manage your cricket matches")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        // Start Match Button
                        Button(action: { showEnterPlayers = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Start New Match")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal, 24)
                        
                        // Previous Matches Button
                        NavigationLink {
                            PreviousMatchesView()
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Match History")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .foregroundColor(.accentColor)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.accentColor, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
    
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showEnterPlayers) {
                EnterPlayersView()
            }
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        // 1. get an in‑memory preview context
        let ctx = PreviewHelpers.previewContext
        
        // 2. point repository at that context
        CricketDataRepository.shared.useContext(ctx)
        
        // 3. nuke everything & insert three demo matches
        CricketDataRepository.shared.resetAndSeedDemoData()
        
        return HomeView()
            .environment(\.managedObjectContext, ctx)
    }
}
#endif
