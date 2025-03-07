import SwiftUI

struct SignupView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isSignedUp = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign Up")
                .font(.largeTitle)
                .bold()
            
            TextField("Username", text: $username)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
            
            Button(action: {

                isSignedUp = true
            }) {
                Text("Submit")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(5)
            }
            
            NavigationLink(destination: HomeView(), isActive: $isSignedUp) {
                EmptyView()
            }
        }
        .padding()
        .navigationBarTitle("Sign Up", displayMode: .inline)
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}
