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

    @Published private(set) var isShowingCachedData = false

    @Published private(set) var isOffline = false

    @Published var selectedCategoryId: String {
        didSet {
            defaults.set(selectedCategoryId, forKey: Self.selectedCategoryKey)
        }
    }

    private static let selectedCategoryKey = "catalog.selectedCategory"

    private let repository: any ProductRepository
    private let cache: any CatalogCaching
    private let monitor: any NetworkMonitoring
    private let defaults: UserDefaults

    init(
        repository: any ProductRepository,
        cache: any CatalogCaching = CatalogCache.shared,
        monitor: any NetworkMonitoring = NetworkMonitor(),
        defaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.cache = cache
        self.monitor = monitor
        self.defaults = defaults
        self.selectedCategoryId = defaults.string(forKey: Self.selectedCategoryKey) ?? ProductCategory.new.id
        self.isOffline = !monitor.isConnected

        self.monitor.onChange = { [weak self] connected in
            Task { @MainActor in
                guard let self else { return }
                self.isOffline = !connected
                if connected, self.isShowingCachedData {
                    await self.refreshFromNetwork()
                }
            }
        }
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

    var loadedCatalog: ProductCatalog? {
        if case let .loaded(catalog) = state { return catalog }
        return nil
    }

    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    func load() async {
        if let cached = await cache.load(), !cached.items.isEmpty {
            apply(cached)
            isShowingCachedData = true
        } else {
            state = .loading
        }

        if !monitor.isConnected {
            if case .loaded = state {
                isOffline = true
                return
            } else {
                state = .failed("Нет подключения к сети.")
                return
            }
        }

        await refreshFromNetwork()
    }

    private func refreshFromNetwork() async {
        do {
            let fresh = try await repository.loadCatalog()
            await cache.save(fresh)
            apply(fresh)
            isShowingCachedData = false
        } catch is CancellationError {
        } catch {
            if case .loaded = state {
                isShowingCachedData = true
            } else {
                state = .failed(error.localizedDescription)
            }
        }
    }

    private func apply(_ catalog: ProductCatalog) {
        let validCategoryIds = Set(catalog.categories.map(\.id) + [ProductCategory.new.id])
        if !validCategoryIds.contains(selectedCategoryId) {
            selectedCategoryId = ProductCategory.new.id
        }
        state = .loaded(catalog)
    }
}
