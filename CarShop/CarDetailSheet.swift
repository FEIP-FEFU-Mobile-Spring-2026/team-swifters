import SwiftUI

struct ProductDetailView: View {
    let product: Product

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProductImage(imageUrl: product.imageUrl)
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                if product.tags.contains("New") {
                    Text("NEW")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .frame(height: 26)
                        .background(Capsule().fill(Color.brandBrown))
                }

                Text(product.name)
                    .font(.largeTitle.bold())

                Text(product.longDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text(product.formattedPrice)
                    .font(.title3.bold())
                    .foregroundStyle(Color.brandBrown)

                Button("Добавить в корзину") { }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Color.catalogBackground)
        .navigationTitle("Автомобиль")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(
            product: Product(
                id: "preview",
                name: "Bugatti Chiron",
                shortDescription: "Гиперкар с двигателем W16",
                longDescription: "Сочетание динамики, роскоши и инженерного искусства.",
                priceInKopecks: 35_000_000_000,
                imageUrl: "asset://buga",
                tags: ["New"],
                categoryId: "cat_hypercars"
            )
        )
    }
}
