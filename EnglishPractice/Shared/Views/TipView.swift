//
//  TipView.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/15/25.
//

import SwiftUI

struct TipView: View {
    var body: some View {
        VStack {
            Text("Give your Husband a Tip!")
            List {
                Text("Hug")
                Text("Kiss")
                Text("Something Special...")
            }
        }
    }
}

#Preview {
    TipView()
}
