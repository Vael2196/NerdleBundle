//
//  RegisterView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Sign-up screen for new users.
/// Creates both a Firebase Auth user and a `/users` document.
struct RegisterView: View {
    @EnvironmentObject private var app: AppState
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var error: String?
    @State private var loading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Welcome to our community!")
                    .font(.system(.largeTitle, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundStyle(.nbTextPrimary)

                VStack(spacing: 12) {
                    NBInputField(placeholder: "Username",
                                 text: $username,
                                 secure: false,
                                 keyboard: .default,
                                 contentType: .username)

                    NBInputField(placeholder: "Email",
                                 text: $email,
                                 secure: false,
                                 keyboard: .emailAddress,
                                 contentType: .emailAddress)

                    NBInputField(placeholder: "Password",
                                 text: $password,
                                 secure: true,
                                 contentType: .newPassword)

                    NBInputField(placeholder: "Confirm Password",
                                 text: $confirm,
                                 secure: true,
                                 contentType: .newPassword)
                }
                .padding(.horizontal)

                if let error { Text(error).foregroundStyle(.red).padding(.top, 4) }

                Button {
                    // Ultra-basic validation: required fields + matching passwords.
                    guard !username.isEmpty, !email.isEmpty, !password.isEmpty, password == confirm else {
                        error = "Please fill all fields and match passwords."; return
                    }
                    loading = true; error = nil
                    Task {
                        do {
                            try await AuthService.shared.signUp(email: email, password: password, username: username)
                            await loadProfileIntoAppState()
                        } catch {
                            self.error = error.localizedDescription
                        }
                        loading = false
                    }
                } label: {
                    HStack {
                        if loading { ProgressView().tint(.nbCrimson) }
                        Text("CREATE ACCOUNT")
                            .font(.system(size: 20, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .background(Color.nbHeader)
                .clipShape(RoundedRectangle(cornerRadius: 72))
                .overlay(
                    RoundedRectangle(cornerRadius: 72)
                        .stroke(Color.nbCrimson.opacity(0.4), lineWidth: 0.8)
                )
                .foregroundStyle(Color.nbTextPrimary)
                .padding(.horizontal)
                .disabled(loading)

                HStack(spacing: 6) {
                    Text("Already have an account?")
                        .foregroundStyle(Color.nbTextSecondary)
                    NavigationLink {
                        LoginView()
                    } label: {
                        Text("Log in")
                            .underline()
                            .foregroundStyle(Color.nbCrimson)
                    }
                }
                .padding(.top, 8)
                
                Spacer(minLength: 40)
            }
        }
        .background(Color.nbBackground.ignoresSafeArea())
    }
}

private extension RegisterView {
    /// After successful sign-up, this pulls the freshly created user doc and sets `app.user`.
    func loadProfileIntoAppState() async {
        guard let uid = AuthService.shared.currentUID() else { return }
        do {
            let doc = try await FirebaseManager.shared.db.collection("users").document(uid).getDocument()
            guard let data = doc.data() else { return }
            let username = (data["username"] as? String) ?? "Player"
            let email = (data["email"] as? String) ?? ""
            let avatarPath = data["avatarPath"] as? String
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

            let nbUser = NBUser(id: uid, email: email, username: username, avatarPath: avatarPath, createdAt: createdAt)
            await MainActor.run { app.user = nbUser }
        } catch {
            // If this fails, the Firebase user still exists, just no profile cached locally yet.
        }
    }
}
