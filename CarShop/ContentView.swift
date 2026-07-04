import SwiftUI

struct Car: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let price: String
    let imageName: String
    let colors: [ColorOption]

    struct ColorOption: Identifiable {
        let id = UUID()
        let name: String
        let color: Color
    }
}

struct ContentView: View {
    @State private var quantity2 = 1
    @State private var showCarDetail = false

    let cars: [Car] = [
        Car(
            name: "Bugatti Chiron",
            description: "Суперкар с максимальной скоростью 420 км/ч и двигателем 1500 л.с.",
            price: "$3 500 000",
            imageName: "buga",
            colors: [
                .init(name: "Черный", color: .black),
                .init(name: "Белый", color: .white),
                .init(name: "Красный", color: .red),
                .init(name: "Желтый", color: .yellow)
            ]
        ),
        Car(
            name: "Aston Martin DB12",
            description: "Элегантный спорткар с роскошным интерьером и V8 двигателем.",
            price: "$250 000",
            imageName: "astonMartin",
            colors: []
        ),
        Car(
            name: "Lamborghini Huracán",
            description: "Агрессивный дизайн, полный привод и 640 л.с. — чистая страсть на дороге.",
            price: "$280 000",
            imageName: "lamba",
            colors: []
        ),
        Car(
            name: "Maserati MC20",
            description: "Итальянская элегантность и мощь в одном автомобиле с двигателем Nettuno.",
            price: "$220 000",
            imageName: "maser",
            colors: []
        )
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Категории
                HStack(spacing: 8) {
                    ForEach(["Новинки", "SportCar", "Limited"], id: \.self) { item in
                        Text(item)
                            .font(.callout)
                            .foregroundColor(item == "Новинки" ? .white : .black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(item == "Новинки" ? Color(red: 0.5, green: 0.3, blue: 0.2) : Color(red: 0.9, green: 0.9, blue: 0.9))
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .background(Color.white)

                Spacer().frame(height: 8)

                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 1)
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                    .padding(.horizontal)

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 6) {
                        ForEach(cars.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 16) {
                                Image(cars[index].imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .clipped()

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(cars[index].name)
                                        .font(.title2)
                                        .fontWeight(.medium)

                                    Text(cars[index].description)
                                        .font(.body)
                                        .foregroundColor(.secondary)

                                    if index == 1 {
                                        HStack(spacing: 8) {
                                            Button(action: {
                                                if quantity2 > 1 { quantity2 -= 1 }
                                            }) {
                                                Text("-")
                                                    .font(.headline)
                                                    .foregroundColor(.black)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 8)
                                            }
                                            .buttonStyle(PlainButtonStyle())

                                            Text("\(quantity2)")
                                                .font(.headline)
                                                .foregroundColor(Color(red: 0.5, green: 0.3, blue: 0.2))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 8)

                                            Button(action: { quantity2 += 1 }) {
                                                Text("+")
                                                    .font(.headline)
                                                    .foregroundColor(.black)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 8)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(red: 0.9, green: 0.9, blue: 0.9))
                                        )
                                    } else {
                                        Text(cars[index].price)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color(red: 0.5, green: 0.3, blue: 0.2))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(red: 0.95, green: 0.9, blue: 0.85))
                                            )
                                    }
                                }
                                .padding(.trailing, 10)
                            }
                            .padding(.horizontal)
                            .id(index)
                            .frame(height: index == 3 ? 120 : 170)
                            .clipped()
                            .onTapGesture {
                                if index == 0 {
                                    showCarDetail = true
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, -8)
                }
                .background(Color.white)

                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 1)
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                    .padding(.horizontal)

                HStack(spacing: 50) {
                    VStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                            .foregroundColor(.black)
                        Text("Меню")
                            .font(.caption)
                            .foregroundColor(.black)
                    }

                    VStack(spacing: 4) {
                        Image(systemName: "cart")
                            .font(.title2)
                            .foregroundColor(.black)
                        Text("Корзина")
                            .font(.caption)
                            .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .shadow(radius: 3)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCarDetail) {
                CarDetailSheet(car: cars[0])
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
