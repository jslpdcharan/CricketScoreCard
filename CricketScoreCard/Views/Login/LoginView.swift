import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn = false
    @State private var showSignup = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Login")
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
                    if username.lowercased() == "admin" && password.lowercased() == "admin" {
                        isLoggedIn = true
                    }
                }) {
                    Text("Submit")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(5)
                }
                
                NavigationLink(destination: HomeView(), isActive: $isLoggedIn) {
                    EmptyView()
                }
                
                Button(action: {
                    showSignup = true
                }) {
                    Text("Don't have an account? Create account")
                }
                .padding(.top, 10)
                
                NavigationLink(destination: SignupView(), isActive: $showSignup) {
                    EmptyView()
                }
            }
            .padding()
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
