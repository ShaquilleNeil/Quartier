import SwiftUI

struct PaymentCard: Identifiable {
    let id = UUID()
    let brand: String
    let last4: String
    let holder: String
    let expiry: String
}

struct PaymentMethodsView: View {
    
    @State private var selectedID: UUID?
    @State private var showingAddCard = false
    
    let cards: [PaymentCard] = [
        .init(brand: "Visa", last4: "1234", holder: "Shaquille Neil", expiry: "12/26"),
        .init(brand: "Mastercard", last4: "4321", holder: "Shaquille Neil", expiry: "03/27")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            
            ScrollView {
                VStack(spacing: 16) {
                    
                    ForEach(cards) { (card: PaymentCard) in
                        PaymentMethodRow(
                            card: card,
                            isSelected: selectedID == card.id
                        ) {
                            selectedID = card.id
                        }
                    }
                    
                    Button {
                       showingAddCard = true
                    } label: {
                        Label("Add new card", systemImage: "plus")
                            .font(.headline)
                    }
                    .padding(.top, 8)
                    .sheet(isPresented: $showingAddCard) {
                        // Replace AddCardViewPlaceholder with AddCardView if you have it in your project
                        AddCardView()
                    }
                }
                .padding()
            }
            
            ContinueButton(enabled: selectedID != nil) {
                // continue to payment step
            }
        }
        .navigationTitle("Payment Methods")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGray6))
    }
}


private struct PaymentMethodRow: View {
    
    let card: PaymentCard
    let isSelected: Bool
    let tap: () -> Void
    
    var body: some View {
        Button(action: tap) {
            HStack {
                Image(systemName: "creditcard")
                
                VStack(alignment: .leading) {
                    Text("\(card.brand) **** \(card.last4)")
                    Text("Expires \(card.expiry)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .red : .gray)
            }
            .padding()
            .background(.white)
            .cornerRadius(14)
        }
    }
}


private struct ContinueButton: View {
    
    let enabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(enabled ? Color.red : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(14)
                .padding()
        }
        .disabled(!enabled)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    NavigationStack { PaymentMethodsView() }
}
