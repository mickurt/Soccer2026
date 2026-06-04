import Foundation
import Combine
import AppTrackingTransparency
import AdSupport
import GoogleMobileAds

class AdManager: ObservableObject {
    static let shared = AdManager()
    
    @Published var isTrackingAuthorized: Bool = false
    
    private init() {
        updateTrackingStatus()
    }
    
    func updateTrackingStatus() {
        let status = ATTrackingManager.trackingAuthorizationStatus
        DispatchQueue.main.async {
            self.isTrackingAuthorized = (status == .authorized)
        }
    }
    
    /// Demande l'autorisation de suivi publicitaire (ATT) et initialise le SDK Google Mobile Ads
    func requestTrackingAuthorization(completion: @escaping () -> Void = {}) {
        // Nous attendons 1 seconde pour s'assurer que la fenêtre de l'application est bien active,
        // ce qui est requis pour que le pop-up ATT puisse s'afficher correctement à l'écran.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in
                self.updateTrackingStatus()
                
                // Initialise le SDK AdMob (avec ou sans personnalisation selon le choix de l'utilisateur)
                MobileAds.shared.start()
                
                print("Demande ATT terminée. Statut : \(status.rawValue)")
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
}
