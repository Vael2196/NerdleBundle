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
                    TextField("Username", text: $username).padding().background(.white).clipShape(RoundedRectangle(cornerRadius: 10))
                    TextField("Email", text: $email).textContentType(.emailAddress).keyboardType(.emailAddress).padding().background(.white).clipShape(RoundedRectangle(cornerRadius: 10))
                    SecureField("Password", text: $password).padding().background(.white).clipShape(RoundedRectangle(cornerRadius: 10))
                    SecureField("Confirm Password", text: $confirm).padding().background(.white).clipShape(RoundedRectangle(cornerRadius: 10))
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
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 36))
                        .overlay(RoundedRectangle(cornerRadius: 36).stroke(Color.pink, lineWidth: 1))
                        .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color.nbBackground.ignoresSafeArea())
    }
}
