//
//  LoginView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Simple sign-in screen for existing users.
/// On success, the `/users` doc is pulled and stored in `AppState`.
struct LoginView: View {
    @EnvironmentObject private var app: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var error: String?
    @State private var loading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Welcome Back!")
                    .font(.system(.largeTitle, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundStyle(.nbTextPrimary)

                VStack(spacing: 12) {
                    NBInputField(placeholder: "Email",
                                 text: $email,
                                 secure: false,
                                 keyboard: .emailAddress,
                                 contentType: .emailAddress)

                    NBInputField(placeholder: "Password",
                                 text: $password,
                                 secure: true,
                                 keyboard: .default,
                                 contentType: .password)
                }
                .padding()
                .background(Color.nbCard)
                .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                .padding(.horizontal)
                .task {
                    // If a session already exists, quietly hydrate the profile.
                    await checkExistingSession()
                }

                if let error { Text(error).foregroundStyle(.red).padding(.top, 4) }

                Button {
                    // Quick client-side sanity check before hitting Firebase.
                    if email.isEmpty || password.isEmpty || !email.contains("@") {
                        error = "Please enter a valid email and password."
                        return
                    }
                    loading = true; error = nil
                    Task {
                        do {
                            try await AuthService.shared.signIn(email: email, password: password)
                            await loadProfileIntoAppState()
                        } catch {
                            self.error = error.localizedDescription
                        }
                        loading = false
                    }
                } label: {
                    HStack {
                        if loading { ProgressView().tint(.nbCrimson) }
                        Text("Log in")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundStyle(Color.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.nbCrimson, lineWidth: 1))
                    .padding(.horizontal)
                }
                .disabled(loading)

                NavigationLink {
                    RegisterView()
                } label: {
                    Text("Sign up now")
                        .font(.system(size: 20, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(Color.nbHeader)
                .clipShape(RoundedRectangle(cornerRadius: 68))
                .overlay(
                    RoundedRectangle(cornerRadius: 68)
                        .stroke(Color.nbCrimson.opacity(0.4), lineWidth: 0.8)
                )
                .foregroundStyle(Color.nbTextPrimary)
                .padding(.horizontal)

                Spacer()
            }
            .background(Color.nbBackground)
            .navigationDestination(isPresented: $showRegister) { RegisterView() }
        }
    }
}

private extension LoginView {
    /// If there is already a user signed in, this quietly loads the profile into `AppState`.
    func checkExistingSession() async {
            guard let uid = AuthService.shared.currentUID() else { return }
            await loadProfileIntoAppState()
        }
    
    /// Reads `/users/{uid}` and stuffs it into `app.user`.
    /// This is basically the same dance as in `RegisterView` and `AccountRouterView`.
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
            // Silent fail here; login still works but profile won't hydrate.
        }
    }
}
