//
//  LoginView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var app: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Welcome Back!")
                    .font(.system(.largeTitle, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundStyle(.nbTextPrimary)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding()
                .background(Color.nbCard)
                .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                .padding(.horizontal)

                if let error { Text(error).foregroundStyle(.red) }

                Button {
                    if email.isEmpty || password.isEmpty || !email.contains("@") {
                        error = "Please enter a valid email and password."
                        return
                    }
                    // TODO: replace with Firebase later
                    app.user = .init(id: UUID().uuidString, username: email.split(separator: "@").first.map(String.init) ?? "User", email: email, avatarURL: nil)
                } label: {
                    Text("Log in")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundStyle(Color.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.nbCrimson, lineWidth: 1))
                        .padding(.horizontal)
                }

                Button("Sign up now") { showRegister = true }
                    .foregroundStyle(.white)
                    .padding(.top, 4)

                Spacer()
            }
            .background(Color.nbBackground)
            .navigationDestination(isPresented: $showRegister) { RegisterView() }
        }
    }
}
