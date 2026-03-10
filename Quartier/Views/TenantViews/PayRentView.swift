//
//  PayRentView.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-26.
//
import SwiftUI

import SwiftUI

struct PayRentView: View {
    
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 20) {
                    
                    RentSummaryCard()
                    
                    PaymentMethodPreview {
                        path.append(PaymentRoute.methods)
                    }
                    
                    InvoiceBreakdown()
                }
                .padding()
            }
            .navigationTitle("Pay Rent")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                ConfirmPayButton {
                    path.append(PaymentRoute.methods)   // 👈 flow fix
                }
            }
            .navigationDestination(for: PaymentRoute.self) { route in
                switch route {
                case .methods:
                    PaymentMethodsView()
                    
                    
                case .addCard:
                    AddCardView()
                }
            }
        }
    }
}

#Preview {
    PayRentView()
}

struct RentSummaryCard: View {
    var body: some View {
        VStack(spacing: 0) {
            Image("apartment1")
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .clipped()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("TOTAL DUE")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("$2,450.00")
                    .font(.largeTitle.bold())
                    .foregroundColor(.red)
                
                Text("Payment due by October 1st")
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .background(.white)
        .cornerRadius(16)
    }
}

struct PaymentMethodPreview: View {
    var tap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Method")
                .font(.title3.bold())
            
            Button(action: tap) {
                HStack {
                    Image(systemName: "creditcard")
                    VStack(alignment: .leading) {
                        Text("Visa **** 1234")
                        Text("Expires 12/26").font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.red)
                }
                .padding()
                .background(.white)
                .cornerRadius(12)
            }
        }
    }
}


struct InvoiceBreakdown: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Invoice Breakdown")
                .font(.title3.bold())
            
            VStack {
                BreakdownRow("Monthly Rent", "$2,200")
                Divider()
                BreakdownRow("Utilities", "$185")
                Divider()
                BreakdownRow("Maintenance", "$65")
                Divider()
                BreakdownRow("Total", "$2,450", highlight: true)
            }
            .padding()
            .background(.white)
            .cornerRadius(16)
        }
    }
}

struct BreakdownRow: View {
    let title: String
    let value: String
    var highlight: Bool = false
    
    init(_ t: String,_ v: String, highlight: Bool = false) {
        title = t
        value = v
        self.highlight = highlight
    }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(highlight ? .red : .primary)
        }
    }
}

struct ConfirmPayButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Confirm & Pay $2,450")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(14)
                .padding()
        }
        .background(.ultraThinMaterial)
    }
}

