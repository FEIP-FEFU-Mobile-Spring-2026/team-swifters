import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @ObservedObject var cart: CartViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSize: ProductSize?
    @State private var isShowingDetails = false

    init(product: Product, cart: CartViewModel) {
        self.product = product
        self.cart = cart
        _selectedSize = State(initialValue: product.sizes.first)
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
                        Text("Размер")
                            .font(.headline)

                        sizePicker
                    }

                    HStack {
                        Text(product.formattedPrice)
                            .font(.title2.bold())
                            .foregroundStyle(Color.brandBrown)

                        Spacer()

                        if let selectedSize {
                            Text(selectedSize.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("В корзину") {
                        guard let selectedSize else { return }
                        cart.add(product: product, sizeId: selectedSize.id)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(selectedSize == nil)
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
                Материал: \(product.material)
                Вес: \(product.weight)
                Сезон: \(product.season)
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

    private var sizePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(product.sizes) { size in
                    Button {
                        selectedSize = size
                    } label: {
                        Text(size.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedSize == size ? .white : .primary)
                            .padding(.horizontal, 18)
                            .frame(minWidth: 52, minHeight: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        selectedSize == size
                                            ? Color.brandBrown
                                            : Color.tabBackground
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedSize == size ? .isSelected : [])
                }
            }
        }
    }
}
