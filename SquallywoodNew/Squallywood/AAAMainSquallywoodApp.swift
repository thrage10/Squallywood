//
//  SquallywoodApp.swift
//  Squallywood
//
//  Created by Gareth Hill on 4/5/25.
//

import SwiftUI

@main
struct SquallywoodApp: App {
    @State private var userIsLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            if !userIsLoggedIn {
                LoginSignupView(userIsLoggedIn: $userIsLoggedIn)
            } else {
                MapView(userIsLoggedIn: $userIsLoggedIn)
            }
        }
    }
}
