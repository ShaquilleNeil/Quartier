//
//  ApartmentCard.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-03.
//

import SwiftUI

struct ApartmentCard: View {
    @State var imageName: String = "photo.artframe"
    @State var isNew: Bool = true
    @State var rating: Double = 4.7
    @State var beds: Int = 3
    @State var baths: Int = 2
    @State var sqft: Int = 1200
    @State var price: Double = 1500.00
    @State var location: String = "123 Maple St, Springfield, IL 62701"
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

                    // Image section
                    ZStack(alignment: .topLeading) {
                        Image(systemName: imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(16)

                        if isNew {
                            Text("NEW LISTING")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(12)
                        }

                        // Favorite button
                        HStack {
                            Spacer()
                            Button(action: {}) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }
                            .padding(12)
                        }
                    }

                    // Info section
                    VStack(alignment: .leading, spacing: 6) {

                        HStack {
                            Text("$\(price.formatted(.number.precision(.fractionLength(2))))")

                                .font(.title3.bold())
                                .foregroundColor(.blue)

                            Text("/ mo")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text(String(format: "%.1f", rating))
                                    .font(.subheadline.bold())
                            }
                        }

                        Text(location)
                            .font(.headline)

                        HStack(spacing: 14) {
                            Label("\(beds) bed", systemImage: "bed.double")
                            Label("\(baths) bath", systemImage: "bathtub")
                            Label("\(sqft) sqft", systemImage: "ruler")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 14)
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
            }
    }


#Preview {
    ApartmentCard()
}
