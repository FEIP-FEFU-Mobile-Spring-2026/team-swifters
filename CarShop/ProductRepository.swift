import Foundation

protocol ProductRepository {
    func loadCatalog() async throws -> ProductCatalog
}
