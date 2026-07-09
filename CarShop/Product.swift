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

struct ProductSize: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
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
    let sizes: [ProductSize]
    let material: String
    let weight: String
    let season: String
    let countryOfOrigin: String

    var formattedPrice: String {
        PriceFormatter.format(kopecks: priceInKopecks)
    }
}
