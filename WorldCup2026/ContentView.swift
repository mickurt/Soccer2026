
import SwiftUI
import SwiftData

struct ContentView: View {
    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor.white
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                MatchesView()
                    .tabItem {
                        Label(LocalizedStringKey("Matches"), systemImage: "sportscourt")
                    }
                
                TeamsView()
                    .tabItem {
                        Label(LocalizedStringKey("Countries"), systemImage: "flag.2.crossed")
                    }
                
                MyTeamView()
                    .tabItem {
                        Label(LocalizedStringKey("My Team"), systemImage: "star.fill")
                    }
                
                MiniGameView()
                    .tabItem {
                        Label(LocalizedStringKey("Play"), systemImage: "gamecontroller.fill")
                    }
                
                QuizView()
                    .tabItem {
                        Label(LocalizedStringKey("Quiz"), systemImage: "lightbulb.fill")
                    }
            }
            .tint(Color(red: 0.9, green: 0.8, blue: 0.5)) // Gold color for selected
            
            // Bannière publicitaire AdMob
            BannerAdView()
                .frame(height: 50)
                .background(Color.black)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Match.self, Team.self, Venue.self], inMemory: true)
}
