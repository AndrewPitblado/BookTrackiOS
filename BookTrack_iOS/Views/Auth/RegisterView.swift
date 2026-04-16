//
//  RegisterView.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var passwordsMatch: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }

    private var formValid: Bool {
        !username.isEmpty && !email.isEmpty && !password.isEmpty && passwordsMatch
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Header
            VStack(spacing: 8) {
                Text("Create Account")
                    .font(.largeTitle.bold())
                Text("Start tracking your books")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Form fields
            VStack(spacing: 16) {
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.fill.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.fill.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(.fill.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding()
                    .background(.fill.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text("Passwords do not match")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
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

            // Register button
            Button {
                Task { await session.register(username: username, email: email, password: password) }
            } label: {
                if session.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign Up")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!formValid || session.isLoading)
            .padding(.horizontal)

            Spacer()

            // Back to login
            Button {
                session.clearError()
                dismiss()
            } label: {
                Text("Already have an account? **Log In**")
                    .font(.subheadline)
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    NavigationStack {
        RegisterView()
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
}
