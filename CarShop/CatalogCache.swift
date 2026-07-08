import Foundation
import CoreData

protocol CatalogCaching {
    func load() async -> ProductCatalog?
    func save(_ catalog: ProductCatalog) async
}

private let tagSeparator = "\u{1}"

final class CatalogCache: CatalogCaching {
    static let shared = CatalogCache()

    let container: NSPersistentContainer

    init() {
        let model = CatalogCache.makeModel()
        container = NSPersistentContainer(name: "CatalogCache", managedObjectModel: model)

        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores { _, error in
            if let error {
                print("CoreData: не удалось загрузить хранилище — \(error)")
            }
        }
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let category = entity(name: "CDCategory", attributes: [
            ("id", .stringAttributeType),
            ("name", .stringAttributeType)
        ])

        let product = entity(name: "CDProduct", attributes: [
            ("id", .stringAttributeType),
            ("name", .stringAttributeType),
            ("shortDescription", .stringAttributeType),
            ("longDescription", .stringAttributeType),
            ("priceInKopecks", .integer64AttributeType),
            ("imageUrl", .stringAttributeType),
            ("tagsJoined", .stringAttributeType),
            ("categoryId", .stringAttributeType),
            ("material", .stringAttributeType),
            ("weight", .stringAttributeType),
            ("season", .stringAttributeType),
            ("countryOfOrigin", .stringAttributeType)
        ])

        let size = entity(name: "CDSize", attributes: [
            ("id", .stringAttributeType),
            ("name", .stringAttributeType),
            ("productId", .stringAttributeType),
            ("sortIndex", .integer64AttributeType)
        ])

        let cartItem = entity(name: "CDCartItem", attributes: [
            ("productId", .stringAttributeType),
            ("sizeId", .stringAttributeType),
            ("quantity", .integer64AttributeType)
        ])

        model.entities = [category, product, size, cartItem]
        return model
    }

    private static func entity(
        name: String,
        attributes: [(String, NSAttributeType)]
    ) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = name
        entity.managedObjectClassName = "NSManagedObject"
        entity.properties = attributes.map { attrName, type in
            let attribute = NSAttributeDescription()
            attribute.name = attrName
            attribute.attributeType = type
            attribute.isOptional = true
            return attribute
        }
        return entity
    }

    func load() async -> ProductCatalog? {
        await withCheckedContinuation { continuation in
            let context = container.newBackgroundContext()
            context.perform {
                let categoryRequest = NSFetchRequest<NSManagedObject>(entityName: "CDCategory")
                let productRequest = NSFetchRequest<NSManagedObject>(entityName: "CDProduct")
                let sizeRequest = NSFetchRequest<NSManagedObject>(entityName: "CDSize")

                guard
                    let categoryRows = try? context.fetch(categoryRequest),
                    let productRows = try? context.fetch(productRequest),
                    let sizeRows = try? context.fetch(sizeRequest),
                    !productRows.isEmpty
                else {
                    continuation.resume(returning: nil)
                    return
                }

                var sizesByProduct: [String: [(sortIndex: Int, size: ProductSize)]] = [:]
                for row in sizeRows {
                    let productId = row.value(forKey: "productId") as? String ?? ""
                    let sortIndex = Int(row.value(forKey: "sortIndex") as? Int64 ?? 0)
                    let size = ProductSize(
                        id: row.value(forKey: "id") as? String ?? "",
                        name: row.value(forKey: "name") as? String ?? ""
                    )
                    sizesByProduct[productId, default: []].append((sortIndex, size))
                }

                let categories = categoryRows.map { row in
                    ProductCategory(
                        id: row.value(forKey: "id") as? String ?? "",
                        name: row.value(forKey: "name") as? String ?? ""
                    )
                }

                let products = productRows.map { row -> Product in
                    let productId = row.value(forKey: "id") as? String ?? ""
                    let tagsJoined = row.value(forKey: "tagsJoined") as? String ?? ""
                    let tags = tagsJoined.isEmpty ? [] : tagsJoined.components(separatedBy: tagSeparator)
                    let sizes = (sizesByProduct[productId] ?? [])
                        .sorted { $0.sortIndex < $1.sortIndex }
                        .map(\.size)

                    return Product(
                        id: productId,
                        name: row.value(forKey: "name") as? String ?? "",
                        shortDescription: row.value(forKey: "shortDescription") as? String ?? "",
                        longDescription: row.value(forKey: "longDescription") as? String ?? "",
                        priceInKopecks: Int(row.value(forKey: "priceInKopecks") as? Int64 ?? 0),
                        imageUrl: row.value(forKey: "imageUrl") as? String ?? "",
                        tags: tags,
                        categoryId: row.value(forKey: "categoryId") as? String ?? "",
                        sizes: sizes,
                        material: row.value(forKey: "material") as? String ?? "",
                        weight: row.value(forKey: "weight") as? String ?? "",
                        season: row.value(forKey: "season") as? String ?? "",
                        countryOfOrigin: row.value(forKey: "countryOfOrigin") as? String ?? ""
                    )
                }

                continuation.resume(returning: ProductCatalog(categories: categories, items: products))
            }
        }
    }

    func save(_ catalog: ProductCatalog) async {
        await withCheckedContinuation { continuation in
            let context = container.newBackgroundContext()
            context.perform {
                for entityName in ["CDCategory", "CDProduct", "CDSize"] {
                    let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                    let delete = NSBatchDeleteRequest(fetchRequest: fetch)
                    _ = try? context.execute(delete)
                }

                for category in catalog.categories {
                    let row = NSEntityDescription.insertNewObject(forEntityName: "CDCategory", into: context)
                    row.setValue(category.id, forKey: "id")
                    row.setValue(category.name, forKey: "name")
                }

                for product in catalog.items {
                    let row = NSEntityDescription.insertNewObject(forEntityName: "CDProduct", into: context)
                    row.setValue(product.id, forKey: "id")
                    row.setValue(product.name, forKey: "name")
                    row.setValue(product.shortDescription, forKey: "shortDescription")
                    row.setValue(product.longDescription, forKey: "longDescription")
                    row.setValue(Int64(product.priceInKopecks), forKey: "priceInKopecks")
                    row.setValue(product.imageUrl, forKey: "imageUrl")
                    row.setValue(product.tags.joined(separator: tagSeparator), forKey: "tagsJoined")
                    row.setValue(product.categoryId, forKey: "categoryId")
                    row.setValue(product.material, forKey: "material")
                    row.setValue(product.weight, forKey: "weight")
                    row.setValue(product.season, forKey: "season")
                    row.setValue(product.countryOfOrigin, forKey: "countryOfOrigin")

                    for (index, size) in product.sizes.enumerated() {
                        let sizeRow = NSEntityDescription.insertNewObject(forEntityName: "CDSize", into: context)
                        sizeRow.setValue(size.id, forKey: "id")
                        sizeRow.setValue(size.name, forKey: "name")
                        sizeRow.setValue(product.id, forKey: "productId")
                        sizeRow.setValue(Int64(index), forKey: "sortIndex")
                    }
                }

                try? context.save()
                continuation.resume()
            }
        }
    }
}