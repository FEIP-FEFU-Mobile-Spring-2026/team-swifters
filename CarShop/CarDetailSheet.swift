import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss
    @State private var selectedConfiguration: String?
    @State private var isShowingDetails = false

    init(product: Product) {
        self.product = product
        _selectedConfiguration = State(initialValue: product.configurations.first)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    productImage

                    HStack(alignment: .top, spacing: 12) {
                        Text(product.name)
                            .font(.system(size: 28, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            isShowingDetails = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(Color.brandBrown)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.priceBackground))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Дополнительная информация")
                    }

                    Text(product.longDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Комплектация")
                            .font(.headline)

                        configurationPicker
                    }

                    HStack {
                        Text(product.formattedPrice)
                            .font(.title2.bold())
                            .foregroundStyle(Color.brandBrown)

                        Spacer()

                        if let selectedConfiguration {
                            Text(selectedConfiguration)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("В корзину") { }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Color.catalogBackground)
            .navigationTitle("Детали товара")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.tabBackground))
                    }
                    .accessibilityLabel("Закрыть")
                }
            }
        }
        .alert("Характеристики", isPresented: $isShowingDetails) {
            Button("Понятно", role: .cancel) { }
        } message: {
            Text(
                """
                Двигатель: \(product.engine)
                Вес: \(product.weight)
                Привод: \(product.drivetrain)
                Страна производства: \(product.countryOfOrigin)
                """
            )
        }
    }

    private var productImage: some View {
        ZStack(alignment: .topLeading) {
            ProductImage(imageUrl: product.imageUrl)
                .frame(maxWidth: .infinity)
                .frame(height: 290)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(product.tags, id: \.self) { tag in
                        Text(tag.uppercased())
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.68))
                            )
                    }
                }
                .padding(14)
            }
        }
        .padding(.top, 8)
    }

    private var configurationPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(product.configurations, id: \.self) { configuration in
                    Button {
                        selectedConfiguration = configuration
                    } label: {
                        Text(configuration)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedConfiguration == configuration ? .white : .primary)
                            .padding(.horizontal, 18)
                            .frame(minWidth: 52, minHeight: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        selectedConfiguration == configuration
                                            ? Color.brandBrown
                                            : Color.tabBackground
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(
                        selectedConfiguration == configuration ? .isSelected : []
                    )
                }
            }
        }
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
                categoryId: "cat_hypercars",
                sizes: [
                    ProductSize(id: "chiron", name: "Chiron"),
                    ProductSize(id: "pur_sport", name: "Pur Sport"),
                    ProductSize(id: "super_sport", name: "Super Sport")
                ],
                material: "8,0 л W16, 1 500 л.с.",
                weight: "1 995 кг",
                season: "Полный",
                countryOfOrigin: "Франция"
            )
        )
    }
}
