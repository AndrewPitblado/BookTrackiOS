//
//  LoginView.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: SessionStore

    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Header
                VStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor)
                    Text("BookTrack")
                        .font(.largeTitle.bold())
                    Text("Track your reading journey")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Form fields
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(.fill.tertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(.fill.tertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)

                // Error message
                if let error = session.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Login button
                Button {
                    Task { await session.login(email: email, password: password) }
                } label: {
                    if session.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Log In")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || password.isEmpty || session.isLoading)
                .padding(.horizontal)

                Spacer()

                // Register link
                Button {
                    session.clearError()
                    showRegister = true
                } label: {
                    Text("Don't have an account? **Sign Up**")
                        .font(.subheadline)
                }
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(
            SessionStore(
                authService: AuthService(
                    client: NetworkClient(
                        baseURL: URL(string: "http://localhost:5001/api")!,
                        tokenStore: KeychainTokenStore(service: "preview")
                    ),
                    tokenStore: KeychainTokenStore(service: "preview")
                ),
                tokenStore: KeychainTokenStore(service: "preview")
            )
        )
}
