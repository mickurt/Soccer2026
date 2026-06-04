
import SwiftUI
import SwiftData

struct TeamsView: View {
    @Query(sort: \Team.name) private var teams: [Team]
    
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 20)]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header
                VStack(spacing: 4) {
                    Text(LocalizedStringKey("Countries"))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .green.opacity(0.5), radius: 10)
                    
                    Text("Road to the Final")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                        .shadow(color: .black.opacity(0.5), radius: 2)
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(teams) { team in
                        NavigationLink(destination: CountryDetailView(team: team)) {
                            VStack {
                                Text(team.emoji)
                                    .font(.system(size: 60))
                                    .shadow(radius: 2)
                                Text(LocalizedStringKey(team.name))
                                    .font(.caption)
                                    .bold()
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.white)
                            }
                            .frame(minWidth: 100, minHeight: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.6))
                            )
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
                }
                .padding()
            }
            } // Close VStack(spacing: 0)
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
}
