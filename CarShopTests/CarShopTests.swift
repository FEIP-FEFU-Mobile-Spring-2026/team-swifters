import XCTest
@testable import CarShop

@MainActor
final class CartViewModelTests: XCTestCase {
    func testAddingSameProductAndSizeIncrementsQuantity() {
        let cart = CartViewModel(store: InMemoryCartStore(), automaticallyLoads: false)
        let product = Product.testFixture()

        cart.add(product: product, sizeId: "size_m")
        cart.add(product: product, sizeId: "size_m")

        XCTAssertEqual(cart.items.count, 1)
        XCTAssertEqual(cart.items.first?.quantity, 2)
        XCTAssertEqual(cart.badgeCount, 2)
    }

    func testAddingDifferentSizesCreatesSeparateCartRows() {
        let cart = CartViewModel(store: InMemoryCartStore(), automaticallyLoads: false)
        let product = Product.testFixture()

        cart.add(product: product, sizeId: "size_s")
        cart.add(product: product, sizeId: "size_m")

        XCTAssertEqual(cart.items.count, 2)
        XCTAssertEqual(Set(cart.items.map(\.sizeId)), Set(["size_s", "size_m"]))
    }

    func testDecrementRemovesCartRowWhenQuantityReachesZero() {
        let cart = CartViewModel(store: InMemoryCartStore(), automaticallyLoads: false)
        let product = Product.testFixture()

        cart.add(product: product, sizeId: "size_m")
        let item = cart.resolvedItems(using: ProductCatalog.testFixture()).first!

        cart.decrement(item)

        XCTAssertTrue(cart.items.isEmpty)
        XCTAssertEqual(cart.badgeCount, 0)
    }

    func testOrderValidationRequiresNameAndValidEmail() {
        let cart = CartViewModel(store: InMemoryCartStore(), automaticallyLoads: false)
        let product = Product.testFixture()
        cart.add(product: product, sizeId: "size_m")

        XCTAssertTrue(cart.canPlaceOrder(name: "Елисей", email: "elisey@example.com"))
        XCTAssertFalse(cart.canPlaceOrder(name: " ", email: "elisey@example.com"))
        XCTAssertFalse(cart.canPlaceOrder(name: "Елисей", email: "not-email"))
    }

    func testResolvedCartItemUsesCatalogDataAndCalculatesLinePrice() {
        let cart = CartViewModel(store: InMemoryCartStore(), automaticallyLoads: false)
        let product = Product.testFixture(priceInKopecks: 199900)

        cart.add(product: product, sizeId: "size_m")
        cart.add(product: product, sizeId: "size_m")

        let resolved = cart.resolvedItems(using: ProductCatalog.testFixture(product: product))

        XCTAssertEqual(resolved.count, 1)
        XCTAssertEqual(resolved.first?.sizeName, "M")
        XCTAssertEqual(resolved.first?.lineKopecks, 399800)
        let formattedTotal = cart.formattedTotal(using: ProductCatalog.testFixture(product: product))
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .replacingOccurrences(of: "\u{202f}", with: " ")

        XCTAssertEqual(formattedTotal, "3 998 ₽")
    }
}

@MainActor
final class CatalogViewModelTests: XCTestCase {
    func testNewCategoryShowsProductsTaggedNew() async {
        let catalog = ProductCatalog.testFixture(
            product: Product.testFixture(id: "new_item", tags: ["New"]),
            extraProducts: [
                Product.testFixture(id: "regular_item", tags: [])
            ]
        )
        let viewModel = CatalogViewModel(
            repository: MockProductRepository(catalog: catalog),
            cache: MockCatalogCache(),
            monitor: TestNetworkMonitor(isConnected: true),
            defaults: .isolated()
        )

        await viewModel.load()
        viewModel.selectedCategoryId = ProductCategory.new.id

        XCTAssertEqual(viewModel.visibleProducts.map(\.id), ["new_item"])
    }

    func testSelectedCategoryFiltersProductsByCategoryId() async {
        let catalog = ProductCatalog.testFixture(
            product: Product.testFixture(id: "jeans", categoryId: "cat_jeans", tags: []),
            extraProducts: [
                Product.testFixture(id: "shirt", categoryId: "cat_shirts", tags: ["New"])
            ]
        )
        let viewModel = CatalogViewModel(
            repository: MockProductRepository(catalog: catalog),
            cache: MockCatalogCache(),
            monitor: TestNetworkMonitor(isConnected: true),
            defaults: .isolated()
        )

        await viewModel.load()
        viewModel.selectedCategoryId = "cat_shirts"

        XCTAssertEqual(viewModel.visibleProducts.map(\.id), ["shirt"])
    }
}

final class ProductMappingTests: XCTestCase {
    func testCatalogDecodingMapsSizesAndCharacteristics() throws {
        let json = """
        {
          "categories": [{"id": "cat_tshirts", "name": "Футболки"}],
          "items": [{
            "id": "item_001",
            "name": "Футболка",
            "shortDescription": "Базовая модель",
            "longDescription": "Базовая хлопковая футболка",
            "priceInKopecks": 129900,
            "imageUrl": "https://example.com/tshirt.jpg",
            "tags": ["New"],
            "categoryId": "cat_tshirts",
            "sizes": [{"id": "size_s", "name": "S"}],
            "material": "100% хлопок",
            "weight": "180 г",
            "season": "Лето",
            "countryOfOrigin": "Узбекистан"
          }]
        }
        """.data(using: .utf8)!

        let catalog = try JSONDecoder().decode(ProductCatalog.self, from: json)

        XCTAssertEqual(catalog.categories.first?.name, "Футболки")
        XCTAssertEqual(catalog.items.first?.sizes.first?.name, "S")
        XCTAssertEqual(catalog.items.first?.material, "100% хлопок")
        XCTAssertEqual(catalog.items.first?.season, "Лето")
    }
}

private final class InMemoryCartStore: CartCaching {
    private var items: [StoredCartItem]

    init(items: [StoredCartItem] = []) {
        self.items = items
    }

    func load() async -> [StoredCartItem] {
        items
    }

    func save(_ items: [StoredCartItem]) async {
        self.items = items
    }
}

private struct MockProductRepository: ProductRepository {
    let catalog: ProductCatalog

    func loadCatalog() async throws -> ProductCatalog {
        catalog
    }
}

private final class MockCatalogCache: CatalogCaching {
    var cachedCatalog: ProductCatalog?
    private(set) var savedCatalog: ProductCatalog?

    init(cachedCatalog: ProductCatalog? = nil) {
        self.cachedCatalog = cachedCatalog
    }

    func load() async -> ProductCatalog? {
        cachedCatalog
    }

    func save(_ catalog: ProductCatalog) async {
        savedCatalog = catalog
    }
}

private final class TestNetworkMonitor: NetworkMonitoring {
    var isConnected: Bool
    var onChange: ((Bool) -> Void)?

    init(isConnected: Bool) {
        self.isConnected = isConnected
    }
}

private extension ProductCatalog {
    static func testFixture(
        product: Product = .testFixture(),
        extraProducts: [Product] = []
    ) -> ProductCatalog {
        ProductCatalog(
            categories: [
                ProductCategory(id: "cat_jeans", name: "Джинсы"),
                ProductCategory(id: "cat_shirts", name: "Рубашки")
            ],
            items: [product] + extraProducts
        )
    }
}

private extension Product {
    static func testFixture(
        id: String = "item_001",
        priceInKopecks: Int = 499900,
        categoryId: String = "cat_jeans",
        tags: [String] = ["New"]
    ) -> Product {
        Product(
            id: id,
            name: "Джинсы Slim Fit",
            shortDescription: "Классические зауженные джинсы",
            longDescription: "Стильные джинсы зауженного кроя из качественного денима.",
            priceInKopecks: priceInKopecks,
            imageUrl: "https://example.com/jeans.jpg",
            tags: tags,
            categoryId: categoryId,
            sizes: [
                ProductSize(id: "size_s", name: "S"),
                ProductSize(id: "size_m", name: "M")
            ],
            material: "98% хлопок, 2% эластан",
            weight: "450 г",
            season: "Всесезон",
            countryOfOrigin: "Турция"
        )
    }
}

private extension UserDefaults {
    static func isolated() -> UserDefaults {
        let suiteName = "CarShopTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
