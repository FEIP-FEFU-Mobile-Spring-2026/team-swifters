import SwiftUI

struct CartView: View {
    @ObservedObject var cart: CartViewModel
    let catalog: ProductCatalog?
    var onGoHome: () -> Void = {}

    @State private var name = ""
    @State private var email = ""
    @State private var comment = ""
    @State private var showClearConfirmation = false

    private var resolved: [ResolvedCartItem] { cart.resolvedItems(using: catalog) }

    var body: some View {
        NavigationStack {
            Group {
                if resolved.isEmpty {
                    emptyState
                } else {
                    filledContent
                }
            }
            .navigationTitle("Корзина")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !resolved.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showClearConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.brandBrown)
                        }
                        .accessibilityLabel("Очистить корзину")
                    }
                }
            }
            .background(Color.catalogBackground)
        }
        .confirmationDialog(
            "Очистить корзину?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Очистить", role: .destructive) { cart.clear() }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Все товары будут удалены из корзины.")
        }
        .sheet(isPresented: $cart.showOrderSuccess) {
            OrderSuccessView {
                cart.showOrderSuccess = false
                name = ""
                email = ""
                comment = ""
                onGoHome()
            }
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "cart")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Color.brandBrown)
            Text("Корзина пока пуста")
                .font(.title3.bold())
            Text("Добавленные товары появятся здесь")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.catalogBackground)
    }

    private var filledContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(resolved) { item in
                    CartRow(
                        item: item,
                        onIncrement: { cart.increment(item) },
                        onDecrement: { cart.decrement(item) },
                        onRemove: { cart.remove(item) }
                    )
                }

                orderForm

                HStack {
                    Text("Итого")
                        .font(.headline)
                    Spacer()
                    Text(cart.formattedTotal(using: catalog))
                        .font(.title3.bold())
                        .foregroundStyle(Color.brandBrown)
                }
                .padding(.top, 6)

                Button("Оформить") {
                    cart.placeOrder(name: name, email: email, comment: comment)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!cart.canPlaceOrder(name: name, email: email))
                .opacity(cart.canPlaceOrder(name: name, email: email) ? 1 : 0.5)
            }
            .padding(16)
        }
    }

    private var orderForm: some View {
        VStack(spacing: 10) {
            CartTextField(title: "Имя*", text: $name)
            CartTextField(title: "Почта*", text: $email, keyboard: .emailAddress)
            CartTextField(title: "Комментарий к заказу", text: $comment, multiline: true)
        }
        .padding(.top, 10)
    }
}

private struct CartRow: View {
    let item: ResolvedCartItem
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProductImage(imageUrl: item.product.imageUrl)
                .frame(width: 66, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top, spacing: 8) {
                    Text(item.product.name)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Удалить позицию")
                }

                Text(item.sizeName)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                HStack {
                    Text(item.formattedLinePrice)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.brandBrown)
                    Spacer()
                    QuantityStepper(
                        quantity: item.quantity,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        )
    }
}

private struct QuantityStepper: View {
    let quantity: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onDecrement) {
                Image(systemName: "minus")
            }
            .accessibilityLabel("Уменьшить количество")

            Text("\(quantity)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(minWidth: 18)

            Button(action: onIncrement) {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Увеличить количество")
        }
        .font(.system(size: 13, weight: .bold))
        .foregroundStyle(Color.brandBrown)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(Capsule().fill(Color.priceBackground))
        .buttonStyle(.plain)
    }
}

private struct CartTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var multiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            if multiline {
                TextField("", text: $text, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            } else {
                TextField("", text: $text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(keyboard == .emailAddress ? .never : .sentences)
                    .autocorrectionDisabled(keyboard == .emailAddress)
            }
        }
        .font(.system(size: 15))
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
        )
    }
}

private struct OrderSuccessView: View {
    let onGoHome: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 66, weight: .light))
                .foregroundStyle(Color.brandBrown)

            Text("Заказ успешно оформлен")
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            Text("Подтверждение и чек отправили на вашу почту")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Вернуться на главную", action: onGoHome)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.catalogBackground)
    }
}