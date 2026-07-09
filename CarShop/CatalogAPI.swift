import Foundation

enum APIConfig {
    static let catalogURL = URL(string: "https://fefu2026spring.deploy.feip.dev/catalog")!
    static let bearerToken = "Cmt7wdwFgDIi1_SRX8hlJIExs0jJKPr4axflLpExAxM"
}

enum APIError: LocalizedError {
    case invalidResponse
    case badStatus(Int)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Некорректный ответ сервера."
        case let .badStatus(code):
            return "Сервер вернул ошибку (код \(code))."
        case .decoding:
            return "Не удалось обработать данные каталога."
        }
    }
}

struct RemoteProductRepository: ProductRepository {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func loadCatalog() async throws -> ProductCatalog {
        var request = URLRequest(url: APIConfig.catalogURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIConfig.bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.badStatus(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(ProductCatalog.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}