import Foundation
import Combine

@MainActor
final class CartViewModel: ObservableObject {
    @Published private(set) var items: [StoredCartItem] = []
    @Published var showOrderSuccess = false

    private let store: any CartCaching

    init(store: any CartCaching = CartStore(), automaticallyLoads: Bool = true) {
        self.store = store
        if automaticallyLoads {
            Task { await reload() }
        }
    }

    private func reload() async {
        items = await store.load()
    }

    private func persist() {
        let snapshot = items
        Task { await store.save(snapshot) }
    }

    var badgeCount: Int { items.reduce(0) { $0 + $1.quantity } }

    func add(product: Product, sizeId: String) {
        if let index = items.firstIndex(where: { $0.productId == product.id && $0.sizeId == sizeId }) {
            items[index].quantity += 1
        } else {
            items.append(StoredCartItem(productId: product.id, sizeId: sizeId, quantity: 1))
        }
        persist()
    }

    func increment(_ item: ResolvedCartItem) {
        guard let index = index(of: item) else { return }
        items[index].quantity += 1
        persist()
    }

    func decrement(_ item: ResolvedCartItem) {
        guard let index = index(of: item) else { return }
        items[index].quantity -= 1
        if items[index].quantity <= 0 {
            items.remove(at: index)
        }
        persist()
    }

    func remove(_ item: ResolvedCartItem) {
        items.removeAll { $0.productId == item.product.id && $0.sizeId == item.sizeId }
        persist()
    }

    func clear() {
        items.removeAll()
        persist()
    }

    private func index(of item: ResolvedCartItem) -> Int? {
        items.firstIndex { $0.productId == item.product.id && $0.sizeId == item.sizeId }
    }

    func resolvedItems(using catalog: ProductCatalog?) -> [ResolvedCartItem] {
        guard let catalog else { return [] }
        let productsById = Dictionary(catalog.items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        return items.compactMap { stored in
            guard let product = productsById[stored.productId] else { return nil }
            let sizeName = product.sizes.first { $0.id == stored.sizeId }?.name ?? "—"
            return ResolvedCartItem(
                product: product,
                sizeId: stored.sizeId,
                sizeName: sizeName,
                quantity: stored.quantity
            )
        }
    }

    func totalKopecks(using catalog: ProductCatalog?) -> Int {
        resolvedItems(using: catalog).reduce(0) { $0 + $1.lineKopecks }
    }

    func formattedTotal(using catalog: ProductCatalog?) -> String {
        PriceFormatter.format(kopecks: totalKopecks(using: catalog))
    }

    func isNameValid(_ name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func isEmailValid(_ email: String) -> Bool {
        let pattern = "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$"
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    func canPlaceOrder(name: String, email: String) -> Bool {
        !items.isEmpty && isNameValid(name) && isEmailValid(email)
    }

    func placeOrder(name: String, email: String, comment: String) {
        guard canPlaceOrder(name: name, email: email) else { return }
        clear()
        showOrderSuccess = true
    }
}
