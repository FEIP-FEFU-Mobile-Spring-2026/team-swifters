import Foundation
import Combine

@MainActor
final class CatalogViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded(ProductCatalog)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published var selectedCategoryId: String {
        didSet {
            defaults.set(selectedCategoryId, forKey: Self.selectedCategoryKey)
        }
    }

    private static let selectedCategoryKey = "catalog.selectedCategory"

    private let repository: any ProductRepository
    private let defaults: UserDefaults

    init(
        repository: any ProductRepository,
        defaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.defaults = defaults
        self.selectedCategoryId = defaults.string(forKey: Self.selectedCategoryKey) ?? ProductCategory.new.id
    }

    var categories: [ProductCategory] {
        guard case let .loaded(catalog) = state else { return [] }
        return [.new] + catalog.categories
    }

    var visibleProducts: [Product] {
        guard case let .loaded(catalog) = state else { return [] }

        if selectedCategoryId == ProductCategory.new.id {
            return catalog.items.filter { $0.tags.contains("New") }
        }

        return catalog.items.filter { $0.categoryId == selectedCategoryId }
    }

    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    func load() async {
        state = .loading

        do {
            let catalog = try await repository.loadCatalog()
            let validCategoryIds = Set(catalog.categories.map(\.id) + [ProductCategory.new.id])
            if !validCategoryIds.contains(selectedCategoryId) {
                selectedCategoryId = ProductCategory.new.id
            }
            state = .loaded(catalog)
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
