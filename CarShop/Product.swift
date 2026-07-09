import Foundation

struct ProductCatalog: Decodable {
    let categories: [ProductCategory]
    let items: [Product]
}

struct ProductCategory: Identifiable, Decodable, Hashable {
    let id: String
    let name: String

    static let new = ProductCategory(id: "new", name: "Новинки")
}

struct Product: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
    let shortDescription: String
    let longDescription: String
    let priceInKopecks: Int
    let imageUrl: String
    let tags: [String]
    let categoryId: String
    let sizes: [String]
    let material: String
    let weight: String
    let season: String
    let countryOfOrigin: String

    var configurations: [String] { sizes }
    var engine: String { material }
    var drivetrain: String { season }

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.maximumFractionDigits = 0

        let rubles = NSNumber(value: priceInKopecks / 100)
        return "\(formatter.string(from: rubles) ?? rubles.stringValue) ₽"
    }
}
