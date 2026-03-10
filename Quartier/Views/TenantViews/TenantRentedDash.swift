//
//  TenantRentedDash.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-26.
//

import SwiftUI

struct TenantRentedDash: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                HeaderView()
                
                RentStatusCard()
                
                QuickActionsGrid()
                
                UpdatesSection()
            }
            .padding()
        }
        .background(Color(.systemGray6))
    }
}


private struct HeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("QUARTIER")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("Unit 402 • The Mason")
                    .font(.headline)
            }
            
            Spacer()
            
            Image(systemName: "bell.fill")
                .font(.title3)
        }
    }
}

private struct RentStatusCard: View {
    @State private var isPresentingPayRent = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            Image("apartment1") // replace with your asset
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .clipped()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Rent Status")
                            .font(.headline)
                        
                        Text("September 2024")
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("$2,450.00")
                            .font(.title2.bold())
                            .foregroundColor(.red)
                        
                        Text("Due in 3 days")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Button {
                    self.isPresentingPayRent = true
                } label: {
                    Text("Pay Now")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(.white)
        .cornerRadius(16)
        .shadow(radius: 4)
        .sheet(isPresented: $isPresentingPayRent) {
            PayRentView()
        }
    }
}


private struct QuickActionsGrid: View {
    
    let items = [
        ("Maintenance", "wrench"),
        ("Lost Keys", "key"),
        ("Amenities", "calendar"),
        ("Emergency", "exclamationmark.triangle.fill")
    ]
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK ACTIONS")
                .font(.caption)
                .foregroundColor(.gray)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items, id: \.0) { item in
                    QuickActionCard(title: item.0, icon: item.1)
                }
            }
        }
    }
}

private struct QuickActionCard: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 56, height: 56)
                .background(Color(.systemGray5))
                .clipShape(Circle())
            
            Text(title)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(.white)
        .cornerRadius(16)
    }
}

private struct UpdatesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Building Updates")
                    .font(.title3.bold())
                
                Spacer()
                
                Text("View All")
                    .foregroundColor(.red)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    UpdateCard()
                    UpdateCard()
                }
            }
        }
    }
}

private struct UpdateCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ELEVATOR SERVICE")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("Elevator B Maintenance")
                .font(.headline)
            
            Text("Regular inspection scheduled for tomorrow…")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(width: 260)
        .background(.white)
        .cornerRadius(16)
    }
}

#Preview {
    TenantRentedDash()
}

