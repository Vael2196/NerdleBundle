//
//  SteamdleView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

struct SteamdleView: View {
    @State private var guesses: [String] = Array(repeating: "", count: 5)

    var body: some View {
        VStack(spacing: 12) {
            Text("Steamdle")
                .font(.title).bold()
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.nbHeader)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal)

            RoundedRectangle(cornerRadius: 7)
                .fill(Color.nbMutedRed)
                .frame(height: 220)
                .overlay(Text("Game cover/screenshots here").foregroundStyle(.nbTextSecondary))

            VStack(spacing: 10) {
                ForEach(0..<guesses.count, id: \.self) { i in
                    TextField("...\(i+1) ($AUD)", text: $guesses[i])
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal)

            Spacer()

            Button("Next") { /* move to next screen/instance. Gotta attach the APIs first */ }
                .buttonStyle(.bordered)
                .tint(.pink)
        }
        .background(Color.nbBackground.ignoresSafeArea())
    }
}
