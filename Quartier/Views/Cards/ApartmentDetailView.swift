//
//  ApartmentDetailView.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-06.
//

import SwiftUI
import MapKit

struct ApartmentDetailView: View {

    let listing: Listing
    @State private var isExpanded = false

    var body: some View {

        ZStack(alignment: .top) {

            headerImage

            ScrollView {

                VStack(spacing: 0) {

                    Spacer()
                        .frame(height: 235)

                    contentCard
                        .padding()

                }.padding()
            }
        }.padding()
    }

    private func infoColumn(value: Int, title: String) -> some View {
        VStack {
            Text("\(value)")
                .font(.subheadline.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private var apartmentCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 45.5019, longitude: -73.5674)
    }

    private var contentCard: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text("$\(listing.price.formatted(.number.precision(.fractionLength(2))))/mo")
                .font(.title.bold())

            Text("Apartment Listing")

            HStack {
                Image(systemName: "location.viewfinder")

                Text(listing.address)
                    .font(.subheadline.italic())
                    .foregroundStyle(.gray)
            }

            Divider()

            HStack(spacing: 0) {

                infoColumn(value: listing.bedrooms, title: "BEDROOMS")

                Divider()
                    .frame(height: 50)

                infoColumn(value: listing.bathrooms, title: "BATH")

                Divider()
                    .frame(height: 50)

                infoColumn(value: 0, title: "SQFT")
            }
            .padding()

            Divider()

            Spacer()
                .frame(height: 20)

            Text("About this place")
                .font(.subheadline.bold())

            Text("This apartment offers a comfortable and well-designed living space with plenty of natural light and a practical layout suited for everyday living. The unit features spacious rooms, modern finishes, and convenient access to nearby shops, public transportation, and local amenities.")
                .lineLimit(isExpanded ? nil : 3)
                .font(.body)
                .foregroundStyle(.gray)

            Button(isExpanded ? "Read less" : "Read more") {
                isExpanded.toggle()
            }
            .font(.caption)
            .foregroundStyle(.blue)

            Spacer()
                .frame(height: 20)

            Text("Amenities")
                .font(.subheadline.bold())

            ForEach(listing.amenities, id: \.self) { amenity in
                Text("• \(amenity)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()
                .frame(height: 20)

            Text("Location")
                .font(.subheadline.bold())

            MapCard(
                coordinate: apartmentCoordinate,
                locationName: listing.address
            )

            Spacer()

            HStack {

                Spacer()

                Button(action: {}) {

                    Text("Contact Landlord")
                        .foregroundStyle(.white)
                        .font(.subheadline.bold())
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                        )
                }

                Spacer()
            }
        }
        .padding()
        .background(.background)
        .clipShape(
            RoundedRectangle(cornerRadius: 34)
        )
        .offset(y: -30)
    }

    private var headerImage: some View {

        Group {

            if let firstImage = listing.existingImageURLs.first,
               let url = URL(string: firstImage) {

                AsyncImage(url: url) { phase in

                    switch phase {

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure(_):
                        Image("apartment1")
                            .resizable()
                            .scaledToFill()

                    case .empty:
                        ProgressView()

                    @unknown default:
                        Image("apartment1")
                            .resizable()
                            .scaledToFill()
                    }
                }

            } else {

                Image("apartment1")
                    .resizable()
                    .scaledToFill()
            }

        }
        .frame(height: 320)
        .clipped()
        .ignoresSafeArea(edges: .top)
    }
}


struct MapCard: View {

    let coordinate: CLLocationCoordinate2D
    let locationName: String

    @State private var region: MKCoordinateRegion

    init(coordinate: CLLocationCoordinate2D,
         locationName: String) {

        self.coordinate = coordinate
        self.locationName = locationName

        _region = State(initialValue:
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01,
                                       longitudeDelta: 0.01)
            )
        )
    }

    var body: some View {

        ZStack(alignment: .bottomLeading) {

            Map(position: .constant(.region(region)))
                .allowsHitTesting(false)

            Text(locationName)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(12)
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.gray.opacity(0.15))
        )
        .shadow(color: .black.opacity(0.08),
                radius: 6, y: 3)
    }
}


#Preview {
    // Construct a mock Listing by decoding JSON, since Listing likely only exposes init(from:)
    let json = """
    {
      "price": 1800,
      "address": "123 Main St, Montreal, QC",
      "bedrooms": 2,
      "bathrooms": 1,
      "amenities": ["Washer/Dryer", "Dishwasher", "Balcony"],
      "existingImageURLs": [
        "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2"
      ]
    }
    """

    let mock: Listing = {
        let data = Data(json.utf8)
        return try! JSONDecoder().decode(Listing.self, from: data)
    }()

    return ApartmentDetailView(listing: mock)
}
