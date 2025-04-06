//
//  LoginSignupView.swift
//  Squallywood
//
//  Created by Gareth Hill on 4/6/25.
//

import SwiftUI
import Supabase
import Foundation

struct LoginSignupView: View {
    @Binding var isLoggedIn: Bool  // Bind to isLoggedIn state from the main app
    @State private var username: String = ""
    @State private var isLoggingIn: Bool = false
    @State private var loginAttemptCount: Int = 0
    @State private var errorMessage: String?

    let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://yayivyfaenfjkxeibddl.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlheWl2eWZhZW5mamt4ZWliZGRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM4NzIzNzIsImV4cCI6MjA1OTQ0ODM3Mn0.41_ftRNoFJvLKKcYc-BRIhAngryVmxxy3WWJT6PY-_Q"
    )

    var body: some View {
            VStack {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Button("Log In / Sign Up") {
                    loginOrSignUp()
                }
                .padding()
                .disabled(isLoggingIn)

                if isLoggingIn {
                    ProgressView("Logging in...")
                }
            }
            .padding()
        }

        func loginOrSignUp() {
            if username.isEmpty {
                errorMessage = "Username cannot be empty"
                return
            }

            isLoggingIn = true
            loginAttemptCount += 1

            Task {
                await attemptLoginOrSignup()
            }
        }

        func attemptLoginOrSignup() async {
            let maxRetries = 3

            do {
                let response = try await supabase.auth.signIn(email: username, password: "password")
                handleLoginSuccess(response.user)
            } catch {
                if loginAttemptCount < maxRetries {
                    do {
                        let response = try await supabase.auth.signUp(email: username, password: "password")
                        handleLoginSuccess(response.user)
                    } catch {
                        handleLoginError(error)
                    }
                } else {
                    handleLoginError(error)
                }
            }
        }

        func handleLoginSuccess(_ user: User) {
            isLoggingIn = false
            errorMessage = nil
            isLoggedIn = true // Set login state to true
        }

        func handleLoginError(_ error: Error) {
            isLoggingIn = false
            errorMessage = "Failed to login or sign up. Please try again."
            print("Error logging in or signing up: \(error)")
        }
    }
