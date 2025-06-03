import Foundation

enum CategoryFilter: String, CaseIterable {
    case all = "Tous les items"
    case manteau = "Manteau"
    case tshirt = "T-Shirt"
    case sweat = "Sweat"
}

struct Product: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let category: CategoryFilter
    let imageName: String
    let prix: Double
    let rating: Double
    let description: String
}

let allProducts: [Product] = [
    Product(
        name: "Doudoune",
        category: .manteau,
        imageName: "Doudoune",
        prix: 162.99,
        rating: 5.0,
        description: "Doudoune épaisse parfaite pour l'hiver, coupe moderne et tissu déperlant."
    ),
    Product(
        name: "Sweat noir",
        category: .sweat,
        imageName: "image_enfant",
        prix: 59.99,
        rating: 5.0,
        description: "Sweat confortable en coton bio, idéal pour un look streetwear."
    ),
    Product(
        name: "Sweat gris",
        category: .sweat,
        imageName: "Sweat_gris",
        prix: 59.99,
        rating: 5.0,
        description: "Sweat gris unisexe, coupe oversize, molleton intérieur doux."
    ),
    Product(
        name: "Parka noir",
        category: .manteau,
        imageName: "Parka",
        prix: 159.99,
        rating: 5.0,
        description: "Parka imperméable avec capuche amovible et doublure chaude."
    ),
    Product(
        name: "T-Shirt blanc",
        category: .tshirt,
        imageName: "T-shirt_blanc",
        prix: 29.99,
        rating: 5.0,
        description: "T-shirt basique blanc en coton 100%, coupe droite et col rond."
    )
]
