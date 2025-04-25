//import SwiftUI
//
//struct LoginView: View {
//    @State private var username: String = ""
//    @State private var password: String = ""
//    @State private var isLoggedIn = false
//    @State private var showSignup = false
//
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 20) {
//                Text("Login")
//                    .font(.largeTitle)
//                    .bold()
//                
//                TextField("Username", text: $username)
//                    .padding()
//                    .background(Color.gray.opacity(0.2))
//                    .cornerRadius(5)
//                
//                SecureField("Password", text: $password)
//                    .padding()
//                    .background(Color.gray.opacity(0.2))
//                    .cornerRadius(5)
//                
//                Button(action: {
//                    if username.lowercased() == "admin" && password.lowercased() == "admin" {
//                        isLoggedIn = true
//                    }
//                }) {
//                    Text("Submit")
//                        .foregroundColor(.white)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(Color.blue)
//                        .cornerRadius(5)
//                }
//                
//                NavigationLink(destination: HomeView(), isActive: $isLoggedIn) {
//                    EmptyView()
//                }
//                
//                Button(action: {
//                    showSignup = true
//                }) {
//                    Text("Don't have an account? Create account")
//                }
//                .padding(.top, 10)
//                
//                NavigationLink(destination: SignupView(), isActive: $showSignup) {
//                    EmptyView()
//                }
//            }
//            .padding()
//            .navigationBarBackButtonHidden(true)
//            .navigationBarHidden(true)
//        }
//    }
//}
//
//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView()
//    }
//}





import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    @State private var showSignup = false
    @State private var showAlert = false
    @State private var alertMsg  = ""
    
    private let repo = CricketDataRepository.shared
    
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
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
                
                Button(action: submit) {
                    Text("Submit")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(5)
                }
                
                NavigationLink(destination: HomeView(),
                               isActive: $isLoggedIn) { EmptyView() }
                
                Button("Don't have an account? Create account") {
                    showSignup = true
                }
                .padding(.top, 10)
                
                NavigationLink(destination: SignupView(),
                               isActive: $showSignup) { EmptyView() }
            }
            .padding()
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            .onAppear {
                // every time the Login screen becomes visible, reset the form
                username   = ""
                password   = ""
                isLoggedIn = false        // so the NavigationLink is ready for next login
                showAlert  = false
            }
            .alert("Login failed",
                   isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMsg)
            }
        }

    }
    
    private func submit() {
        let user = username.trimmingCharacters(in: .whitespaces)
        guard !user.isEmpty, !password.isEmpty else {
            alertMsg = "Please enter username and password."
            showAlert = true
            return
        }
        guard repo.validateUser(username: user, password: password) else {
            alertMsg = repo.fetchUser(username: user) == nil
                      ? "Username not found."
                      : "Incorrect password."
            showAlert = true
            return
        }
        isLoggedIn = true
    }

}
