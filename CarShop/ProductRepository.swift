import Foundation

protocol ProductRepository {
    func loadCatalog() async throws -> ProductCatalog
}

enum ProductRepositoryError: LocalizedError {
    case fileNotFound
    case unreadableData

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Не удалось найти каталог автомобилей."
        case .unreadableData:
            return "Не удалось прочитать данные каталога."
        }
    }
}

struct LocalProductRepository: ProductRepository {
    private let bundle: Bundle
    private let decoder: JSONDecoder

    init(bundle: Bundle = .main, decoder: JSONDecoder = JSONDecoder()) {
        self.bundle = bundle
        self.decoder = decoder
    }

    func loadCatalog() async throws -> ProductCatalog {
        // Небольшая задержка делает состояние загрузки видимым и имитирует реальный источник данных.
        try await Task.sleep(nanoseconds: 1_200_000_000)

        guard let url = bundle.url(forResource: "products", withExtension: "json") else {
            throw ProductRepositoryError.fileNotFound
        }

        guard let data = try? Data(contentsOf: url) else {
            throw ProductRepositoryError.unreadableData
        }

        return try decoder.decode(ProductCatalog.self, from: data)
    }
}
