import Foundation

nonisolated enum NewsItemType: String, Codable, Sendable, Hashable {
    case newspaper, injury, transfer, board, pressConference, matchResult
    
    var icon: String {
        switch self {
        case .newspaper: "newspaper"
        case .injury: "cross.case.fill"
        case .transfer: "arrow.left.arrow.right"
        case .board: "building.2.fill"
        case .pressConference: "mic.fill"
        case .matchResult: "sportscourt.fill"
        }
    }
}

struct NewsArticle: Identifiable, Codable, Sendable, Hashable {
    let id: String
    let headline: String
    let subheadline: String?
    let body: String
    let date: String
    let source: String
    let type: NewsItemType
    var isRead: Bool
    let week: Int
}
