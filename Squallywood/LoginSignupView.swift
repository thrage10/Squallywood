//
//  LoginSignupView.swift
//  Squallywood
//
//  Created by Gareth Hill on 4/6/25.
//

import SwiftUI
import Supabase
import Foundation

// Enum to manage the current authentication state/mode
enum AuthMode {
    case undecided
    case login
    case signUp
}

struct LoginSignupView: View {
    @Binding var userIsLoggedIn: Bool
    @State private var userEmailAddress: String = ""
    @State private var authenticationInProgress: Bool = false
    @State private var authenticationErrorMessage: String? = nil
    @State private var authMode: AuthMode = .undecided // Start in undecided mode

    let supabaseConnection = SupabaseClient(
        supabaseURL: URL(string: "https://yayivyfaenfjkxeibddl.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlheWl2eWZhZW5mamt4ZWliZGRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM4NzIzNzIsImV4cCI6MjA1OTQ0ODM3Mn0.41_ftRNoFJvLKKcYc-BRIhAngryVmxxy3WWJT6PY-_Q"
    )

    var body: some View {
        NavigationView { // Keep NavigationView for title and potential back button
            VStack {
                // Conditional UI based on authMode
                switch authMode {
                case .undecided:
                    initialChoiceView
                case .login:
                    authenticationView(isSigningUp: false)
                case .signUp:
                    authenticationView(isSigningUp: true)
                }

                Spacer() // Push content to the top
            }
            .padding()
            .navigationTitle(navigationTitle) // Dynamic title
            .navigationBarItems(leading: backButton) // Show back button conditionally
            .animation(.default, value: authMode) // Animate transitions
        }
    }

    // View for the initial choice (Log In / Sign Up)
    var initialChoiceView: some View {
        VStack(spacing: 20) {
            Text("Welcome to Squallywood!")
                 .font(.title2)
                 .padding(.bottom)
                 
            Button("Log In") {
                authMode = .login
                resetState()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large) // Make buttons larger

            Button("Sign Up") {
                authMode = .signUp
                resetState()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    // View for email input and action button (Log In or Sign Up)
    func authenticationView(isSigningUp: Bool) -> some View {
        VStack {
            TextField("Email", text: $userEmailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)

            if let authenticationErrorMessage = authenticationErrorMessage {
                Text(authenticationErrorMessage)
                    .foregroundColor(.red)
                    .padding(.bottom, 5)
            }

            Button(isSigningUp ? "Sign Up" : "Log In") {
                performAuthentication(isSigningUp: isSigningUp)
            }
            .buttonStyle(.borderedProminent)
            .disabled(authenticationInProgress || userEmailAddress.isEmpty || !isValidEmail(userEmailAddress))
            .padding(.bottom)

            if authenticationInProgress {
                ProgressView(isSigningUp ? "Signing Up..." : "Logging In...")
            }
        }
    }
    
    // Dynamic Navigation Title
    var navigationTitle: String {
        switch authMode {
        case .undecided:
            return "Welcome"
        case .login:
            return "Log In"
        case .signUp:
            return "Sign Up"
        }
    }
    
    // Conditional Back Button
    @ViewBuilder
    var backButton: some View {
        if authMode != .undecided {
            Button(action: {
                authMode = .undecided
                resetState()
            }) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        } else {
            EmptyView() // No back button on the initial screen
        }
    }
    
    // Reset state when switching modes or going back
    func resetState() {
        userEmailAddress = ""
        authenticationErrorMessage = nil
        authenticationInProgress = false
    }


    // --- Authentication Logic (mostly unchanged) ---

    func performAuthentication(isSigningUp: Bool) {
        guard !userEmailAddress.isEmpty else {
            authenticationErrorMessage = "Email cannot be empty"
            return
        }
        
        guard isValidEmail(userEmailAddress) else {
             authenticationErrorMessage = "Please enter a valid email address"
             return
        }

        authenticationInProgress = true
        authenticationErrorMessage = nil 

        Task {
            await attemptAuthentication(isSigningUp: isSigningUp)
        }
    }

    func attemptAuthentication(isSigningUp: Bool) async {
        let maxRetries = 3
        var currentRetry = 0
        
        while currentRetry < maxRetries {
            do {
                if isSigningUp {
                    let response = try await supabaseConnection.auth.signUp(email: userEmailAddress, password: "password")
                    handleAuthSuccess(response.user)
                    return
                } else {
                    let response = try await supabaseConnection.auth.signIn(email: userEmailAddress, password: "password")
                    handleAuthSuccess(response.user)
                    return
                }
            } catch {
                currentRetry += 1
                if currentRetry == maxRetries {
                    handleAuthError(error, action: isSigningUp ? "sign up" : "log in")
                    return
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay between retries
            }
        }
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    @MainActor 
    func handleAuthSuccess(_ user: User) {
        authenticationInProgress = false
        authenticationErrorMessage = nil
        userIsLoggedIn = true 
    }

    @MainActor 
    func handleAuthError(_ error: Error, action: String) {
        authenticationInProgress = false
        // Simplified error message for common cases
        if let authError = error as? AuthError, authError.message == "User already registered" {
             authenticationErrorMessage = "This email is already registered. Please try logging in."
        } else if let authError = error as? AuthError, authError.message == "Invalid login credentials" {
             authenticationErrorMessage = "Incorrect email or password. Please try again." // Assuming password issues might occur later
        } else {
             authenticationErrorMessage = "Failed to \(action). Please try again." // More generic
        }
        print("Error details: \(error)")
    }
}
