import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: .mock)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), data: loadWidgetData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = SimpleEntry(date: Date(), data: loadWidgetData())
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadWidgetData() -> WidgetData {
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.mm.WorldCup2026") {
            let fileURL = containerURL.appendingPathComponent("widget_data.json")
            if let data = try? Data(contentsOf: fileURL) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let decoded = try? decoder.decode(WidgetData.self, from: data) {
                    return decoded
                }
            }
        }
        return .mock
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// Extension to provide robust, visually premium mock data
extension WidgetData {
    static var mock: WidgetData {
        WidgetData(
            matchOfTheDay: WidgetMatchData(
                id: "1",
                date: Date(),
                stage: "Phase de Groupes",
                homeTeamName: "France",
                homeTeamEmoji: "🇫🇷",
                awayTeamName: "Sénégal",
                awayTeamEmoji: "🇸🇳",
                homeScore: "2",
                awayScore: "1",
                status: "Live",
                venue: "Estadio Azteca"
            ),
            myTeamNextMatch: WidgetMatchData(
                id: "2",
                date: Date().addingTimeInterval(86400 * 2), // 2 days from now
                stage: "Phase de Groupes",
                homeTeamName: "Canada",
                homeTeamEmoji: "🇨🇦",
                awayTeamName: "France",
                awayTeamEmoji: "🇫🇷",
                homeScore: "-",
                awayScore: "-",
                status: "Scheduled",
                venue: "BC Place"
            ),
            myTeamLastResult: WidgetMatchData(
                id: "3",
                date: Date().addingTimeInterval(-86400 * 3), // 3 days ago
                stage: "Phase de Groupes",
                homeTeamName: "France",
                homeTeamEmoji: "🇫🇷",
                awayTeamName: "Irak",
                awayTeamEmoji: "🇮🇶",
                homeScore: "3",
                awayScore: "0",
                status: "Finished",
                venue: "MetLife Stadium"
            ),
            favoriteTeamCode: "FRA",
            labelMatchOfTheDay: "Match du Jour",
            labelMyTeam: "Mon Équipe",
            labelLive: "EN DIRECT",
            labelFinished: "TERMINÉ",
            labelNoMatchToday: "Aucun match planifié aujourd'hui.",
            labelNoFavoriteTeam: "Sélectionnez votre équipe dans l'app.",
            labelNextMatch: "PROCHAIN MATCH",
            labelLastResult: "DERNIER RÉSULTAT",
            labelNoRecentMatch: "Aucun match récent.",
            labelNoUpcomingMatch: "Aucun match planifié",
            labelNoRecentResult: "Aucun résultat récent",
            labelNotDefined: "NON DÉFINIE",
            labelNoMatch: "AUCUN MATCH"
        )
    }
}

// MARK: - Views

struct MatchOfTheDayEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header Row
            HStack {
                if let match = entry.data.matchOfTheDay {
                    if match.status == "Live" {
                        HStack(spacing: 4) {
                            Circle().fill(Color.red).frame(width: 6, height: 6)
                            Text(entry.data.labelLive.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Capsule())
                    } else if match.status == "Finished" {
                        Text(entry.data.labelFinished.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color(red: 0.8, green: 1.0, blue: 0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Capsule())
                    } else {
                        Text(entry.data.labelMatchOfTheDay.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                    }
                    
                    Spacer()
                    
                    Text(match.stage)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                } else {
                    Text(entry.data.labelNoMatch.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                }
            }
            
            Spacer(minLength: 0)
            
            if let match = entry.data.matchOfTheDay {
                if family == .systemSmall {
                    // Small layout: stacked score/teams
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text(match.homeTeamEmoji)
                                .font(.system(size: 18))
                            Text(match.homeTeamName)
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                                .foregroundStyle(.white)
                            Spacer()
                            Text(match.homeScore)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(match.status == "Live" ? .red : .white)
                        }
                        
                        HStack(spacing: 6) {
                            Text(match.awayTeamEmoji)
                                .font(.system(size: 18))
                            Text(match.awayTeamName)
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                                .foregroundStyle(.white)
                            Spacer()
                            Text(match.awayScore)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(match.status == "Live" ? .red : .white)
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Bottom kickoff details
                    if match.status == "Scheduled" {
                        Text(match.date, style: .time)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                    } else {
                        Text(match.venue)
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                } else {
                    // Medium layout: side-by-side card with more details
                    HStack(spacing: 12) {
                        VStack(alignment: .center, spacing: 6) {
                            Text(match.homeTeamEmoji)
                                .font(.system(size: 34))
                            Text(match.homeTeamName)
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(alignment: .center, spacing: 4) {
                            if match.status == "Scheduled" {
                                Text(match.date, style: .time)
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                                Text(match.date, style: .date)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white.opacity(0.6))
                            } else {
                                Text("\(match.homeScore) - \(match.awayScore)")
                                    .font(.system(size: 24, weight: .black))
                                    .foregroundStyle(match.status == "Live" ? .red : Color(red: 0.9, green: 0.8, blue: 0.5))
                                Text(match.status == "Live" ? entry.data.labelLive.uppercased() : entry.data.labelFinished.uppercased())
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(match.status == "Live" ? .red : .green)
                            }
                        }
                        .frame(width: 80)
                        
                        VStack(alignment: .center, spacing: 6) {
                            Text(match.awayTeamEmoji)
                                .font(.system(size: 34))
                            Text(match.awayTeamName)
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 4)
                    
                    Spacer(minLength: 0)
                    
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 8))
                            .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                        Text(match.venue)
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
            } else {
                Text(entry.data.labelNoMatchToday)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }
        }
    }
}

struct MyTeamEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Text(entry.data.labelMyTeam.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                
                Spacer()
                
                if let code = entry.data.favoriteTeamCode {
                    Text(code)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text(entry.data.labelNotDefined.uppercased())
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            
            Spacer(minLength: 0)
            
            if entry.data.favoriteTeamCode == nil {
                VStack(alignment: .center, spacing: 6) {
                    Text("⚽️")
                        .font(.system(size: 24))
                    Text(entry.data.labelNoFavoriteTeam)
                        .font(.system(size: 10, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if family == .systemSmall {
                    // Small layout: Show next match or last result
                    if let next = entry.data.myTeamNextMatch {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.data.labelNextMatch.uppercased())
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                            
                            HStack(spacing: 6) {
                                Text(next.homeTeamEmoji)
                                    .font(.system(size: 18))
                                Text("VS")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                                Text(next.awayTeamEmoji)
                                    .font(.system(size: 18))
                                Spacer()
                            }
                            
                            Text("\(next.homeTeamName) - \(next.awayTeamName)")
                                .font(.system(size: 10, weight: .bold))
                                .lineLimit(1)
                                .foregroundStyle(.white)
                            
                            Spacer(minLength: 0)
                            
                            Text(next.date, style: .date)
                                .font(.system(size: 8))
                                .foregroundStyle(.white.opacity(0.6))
                            Text(next.date, style: .time)
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                        }
                    } else if let last = entry.data.myTeamLastResult {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.data.labelLastResult.uppercased())
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                            
                            HStack(spacing: 6) {
                                Text(last.homeTeamEmoji)
                                    .font(.system(size: 18))
                                Text("VS")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                                Text(last.awayTeamEmoji)
                                    .font(.system(size: 18))
                                Spacer()
                            }
                            
                            Text("\(last.homeScore) - \(last.awayScore)")
                                .font(.system(size: 15, weight: .black))
                                .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                            
                            Text("\(last.homeTeamName) - \(last.awayTeamName)")
                                .font(.system(size: 9))
                                .lineLimit(1)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    } else {
                        Text(entry.data.labelNoRecentMatch)
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                } else {
                    // Medium layout: side-by-side (Next Match & Last Result)
                    HStack(spacing: 12) {
                        // Left side: Next Match
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.data.labelNextMatch.uppercased())
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                            
                            if let next = entry.data.myTeamNextMatch {
                                HStack(spacing: 6) {
                                    Text(next.homeTeamEmoji)
                                        .font(.system(size: 22))
                                    Text("VS")
                                        .font(.system(size: 13, weight: .black))
                                        .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                                    Text(next.awayTeamEmoji)
                                        .font(.system(size: 22))
                                }
                                Text("\(next.homeTeamName) vs \(next.awayTeamName)")
                                    .font(.system(size: 11, weight: .bold))
                                    .lineLimit(1)
                                    .foregroundStyle(.white)
                                
                                Spacer(minLength: 0)
                                
                                Text(next.date, style: .date)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white.opacity(0.6))
                                Text(next.date, style: .time)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                            } else {
                                Text(entry.data.labelNoUpcomingMatch)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white.opacity(0.4))
                                Spacer()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider().background(.white.opacity(0.15))
                        
                        // Right side: Last Result
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.data.labelLastResult.uppercased())
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                            
                            if let last = entry.data.myTeamLastResult {
                                HStack(spacing: 6) {
                                    Text(last.homeTeamEmoji)
                                        .font(.system(size: 22))
                                    Text("VS")
                                        .font(.system(size: 13, weight: .black))
                                        .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                                    Text(last.awayTeamEmoji)
                                        .font(.system(size: 22))
                                }
                                
                                Text("\(last.homeScore) - \(last.awayScore)")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                                
                                Text("\(last.homeTeamName) vs \(last.awayTeamName)")
                                    .font(.system(size: 9))
                                    .lineLimit(1)
                                    .foregroundStyle(.white.opacity(0.6))
                                
                                Spacer()
                            } else {
                                Text(entry.data.labelNoRecentResult)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white.opacity(0.4))
                                Spacer()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

// MARK: - Widget Configurations

struct MatchOfTheDayWidget: Widget {
    let kind: String = "com.mm.WorldCup2026.MatchOfTheDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                MatchOfTheDayEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        LinearGradient(
                            gradient: Gradient(colors: [Color(red: 0.05, green: 0.20, blue: 0.10), Color(red: 0.02, green: 0.08, blue: 0.04)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
            } else {
                MatchOfTheDayEntryView(entry: entry)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(red: 0.05, green: 0.20, blue: 0.10), Color(red: 0.02, green: 0.08, blue: 0.04)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .configurationDisplayName("Match du Jour")
        .description("Suivez le match du jour en direct ou la prochaine affiche.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MyTeamWidget: Widget {
    let kind: String = "com.mm.WorldCup2026.MyTeamWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                MyTeamEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        LinearGradient(
                            gradient: Gradient(colors: [Color(red: 0.05, green: 0.12, blue: 0.20), Color(red: 0.02, green: 0.05, blue: 0.10)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
            } else {
                MyTeamEntryView(entry: entry)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(red: 0.05, green: 0.12, blue: 0.20), Color(red: 0.02, green: 0.05, blue: 0.10)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .configurationDisplayName("Mon Équipe")
        .description("Suivez les résultats et le prochain match de votre équipe favorite.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#if canImport(ActivityKit)
import ActivityKit

struct LiveScoreActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveScoreAttributes.self) { context in
            // Lock screen / banner UI
            LockScreenLiveScoreView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Text(context.attributes.homeTeamEmoji)
                            .font(.system(size: 28))
                        Text(context.attributes.homeTeamName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.leading, 8)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 8) {
                        Text(context.attributes.awayTeamName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                        Text(context.attributes.awayTeamEmoji)
                            .font(.system(size: 28))
                    }
                    .padding(.trailing, 8)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("\(context.state.homeScore) - \(context.state.awayScore)")
                            .font(.system(size: 26, weight: .black))
                            .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5)) // Gold
                        
                        Text(context.state.status.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.red)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.attributes.stage)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        if context.state.matchStatusRawValue == "Live" {
                            HStack(spacing: 4) {
                                Circle().fill(Color.red).frame(width: 6, height: 6)
                                Text(context.state.liveLabel)
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Text(context.attributes.homeTeamEmoji)
                    Text("\(context.state.homeScore)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                }
            } compactTrailing: {
                HStack(spacing: 4) {
                    Text("\(context.state.awayScore)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                    Text(context.attributes.awayTeamEmoji)
                }
            } minimal: {
                Text(context.state.status == "LIVE" ? "⚽️" : "\(context.state.homeScore)-\(context.state.awayScore)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
            }
        }
    }
}

struct MatchProgressBar: View {
    let status: String
    let timerStartDate: Date?
    
    private var elapsedMinutes: Int {
        if status.lowercased().contains("ht") || status.lowercased().contains("mi-temp") || status.lowercased().contains("half") {
            return 45
        }
        if status.lowercased().contains("finished") || status.lowercased().contains("termin") {
            return 90
        }
        let clean = status.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(clean) ?? 0
    }
    
    private var totalMinutes: Int {
        elapsedMinutes > 90 ? 120 : 90
    }
    
    var body: some View {
        if let startDate = timerStartDate, status.lowercased() != "ht", !status.lowercased().contains("mi-temp"), !status.lowercased().contains("finished"), !status.lowercased().contains("termin") {
            // Live match with a running timer
            let totalSeconds = Double(totalMinutes * 60)
            VStack(spacing: 6) {
                ProgressView(timerInterval: startDate...startDate.addingTimeInterval(totalSeconds), countsDown: false, label: { EmptyView() }, currentValueLabel: { EmptyView() })
                    .tint(.green)
                
                HStack {
                    Text(status)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                    Spacer()
                    Text("\(totalMinutes) min")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 4)
        } else {
            // Fallback for static display (Halftime, Finished, Scheduled)
            let total = totalMinutes
            let elapsed = min(max(elapsedMinutes, 0), total)
            let remaining = max(total - elapsed, 0)
            
            VStack(spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.9, green: 0.8, blue: 0.5), .green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(elapsed) / CGFloat(total), height: 6)
                    }
                }
                .frame(height: 6)
                
                HStack {
                    Text("\(elapsed) min")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                    Spacer()
                    Text("-\(remaining) min")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct LockScreenLiveScoreView: View {
    let context: ActivityViewContext<LiveScoreAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Home Team
                VStack(spacing: 4) {
                    Text(context.attributes.homeTeamEmoji)
                        .font(.system(size: 34))
                    Text(context.attributes.homeTeamName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                
                // Score Info
                VStack(spacing: 4) {
                    Text(context.attributes.stage)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                    
                    Text("\(context.state.homeScore) - \(context.state.awayScore)")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                    
                    HStack(spacing: 4) {
                        if context.state.matchStatusRawValue == "Live" {
                            Circle().fill(Color.red).frame(width: 6, height: 6)
                            Text(context.state.liveLabel)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.red)
                        } else {
                            Text(context.state.status.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
                .frame(width: 100)
                
                // Away Team
                VStack(spacing: 4) {
                    Text(context.attributes.awayTeamEmoji)
                        .font(.system(size: 34))
                    Text(context.attributes.awayTeamName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Progress Bar Section
            if context.state.matchStatusRawValue == "Live" || context.state.matchStatusRawValue == "Finished" {
                MatchProgressBar(status: context.state.status, timerStartDate: context.state.timerStartDate)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.05, green: 0.20, blue: 0.10), Color(red: 0.02, green: 0.08, blue: 0.04)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
#endif

@main
struct WorldCupWidgetBundle: WidgetBundle {
    var body: some Widget {
        MatchOfTheDayWidget()
        MyTeamWidget()
        #if canImport(ActivityKit)
        LiveScoreActivityWidget()
        #endif
    }
}

