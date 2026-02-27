import SwiftUI

struct AddCardView: View {
    
    @State private var nameOnCard = ""
    @State private var cardNumber = ""
    @State private var expiry = ""
    @State private var cvv = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                CreditCardPreview(
                    name: nameOnCard,
                    number: cardNumber,
                    expiry: expiry
                )
                
                VStack(spacing: 16) {
                    CardTextField(title: "Name on card", text: $nameOnCard)
                    
                    CardTextField(
                        title: "Card number",
                        text: $cardNumber,
                        keyboard: .numberPad
                    )
                    
                    HStack(spacing: 12) {
                        CardTextField(
                            title: "MM/YY",
                            text: $expiry,
                            keyboard: .numbersAndPunctuation
                        )
                        
                        CardTextField(
                            title: "CVV",
                            text: $cvv,
                            keyboard: .numberPad
                        )
                    }
                }
                
                Button {
                    // TODO Stripe attach payment method
                } label: {
                    Text("Add Card")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
            }
            .padding()
        }
        .navigationTitle("Add Card")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGray6))
    }
}


private struct CreditCardPreview: View {
    let name: String
    let number: String
    let expiry: String
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.black, .gray],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(number.isEmpty ? "**** **** **** ****" : number)
                    .font(.title2.monospacedDigit())
                    .foregroundColor(.white)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("CARD HOLDER")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(name.isEmpty ? "Your Name" : name)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("EXPIRES")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(expiry.isEmpty ? "MM/YY" : expiry)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
    }
}

private struct CardTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            TextField("", text: $text)
                .keyboardType(keyboard)
                .padding()
                .background(.white)
                .cornerRadius(12)
        }
    }
}

#Preview {
    NavigationStack { AddCardView() }
}
