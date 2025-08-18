//
//  ColorPalatte.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/18/25.
//

import Foundation
import SwiftUI

struct ColorPalatte: Hashable {
    let name: String
    let pop: Color
    let grow: Color
    let background: Color
    let text: Text
    let gradient: Gradient
    let card: Card
    let button: Button
    
    init(name: String,
         pop: Color,
         grow: Color,
         background: Color,
         text: Text,
         gradient: Gradient,
         card: Card,
         button: Button
    ) {
        self.name = name
        self.pop = pop
        self.grow = grow
        self.background = background
        self.text = text
        self.gradient = gradient
        self.card = card
        self.button = button
    }
}

extension ColorPalatte {
    struct Text: Hashable {
        let body: Color
    }
    
    struct Gradient: Hashable {
        let start: Color
        let start2: Color
        let end: Color
    }
    
    struct Card: Hashable {
        let background: Color
    }
    
    struct Button: Hashable {
        let background: Color
    }
}

extension ColorPalatte {
    static let `default` = ColorPalatte(
        name: "Default",
        pop: .pop,
        grow: .growAccent,
        background: .background,
        text: Text(body: .mainBodyText),
        gradient: Gradient(start: .primaryGradient, start2: .secondaryGradient, end: .background),
        card: Card(background: .backgroundCard),
        button: Button(background: .accentButton)
    )
    
}
