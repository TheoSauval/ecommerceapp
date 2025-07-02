import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // En-tête
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Politique de Confidentialité")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Dernière mise à jour : \(Date().formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom)
                    
                    // Introduction
                    SectionView(title: "1. Introduction") {
                        Text("Cette politique de confidentialité décrit comment Shop Clothing collecte, utilise et protège vos informations personnelles conformément au Règlement Général sur la Protection des Données (RGPD).")
                    }
                    
                    // Collecte des données
                    SectionView(title: "2. Données que nous collectons") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nous collectons les informations suivantes :")
                                .fontWeight(.medium)
                            
                            BulletPoint("Informations d'identification (nom, prénom, email)")
                            BulletPoint("Informations de profil (âge, préférences)")
                            BulletPoint("Données de commande et historique d'achat")
                            BulletPoint("Données de navigation et cookies")
                            BulletPoint("Adresse de livraison et facturation")
                        }
                    }
                    
                    // Utilisation des données
                    SectionView(title: "3. Utilisation de vos données") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vos données sont utilisées pour :")
                                .fontWeight(.medium)
                            
                            BulletPoint("Traiter vos commandes et paiements")
                            BulletPoint("Personnaliser votre expérience d'achat")
                            BulletPoint("Vous envoyer des communications marketing (avec votre consentement)")
                            BulletPoint("Améliorer nos services et produits")
                            BulletPoint("Respecter nos obligations légales")
                        }
                    }
                    
                    // Base légale
                    SectionView(title: "4. Base légale du traitement") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Le traitement de vos données est fondé sur :")
                                .fontWeight(.medium)
                            
                            BulletPoint("L'exécution du contrat (traitement de commande)")
                            BulletPoint("Votre consentement (marketing)")
                            BulletPoint("L'intérêt légitime (amélioration des services)")
                            BulletPoint("L'obligation légale (facturation, comptabilité)")
                        }
                    }
                    
                    // Partage des données
                    SectionView(title: "5. Partage de vos données") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nous ne vendons jamais vos données personnelles. Nous pouvons les partager avec :")
                                .fontWeight(.medium)
                            
                            BulletPoint("Nos prestataires de services (livraison, paiement)")
                            BulletPoint("Les autorités compétentes (obligation légale)")
                            BulletPoint("Nos partenaires techniques (hébergement, sécurité)")
                        }
                    }
                    
                    // Vos droits
                    SectionView(title: "6. Vos droits RGPD") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Conformément au RGPD, vous disposez des droits suivants :")
                                .fontWeight(.medium)
                            
                            BulletPoint("Droit d'accès à vos données personnelles")
                            BulletPoint("Droit de rectification des données inexactes")
                            BulletPoint("Droit à l'effacement (droit à l'oubli)")
                            BulletPoint("Droit à la limitation du traitement")
                            BulletPoint("Droit à la portabilité de vos données")
                            BulletPoint("Droit d'opposition au traitement")
                            BulletPoint("Droit de retirer votre consentement")
                        }
                    }
                    
                    // Récupération des données
                    SectionView(title: "7. Récupération de vos données") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Avant de supprimer votre compte, vous pouvez récupérer toutes vos données personnelles.")
                                .fontWeight(.medium)
                            
                            Text("Pour exercer ce droit, contactez-nous à :")
                                .fontWeight(.medium)
                            
                            HStack {
                                Image(systemName: "envelope")
                                Text("shop-clothing@gmail.com")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 5)
                            
                            Text("Nous vous répondrons dans un délai maximum de 30 jours et vous fournirons vos données dans un format structuré et lisible.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Conservation des données
                    SectionView(title: "8. Conservation des données") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nous conservons vos données :")
                                .fontWeight(.medium)
                            
                            BulletPoint("Pendant la durée de votre compte actif")
                            BulletPoint("3 ans après votre dernière activité (historique d'achat)")
                            BulletPoint("10 ans pour les données comptables (obligation légale)")
                            BulletPoint("Jusqu'à votre demande de suppression")
                        }
                    }
                    
                    // Sécurité
                    SectionView(title: "9. Sécurité des données") {
                        Text("Nous mettons en place des mesures de sécurité appropriées pour protéger vos données contre tout accès non autorisé, modification, divulgation ou destruction.")
                    }
                    
                    // Cookies
                    SectionView(title: "10. Cookies et technologies similaires") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nous utilisons des cookies pour :")
                                .fontWeight(.medium)
                            
                            BulletPoint("Mémoriser vos préférences")
                            BulletPoint("Analyser le trafic du site")
                            BulletPoint("Améliorer nos services")
                            
                            Text("Vous pouvez désactiver les cookies dans les paramètres de votre navigateur.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Contact DPO
                    SectionView(title: "11. Contact et Délégué à la Protection des Données") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pour toute question concernant cette politique :")
                                .fontWeight(.medium)
                            
                            HStack {
                                Image(systemName: "envelope")
                                Text("shop-clothing@gmail.com")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 5)
                            
                            Text("Vous avez également le droit de déposer une plainte auprès de la CNIL si vous estimez que vos droits ne sont pas respectés.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Modifications
                    SectionView(title: "12. Modifications de cette politique") {
                        Text("Nous nous réservons le droit de modifier cette politique de confidentialité. Les modifications seront publiées sur cette page avec une nouvelle date de mise à jour.")
                    }
                }
                .padding()
            }
            .navigationTitle("Confidentialité")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Fermer") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// Composants auxiliaires
struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            content
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .fontWeight(.bold)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
    }
} 