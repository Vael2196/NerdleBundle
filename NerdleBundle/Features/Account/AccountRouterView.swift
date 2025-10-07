//
//  AccountRouterView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

struct AccountRouterView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        Group {
            if let _ = app.user {
                AccountSummaryView()
            } else {
                LoginView()
            }
        }
        .background(Color.nbBackground.ignoresSafeArea())
    }
}
