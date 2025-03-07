import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    
    var body: some View {
        VStack {
            Text("Cricket Live Score")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isActive = true
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            LoginView()
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
