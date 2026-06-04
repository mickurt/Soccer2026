
import Foundation
import SwiftData

@Model
final class Match: Identifiable {
    @Attribute(.unique) var id: String
    var date: Date
    var group: String?
    var stage: String
    var homeTeam: Team?
    var awayTeam: Team?
    var venue: Venue?
    var homeScore: Int?
    var awayScore: Int?
    var statusRaw: String // Stored as raw string for query ease
    
    var status: MatchStatus {
        get { MatchStatus(rawValue: statusRaw) ?? .scheduled }
        set { statusRaw = newValue.rawValue }
    }
    
    init(id: String = UUID().uuidString, date: Date, group: String? = nil, stage: String, homeTeam: Team?, awayTeam: Team?, venue: Venue?, homeScore: Int? = nil, awayScore: Int? = nil, status: MatchStatus = .scheduled) {
        self.id = id
        self.date = date
        self.group = group
        self.stage = stage
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.venue = venue
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.statusRaw = status.rawValue
    }
}

enum MatchStatus: String, CaseIterable, Codable {
    case scheduled = "Scheduled"
    case live = "Live"
    case finished = "Finished"
    
    var statusColor: String {
        switch self {
        case .scheduled: return "gray"
        case .live: return "red"
        case .finished: return "green"
        }
    }
}
