import SwiftUI

struct CarDetailSheet: View {
    let car: Car
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 16) {
                HStack {
                    Text("NEW")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.5, green: 0.3, blue: 0.2))
                        )
                        .padding(.leading, 16)

                    Spacer()
                }
                .padding(.top, 12)

                Image(car.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 300)
                    .clipped()
                    .cornerRadius(12)
                    .padding(.horizontal)

                HStack {
                    Text(car.name)
                        .font(.title.bold())
                        .padding(.horizontal)

                    Spacer()

                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding(.trailing, 16)
                }

                Text("""
                    Bugatti Chiron — это не просто автомобиль, это произведение искусства инженерии.  
                    С его 8-литровым W16 двигателем мощностью 1500 л.с., он способен разгоняться до 400 км/ч за считанные секунды.  
                    
                    """)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 16)

                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 1)
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Цвет:")
                        .font(.headline)
                        .padding(.horizontal)

                    HStack(spacing: 8) {
                        ForEach(car.colors, id: \.id) { colorOption in
                            let isBlack = colorOption.name == "Черный"
                            let backgroundColor = isBlack ? Color(red: 0.5, green: 0.3, blue: 0.2) : Color.gray.opacity(0.1)
                            let textColor = isBlack ? Color.white : Color.black

                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(backgroundColor)

                                Text(colorOption.name)
                                    .font(.caption)
                                    .foregroundColor(textColor)
                                    .padding(.horizontal, 12)
                            }
                            .frame(height: 44)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.horizontal)

            VStack {
                Spacer()
                Text("В корзину — \(car.price)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.5, green: 0.3, blue: 0.2))
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

struct CarDetailSheet_Previews: PreviewProvider {
    static var previews: some View {
        let bugatti = Car(
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
        )

        return CarDetailSheet(car: bugatti)
    }
}
