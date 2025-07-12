//
//  Font+Extensions.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI

extension Font {
    static func clashGrotesk(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.custom("Clash Grotesk Variable", size: size)
    }
    
    static func clashGroteskFixed(size: CGFloat) -> Font {
        return Font.custom("Clash Grotesk Variable", fixedSize: size)
    }
}