//
//  ColorPalette.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/18/25.
//

import Foundation
import SwiftUI

struct ColorPalette<ColorT: Hashable>: Hashable {
    let name: String
    let pop: ColorT
    let grow: ColorT
    let background: ColorT
    let text: Text
    let gradient: Gradient
    let card: Card
    let button: Button
    
    init(name: String,
         pop: ColorT,
         grow: ColorT,
         background: ColorT,
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

extension ColorPalette {
    struct Text: Hashable {
        let body: ColorT
        let overlay: ColorT
    }
    
    struct Gradient: Hashable {
        let start: ColorT
        let start2: ColorT
        let end: ColorT
    }
    
    struct Card: Hashable {
        let background: ColorT
    }
    
    struct Button: Hashable {
        let background: ColorT
    }
}

extension ColorPalette: Codable where ColorT: Codable {}
extension ColorPalette.Button: Codable where ColorT: Codable {}
extension ColorPalette.Text: Codable where ColorT: Codable {}
extension ColorPalette.Gradient: Codable where ColorT: Codable {}
extension ColorPalette.Card: Codable where ColorT: Codable {}

extension ColorPalette where ColorT == Color {
    static var unknown: Self {
        ColorPalette<Color>(
            name: "unknown",
            pop: .white,
            grow: .white,
            background: .white,
            text: Text(body: .black, overlay: .black),
            gradient: Gradient(start: .white, start2: .white, end: .white),
            card: Card(background: .white),
            button: Button(background: .white)
        )
    }
    
    init(_ colorPalette: ColorPalette<RGBAColor>) {
            self.name = colorPalette.name
            self.pop = Color(colorPalette.pop)
            self.grow = Color(colorPalette.grow)
            self.background = Color(colorPalette.background)
            self.text = Text(body: Color(colorPalette.text.body), overlay: Color(colorPalette.text.overlay))
            self.gradient = Gradient(start: Color(colorPalette.gradient.start), start2: Color(colorPalette.gradient.start2), end: Color(colorPalette.gradient.end))
            self.card = Card(background: Color(colorPalette.card.background))
            self.button = Button(background: Color(colorPalette.button.background))
        }
}

struct RGBAColor: Codable, Hashable, CustomStringConvertible, ExpressibleByStringLiteral {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        // get a stored RGBA string
        let hexString = try container.decode(String.self)
        self = RGBAColor(hexString: hexString)
    }
    
    init<T: StringProtocol>(hexString: T) {
        self.red = UInt8(hexString[hexString.startIndex..<hexString.index(hexString.startIndex, offsetBy: 2)], radix: 16)!
        self.green = UInt8(hexString[hexString.index(hexString.startIndex, offsetBy: 2)..<hexString.index(hexString.startIndex, offsetBy: 4)], radix: 16)!
        self.blue = UInt8(hexString[hexString.index(hexString.startIndex, offsetBy: 4)..<hexString.index(hexString.startIndex, offsetBy: 6)], radix: 16)!
        self.alpha = UInt8(hexString[hexString.index(hexString.startIndex, offsetBy: 6)..<hexString.endIndex], radix: 16)!
    }
    
    init(stringLiteral hexString: StringLiteralType) {
        self.init(hexString: hexString)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        let hexString = description
        try container.encode(hexString)
    }

    var description: String { String(format: "%02x%02x%02x%02x", red, green, blue, alpha) }
}

extension Color {
    init(_ rgbaColor: RGBAColor) {
        let red = Double(rgbaColor.red) / 255.0
        let green = Double(rgbaColor.green) / 255.0
        let blue = Double(rgbaColor.blue) / 255.0
        let alpha = Double(rgbaColor.alpha) / 255.0
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension RGBAColor {
    init(_ color: Color, in environment: EnvironmentValues) {
        let resolved = color.resolve(in: environment)
        self.red = UInt8((Double(resolved.red) * 255).rounded())
        self.green = UInt8((Double(resolved.green) * 255).rounded())
        self.blue = UInt8((Double(resolved.blue) * 255).rounded())
        self.alpha = UInt8((Double(resolved.opacity) * 255).rounded())
    }
}

extension ColorPalette where ColorT == RGBAColor {
    init(_ palette: ColorPalette<Color>, in environment: EnvironmentValues) {
        self.name = palette.name
        self.pop = RGBAColor(palette.pop, in: environment)
        self.grow = RGBAColor(palette.grow, in: environment)
        self.background = RGBAColor(palette.background, in: environment)
        self.text = Text(body: RGBAColor(palette.text.body, in: environment), overlay: RGBAColor(palette.text.overlay, in: environment))
        self.gradient = Gradient(start: RGBAColor(palette.gradient.start, in: environment), start2: RGBAColor(palette.gradient.start2, in: environment), end: RGBAColor(palette.gradient.end, in: environment))
        self.card = Card(background: RGBAColor(palette.card.background, in: environment))
        self.button = Button(background: RGBAColor(palette.button.background, in: environment))
    }
}
