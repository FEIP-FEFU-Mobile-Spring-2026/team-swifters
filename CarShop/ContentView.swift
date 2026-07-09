import SwiftUI

private enum AppTab: String {
    case catalog
    case cart
}

struct ContentView: View {
    @StateObject private var viewModel: CatalogViewModel
    @StateObject private var cartViewModel = CartViewModel()
    @AppStorage("app.selectedTab") private var selectedTabRawValue = AppTab.catalog.rawValue

    init(repository: any ProductRepository = RemoteProductRepository()) {
        _viewModel = StateObject(wrappedValue: CatalogViewModel(repository: repository))
    }

    private var selectedTab: AppTab {
        AppTab(rawValue: selectedTabRawValue) ?? .catalog
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isOffline {
                OfflineBanner()
            }

            Group {
                switch selectedTab {
                case .catalog:
                    CatalogScreen(viewModel: viewModel, cart: cartViewModel)
                case .cart:
                    CartView(
                        cart: cartViewModel,
                        catalog: viewModel.loadedCatalog,
                        onGoHome: { selectedTabRawValue = AppTab.catalog.rawValue }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            BottomNavigation(
                selectedTabRawValue: $selectedTabRawValue,
                cartBadge: cartViewModel.badgeCount
            )
        }
        .background(Color.catalogBackground)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isOffline)
        .task {
            await viewModel.loadIfNeeded()
        }
    }
}

private struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 13, weight: .semibold))
            Text("Нет сети")
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(red: 0.72, green: 0.45, blue: 0.20))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

private struct CatalogScreen: View {
    @ObservedObject var viewModel: CatalogViewModel
    @ObservedObject var cart: CartViewModel
    @State private var selectedProduct: Product?

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    LoadingView()
                case let .failed(message):
                    CatalogErrorView(message: message) {
                        Task { await viewModel.load() }
                    }
                case .loaded:
                    catalogContent
                }
            }
            .navigationTitle("Каталог")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.catalogBackground)
        }
        .sheet(item: $selectedProduct) { product in
            ProductDetailView(product: product, cart: cart)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
    }

    private var catalogContent: some View {
        VStack(spacing: 0) {
            CategoryTabs(
                categories: viewModel.categories,
                selectedCategoryId: $viewModel.selectedCategoryId
            )

            Divider()
                .overlay(Color.black.opacity(0.06))

            if viewModel.visibleProducts.isEmpty {
                ContentUnavailableView(
                    "В этой категории пока пусто",
                    systemImage: "square.grid.2x2",
                    description: Text("Выберите другую категорию")
                )
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.visibleProducts) { product in
                            Button {
                                selectedProduct = product
                            } label: {
                                ProductCard(product: product)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

private struct CategoryTabs: View {
    let categories: [ProductCategory]
    @Binding var selectedCategoryId: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories) { category in
                    Button {
                        selectedCategoryId = category.id
                    } label: {
                        Text(category.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(selectedCategoryId == category.id ? .white : .primary)
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .background(
                                Capsule()
                                    .fill(selectedCategoryId == category.id ? Color.brandBrown : Color.tabBackground)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedCategoryId == category.id ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.white)
    }
}

private struct ProductCard: View {
    let product: Product

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ProductImage(imageUrl: product.imageUrl)
                .frame(width: 126, height: 126)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text(product.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(product.shortDescription)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                Spacer(minLength: 0)

                Text(product.formattedPrice)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.brandBrown)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.priceBackground)
                    )
            }
            .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        )
        .contentShape(Rectangle())
    }
}

struct ProductImage: View {
    let imageUrl: String

    var body: some View {
        if imageUrl.hasPrefix("asset://") {
            let assetName = String(imageUrl.dropFirst("asset://".count))
            Image(assetName)
                .resizable()
                .scaledToFill()
        } else if let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().scaledToFill()
                case .failure:
                    imagePlaceholder(systemName: "exclamationmark.triangle")
                case .empty:
                    ZStack {
                        Color.tabBackground
                        ProgressView().tint(Color.brandBrown)
                    }
                @unknown default:
                    imagePlaceholder(systemName: "photo")
                }
            }
        } else {
            imagePlaceholder(systemName: "photo")
        }
    }

    private func imagePlaceholder(systemName: String) -> some View {
        ZStack {
            Color.tabBackground
            Image(systemName: systemName)
                .font(.title2)
                .foregroundStyle(Color.brandBrown)
        }
    }
}

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.brandBrown)
            Text("Загружаем каталог…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.catalogBackground)
        .accessibilityElement(children: .combine)
    }
}

private struct CatalogErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 54))
                .foregroundStyle(Color.brandBrown)

            Text("Произошла ошибка")
                .font(.title3.bold())

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Повторить загрузку", action: retry)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.catalogBackground)
    }
}

private struct BottomNavigation: View {
    @Binding var selectedTabRawValue: String
    let cartBadge: Int

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.catalog, title: "Каталог", systemImage: "square.grid.2x2")
            tabButton(.cart, title: "Корзина", systemImage: "cart", badge: cartBadge)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(.white.shadow(.drop(color: .black.opacity(0.08), radius: 8, y: -2)))
    }

    private func tabButton(
        _ tab: AppTab,
        title: String,
        systemImage: String,
        badge: Int = 0
    ) -> some View {
        let isSelected = selectedTabRawValue == tab.rawValue

        return Button {
            selectedTabRawValue = tab.rawValue
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .frame(width: 28, height: 24)

                    if badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Circle().fill(Color.brandBrown))
                            .offset(x: 10, y: -8)
                    }
                }
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color.brandBrown : Color.secondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.brandBrown.opacity(configuration.isPressed ? 0.8 : 1))
            )
    }
}

extension Color {
    static let brandBrown = Color(red: 0.58, green: 0.40, blue: 0.31)
    static let priceBackground = Color(red: 0.96, green: 0.92, blue: 0.89)
    static let tabBackground = Color(red: 0.94, green: 0.94, blue: 0.94)
    static let catalogBackground = Color(red: 0.975, green: 0.972, blue: 0.968)
}

#Preview {
    ContentView()
}