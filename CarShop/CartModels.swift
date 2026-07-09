import Foundation

struct StoredCartItem: Identifiable, Hashable {
    let productId: String
    let sizeId: String
    var quantity: Int

    var id: String { "\(productId)|\(sizeId)" }
}

struct ResolvedCartItem: Identifiable {
    let product: Product
    let sizeId: String
    let sizeName: String
    let quantity: Int

    var id: String { "\(product.id)|\(sizeId)" }
    var lineKopecks: Int { product.priceInKopecks * quantity }
    var formattedLinePrice: String { PriceFormatter.format(kopecks: lineKopecks) }
}

enum PriceFormatter {
    static func format(kopecks: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.maximumFractionDigits = 0

        let rubles = NSNumber(value: kopecks / 100)
        return "\(formatter.string(from: rubles) ?? rubles.stringValue) ₽"
    }
}