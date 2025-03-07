// Home Page
import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Heading
            Text("Cricket Scorecard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            Text("Home Page")
                .font(.title2)
                .padding(.bottom, 30)
            
            // Start Match Button
            Button(action: {
                // Action for starting a match (to be implemented)
            }) {
                Text("Start Match")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
            .padding(.horizontal, 20)
            
            // View Previous Matches Button
            Button(action: {
                // Action for viewing previous matches (to be implemented)
            }) {
                Text("View Previous Matches")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .navigationBarTitle("Home", displayMode: .inline) // Show title in navigation bar
    }
}

#Preview {
    HomeView()
}
