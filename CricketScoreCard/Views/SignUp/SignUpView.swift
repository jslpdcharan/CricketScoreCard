//import SwiftUI
//
//struct SignupView: View {
//    @State private var username: String = ""
//    @State private var password: String = ""
//    @State private var isSignedUp = false
//
//    var body: some View {
//        VStack(spacing: 20) {
//            Text("Sign Up")
//                .font(.largeTitle)
//                .bold()
//            
//            TextField("Username", text: $username)
//                .padding()
//                .background(Color.gray.opacity(0.2))
//                .cornerRadius(5)
//            
//            SecureField("Password", text: $password)
//                .padding()
//                .background(Color.gray.opacity(0.2))
//                .cornerRadius(5)
//            
//            Button(action: {
//
//                isSignedUp = true
//            }) {
//                Text("Submit")
//                    .foregroundColor(.white)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.green)
//                    .cornerRadius(5)
//            }
//            
//            NavigationLink(destination: HomeView(), isActive: $isSignedUp) {
//                EmptyView()
//            }
//        }
//        .padding()
//        .navigationBarTitle("Sign Up", displayMode: .inline)
//    }
//}
//
//struct SignupView_Previews: PreviewProvider {
//    static var previews: some View {
//        SignupView()
//    }
//}











import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var password = ""
    @State private var confirm  = ""
    @State private var showAlert = false
    @State private var alertMsg  = ""
    
    private let repo = CricketDataRepository.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sign Up")
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
            
            SecureField("Confirm Password", text: $confirm)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
            
            Button(action: submit) {
                Text("Submit")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(5)
            }
        }
        .padding()
        .navigationBarTitle("Sign Up", displayMode: .inline)
        .alert("Sign-up error",
               isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMsg)
        }
    }
    
    private func submit() {
        let user = username.trimmingCharacters(in: .whitespaces)
        guard !user.isEmpty, !password.isEmpty else {
            alertMsg = "Username and password are required."
            showAlert = true
            return
        }
        guard password == confirm else {
            alertMsg = "Passwords do not match."
            showAlert = true
            return
        }
        guard repo.fetchUser(username: user) == nil else {
            alertMsg = "Username already exists."
            showAlert = true
            return
        }
        _ = repo.createUser(username: user, password: password)
        dismiss()           // takes the user straight back to LoginView
    }
}
