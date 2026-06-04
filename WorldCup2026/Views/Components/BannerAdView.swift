import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    // ID fourni par l'utilisateur : ca-app-pub-9925772968209181/7128705659
    // En mode DEBUG, nous utilisons l'ID de test officiel de Google pour éviter
    // de générer du trafic non valide et de pénaliser votre compte de production.
    #if DEBUG
    let adUnitID: String = "ca-app-pub-3940256099942544/2934735716" // ID de test officiel
    #else
    let adUnitID: String = "ca-app-pub-9925772968209181/7128705659" // ID réel de production
    #endif
    
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = adUnitID
        
        // Recherche de la fenêtre principale et de son RootViewController pour présenter l'annonce
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }
        
        bannerView.load(GADRequest())
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

#Preview {
    BannerAdView()
        .frame(height: 50)
}
