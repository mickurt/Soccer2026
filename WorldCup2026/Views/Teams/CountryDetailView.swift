
import SwiftUI
import SwiftData

struct CountryDetailView: View {
    let team: Team
    @Query(sort: \Match.date) private var allMatches: [Match]
    
    var teamMatches: [Match] {
        allMatches.filter { match in
            match.homeTeam?.id == team.id || match.awayTeam?.id == team.id
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with large flag
                VStack(spacing: 8) {
                    Text(team.emoji)
                        .font(.system(size: 150))
                        .shadow(color: .white.opacity(0.3), radius: 10)
                        .padding(.top, 20)
                    
                    Text(LocalizedStringKey(team.name))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.8), radius: 6, x: 0, y: 2)
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 1, y: 1)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
                
                // Matches Section
                if teamMatches.isEmpty {
                    ContentUnavailableView {
                        Label(LocalizedStringKey("No Matches Scheduled"), systemImage: "sportscourt.slash")
                            .foregroundStyle(.white)
                    } description: {
                        Text(LocalizedStringKey("This team has no scheduled matches yet."))
                            .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                    }
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(teamMatches) { match in
                             NavigationLink(destination: MatchDetailView(match: match)) {
                                 MatchCardView(match: match)
                             }
                             .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background {
            GeometryReader { geometry in
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
        }
    }
}
