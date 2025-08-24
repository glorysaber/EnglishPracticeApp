//
//  ColorPaletteManager.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/23/25.
//

import SwiftUI

// Class to manage and choose palettes
@Observable
final class ColorPaletteManager {
    var currentPalette: ColorPalette<Color>
    
    private let lightPalette: ColorPalette<Color>
    private let darkPalette: ColorPalette<Color>
    
    init(light: ColorPalette<Color>, dark: ColorPalette<Color>) {
        self.lightPalette = light
        self.darkPalette = dark
        self.currentPalette = light  // Default to light
    }
    
    init(resource: URL, defaultPalette: ColorPalette<Color>? = nil, onError: (any Error) -> Void = { _ in }) {
        do {
            let data = try Data(contentsOf: resource)
            let decoder = JSONDecoder()
            let palettes: [String: ColorPalette<RGBAColor>] = try decoder.decode([String: ColorPalette<RGBAColor>].self, from: data)
            
            if let lightPalette = palettes["light"] {
                let lightPalette: ColorPalette<Color> = ColorPalette(lightPalette)
                self.lightPalette = lightPalette
                self.currentPalette = lightPalette
            } else {
                onError(GeneralError(userDescritpion: "Failed to load Color Scheme light, falling back to standard"))
                self.lightPalette = defaultPalette ?? .unknown
                self.currentPalette = defaultPalette ?? .unknown
            }
            
            if let darkPalette = palettes["dark"] {
                self.darkPalette = ColorPalette(darkPalette)
            } else {
                onError(GeneralError(userDescritpion: "Failed to load Color Scheme dark, falling back to standard"))
                self.darkPalette = defaultPalette ?? .unknown
            }
        } catch {
            onError(GeneralError(userDescritpion: "Failed to load Color Schemes, falling back to standard"))
            self.lightPalette = defaultPalette ?? .unknown
            self.darkPalette = defaultPalette ?? .unknown
            self.currentPalette = defaultPalette ?? .unknown
        }
    }
    
    static func _debugManager(file: StaticString = #filePath, line: UInt = #line) -> ColorPaletteManager {
        #if !DEBUG
        Logger.englishPractice.log("Loading debug shared instance for ColorPaletteManager!!!!! \(file):\(line)")
        #endif
        ColorPaletteManager(resource: Bundle.main.url(forResource: "Colors", withExtension: "json")!) { error in
            assertionFailure("Failed to load assets with Error: \(error)")
        }
    }
        
    
    func update(for scheme: ColorScheme) {
        currentPalette = (scheme == .dark) ? darkPalette : lightPalette
    }
}

// View modifier to inject the managed Palette
struct AdaptiveColorPaletteModifier: ViewModifier {
    @State var manager: ColorPaletteManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.self) var environment
    
    func body(content: Content) -> some View {
        content
            .environment(\.colorPalette, manager.currentPalette)
            .onChange(of: colorScheme) { oldScheme, newScheme in
                manager.update(for: newScheme)
            }
    }
}

extension View {
    func adaptiveColorPalette(manager: ColorPaletteManager) -> some View {
        modifier(AdaptiveColorPaletteModifier(manager: manager))
    }
}
