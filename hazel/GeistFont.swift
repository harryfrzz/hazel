import SwiftUI

extension Font {
    static let geistPixel = Font.custom("GeistPixel-Square", size: 12)
    
    static func geist(_ size: CGFloat) -> Font {
        Font.custom("GeistPixel-Square", size: size)
    }
}

extension Text {
    func geistFont(_ size: CGFloat) -> Text {
        self.font(Font.custom("GeistPixel-Square", size: size))
    }
}
