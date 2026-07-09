import Foundation
import CoreData

protocol CartCaching {
    func load() async -> [StoredCartItem]
    func save(_ items: [StoredCartItem]) async
}

final class CartStore: CartCaching {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer = CatalogCache.shared.container) {
        self.container = container
    }

    func load() async -> [StoredCartItem] {
        await withCheckedContinuation { continuation in
            let context = container.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<NSManagedObject>(entityName: "CDCartItem")
                let rows = (try? context.fetch(request)) ?? []
                let items = rows.map { row in
                    StoredCartItem(
                        productId: row.value(forKey: "productId") as? String ?? "",
                        sizeId: row.value(forKey: "sizeId") as? String ?? "",
                        quantity: Int(row.value(forKey: "quantity") as? Int64 ?? 0)
                    )
                }.filter { !$0.productId.isEmpty && $0.quantity > 0 }
                continuation.resume(returning: items)
            }
        }
    }

    func save(_ items: [StoredCartItem]) async {
        await withCheckedContinuation { continuation in
            let context = container.newBackgroundContext()
            context.perform {
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "CDCartItem")
                let delete = NSBatchDeleteRequest(fetchRequest: fetch)
                _ = try? context.execute(delete)

                for item in items {
                    let row = NSEntityDescription.insertNewObject(forEntityName: "CDCartItem", into: context)
                    row.setValue(item.productId, forKey: "productId")
                    row.setValue(item.sizeId, forKey: "sizeId")
                    row.setValue(Int64(item.quantity), forKey: "quantity")
                }

                try? context.save()
                continuation.resume()
            }
        }
    }
}