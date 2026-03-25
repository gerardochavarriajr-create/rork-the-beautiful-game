import SwiftUI

enum AppTheme {
    static let background = Color(hex: "0A0E14")
    static let surface = Color(hex: "151B23")
    static let surfaceElevated = Color(hex: "1C2430")
    static let pitchGreen = Color(hex: "4CAF50")
    static let golden = Color(hex: "FFC107")
    static let textPrimary = Color(hex: "F0F0F0")
    static let textSecondary = Color(hex: "8B95A5")
    static let danger = Color(hex: "EF4444")
    static let warning = Color(hex: "F59E0B")

    static func ratingColor(_ rating: Int) -> Color {
        switch rating {
        case 85...99: Color(hex: "EAB308")
        case 75...84: Color(hex: "3B82F6")
        case 60...74: Color(hex: "4CAF50")
        case 40...59: Color(hex: "F59E0B")
        default: Color(hex: "EF4444")
        }
    }

    static func matchRatingColor(_ rating: Double) -> Color {
        switch rating {
        case 9.0...10.0: Color(hex: "EAB308")
        case 7.5..<9.0: Color(hex: "3B82F6")
        case 6.5..<7.5: Color(hex: "4CAF50")
        case 5.0..<6.5: Color(hex: "F59E0B")
        default: Color(hex: "EF4444")
        }
    }

    static func positionColor(_ category: PositionCategory) -> Color {
        Color(hex: category.color)
    }

    static func formResultColor(_ result: String) -> Color {
        switch result {
        case "W": .green
        case "D": .gray
        case "L": .red
        default: .gray
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
