
import SwiftUI

struct MatchCardView: View {
    let match: Match
    
    var isEnglish: Bool {
        Locale.current.identifier.starts(with: "en")
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Status Header
            HStack {
                Text(match.group ?? match.stage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .textCase(.uppercase)
                
                Spacer()
                
                StatusBadge(match: match)
            }
            .padding(.horizontal, 4)
            
            // Teams and Score
            HStack(alignment: .center) {
                // Home Team
                VStack(spacing: 6) {
                    Text(match.homeTeam?.emoji ?? "🏳️")
                        .font(.system(size: 80))
                        .shadow(color: .white.opacity(0.3), radius: 5)
                    Text(LocalizedStringKey(match.homeTeam?.name ?? "Home"))
                        .font(.system(size: 18, weight: .black))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.white)
                    
                    if match.status == .finished && (match.homeScore ?? 0) > (match.awayScore ?? 0) {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Score or VS
                VStack(spacing: 4) {
                    if match.status == .scheduled {
                        Text("VS")
                            .font(.system(size: 40, weight: .black))
                            .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.4))
                            .shadow(color: Color(red: 0.9, green: 0.8, blue: 0.4).opacity(0.5), radius: 5)
                        
                        Text(match.date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(isEnglish ? Locale(identifier: "en_US") : Locale(identifier: "fr_FR"))))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    } else {
                        HStack(spacing: 8) {
                            Text("\(match.homeScore ?? 0)")
                                .metricStyle()
                            Text("-")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(match.awayScore ?? 0)")
                                .metricStyle()
                        }
                        
                        if match.status == .live {
                            Text("LIVE UPDATE")
                                .font(.system(size: 9, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.2))
                                .foregroundStyle(Color.green)
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(width: 100)
                
                // Away Team
                VStack(spacing: 6) {
                    Text(match.awayTeam?.emoji ?? "🏳️")
                        .font(.system(size: 80))
                        .shadow(color: .white.opacity(0.3), radius: 5)
                    Text(LocalizedStringKey(match.awayTeam?.name ?? "Away"))
                        .font(.system(size: 18, weight: .black))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.white)
                    
                    if match.status == .finished && (match.awayScore ?? 0) > (match.homeScore ?? 0) {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Venue and Date
            HStack {
                Label {
                    Text(LocalizedStringKey(match.venue?.city ?? "Unknown"))
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                Label {
                    Text(match.date.formatted(.dateTime.day().month().year()))
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.6))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 0.9, green: 0.8, blue: 0.4).opacity(0.8), Color(red: 0.9, green: 0.8, blue: 0.4).opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func metricStyle() -> some View {
        self
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .white.opacity(0.5), radius: 4)
    }
}

struct StatusBadge: View {
    let match: Match
    
    var body: some View {
        HStack(spacing: 4) {
            if match.status == .live {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text(LocalizedStringKey("LIVE"))
            } else if match.status == .finished {
                Text(LocalizedStringKey("Finished"))
            } else {
                // Check if match is upcoming soon (e.g., within 24h)
                Image(systemName: "hourglass")
                Text(LocalizedStringKey("Upcoming"))
            }
        }
        .font(.system(size: 12, weight: .bold))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(match.status == .scheduled ? Color.white.opacity(0.15) : (match.status == .live ? Color.red.opacity(0.2) : Color.white.opacity(0.15)))
        .foregroundStyle(match.status == .scheduled ? Color(red: 0.9, green: 0.8, blue: 0.4) : (match.status == .live ? Color.red : Color.white))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(match.status == .scheduled ? Color(red: 0.9, green: 0.8, blue: 0.4).opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}
