//
//  RegisterView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var app: AppState
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var error: String?

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

                if let error { Text(error).foregroundStyle(.red) }

                Button {
                    guard !username.isEmpty, email.contains("@"), password.count >= 6, password == confirm else {
                        error = "Check username/email and matching passwords (6+ chars)."
                        return
                    }
                    // TODO: replace with Firebase, just like Log in
                    app.user = .init(id: UUID().uuidString, username: username, email: email, avatarURL: nil)
                } label: {
                    Text("CREATE ACCOUNT")
                        .font(.system(size: 20, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(Color.nbHeader) // darker on light mode, cohesive on dark
                .clipShape(RoundedRectangle(cornerRadius: 72))
                .overlay(
                    RoundedRectangle(cornerRadius: 72)
                        .stroke(Color.nbCrimson.opacity(0.4), lineWidth: 0.8)
                )
                .foregroundStyle(Color.nbTextPrimary)
                .padding(.horizontal)

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
