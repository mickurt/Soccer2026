import Foundation

struct WidgetMatchData: Codable, Equatable {
    let id: String
    let date: Date
    let stage: String
    let homeTeamName: String
    let homeTeamEmoji: String
    let awayTeamName: String
    let awayTeamEmoji: String
    let homeScore: String
    let awayScore: String
    let status: String // "Scheduled", "Live", "Finished"
    let venue: String
}

struct WidgetData: Codable, Equatable {
    let matchOfTheDay: WidgetMatchData?
    let myTeamNextMatch: WidgetMatchData?
    let myTeamLastResult: WidgetMatchData?
    let favoriteTeamCode: String?
    
    // Localized labels passed from the main app
    let labelMatchOfTheDay: String
    let labelMyTeam: String
    let labelLive: String
    let labelFinished: String
    let labelNoMatchToday: String
    let labelNoFavoriteTeam: String
    let labelNextMatch: String
    let labelLastResult: String
    let labelNoRecentMatch: String
    let labelNoUpcomingMatch: String
    let labelNoRecentResult: String
    let labelNotDefined: String
    let labelNoMatch: String
}

#if canImport(ActivityKit)
import ActivityKit

struct LiveScoreAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var homeScore: Int
        var awayScore: Int
        var status: String // e.g. "12'", "HT", "Scheduled"
        var matchStatusRawValue: String
        var liveLabel: String
    }

    var matchId: String
    var homeTeamName: String
    var homeTeamEmoji: String
    var awayTeamName: String
    var awayTeamEmoji: String
    var stage: String
}
#endif

