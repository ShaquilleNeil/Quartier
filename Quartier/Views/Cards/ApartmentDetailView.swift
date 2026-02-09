//
//  ApartmentDetailView.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-06.
//

import SwiftUI
import MapKit

struct ApartmentDetailView: View {
    @State var imageName: String = "photo.artframe"
    @State var isNew: Bool = true
    @State var rating: Double = 4.7
    @State var beds: Int = 3
    @State var baths: Int = 2
    @State var sqft: Int = 1200
    @State var price: Double = 1500.00
    @State var location: String = "123 Maple St, Springfield, IL 62701"
    @State var isExpanded: Bool = false
    var body: some View {
        ZStack(alignment: .top) {

               headerImage
               

               ScrollView {

                   VStack(spacing: 0) {

                       // pushes content below image
                       Spacer()
                           .frame(height: 235)

                       contentCard
                    
                          
                           
                   }.padding()
               }.padding()
        }
     
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
        // Default to a coordinate in Downtown Montreal
        CLLocationCoordinate2D(latitude: 45.5019, longitude: -73.5674)
    }
    
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 10){
            
            
            Text("$\(price.formatted(.number.precision(.fractionLength(2))))/mo")
                .font(Font.title.bold())
            Text("Modern Loft in Downtown Montreal")
            HStack{
                Image(systemName: "location.viewfinder")
                Text(location)
                    .font(Font.subheadline.italic())
                    .foregroundStyle(Color.gray)
            }
            
            Divider()
            HStack(spacing: 0) {

                infoColumn(value: beds, title: "BEDROOMS")

                Divider()
                    .frame(height: 50)

                infoColumn(value: baths, title: "BATH")

                Divider()
                    .frame(height: 50)

                infoColumn(value: sqft, title: "SQFT")
            }
            .padding()

            Divider()
            Spacer()
                .frame(height: 20)
            
            Text("About this place")
                .font(Font.subheadline.bold())
            
            Text("This apartment offers a comfortable and well-designed living space with plenty of natural light and a practical layout suited for everyday living. The unit features spacious rooms, modern finishes, and convenient access to nearby shops, public transportation, and local amenities. Ideal for individuals or small families looking for a balanced combination of comfort, functionality, and location.")
                .lineLimit(isExpanded ? nil : 3)
                .font(Font.body)
                .foregroundStyle(Color(.gray))
            
            Button(isExpanded ? "Read less" : "Read more") {
                   isExpanded.toggle()
               }
               .font(.caption)
               .foregroundStyle(.blue)
            
            Spacer()
                .frame(height: 20)
            HStack{
                Text("Amenities")
                    .font(Font.subheadline.bold())
                
                Spacer()
                
                Button(action: {}) {
                    Text("view all")
                }
            }
            Spacer()
                .frame(height: 10)
            
            HStack{
                Spacer()
                    .frame(width: 20)
               
                VStack{
                    Image(systemName: "wifi")
                        .foregroundStyle(Color(.blue))
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.blue).opacity(0.1))
                                .frame(width: 40, height: 40)
                        )
                    Spacer()
                        .frame(height: 20)
                    Text("Free Wi-Fi")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
               
                VStack{
                    Image(systemName: "snowflake.circle")
                        .foregroundStyle(Color(.blue))
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.blue).opacity(0.1))
                                .frame(width: 40, height: 40)
                        )
                    Spacer()
                        .frame(height: 20)
                    Text("AC")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                
                VStack{
                    Image(systemName: "dumbbell")
                        .foregroundStyle(Color(.blue))
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.blue).opacity(0.1))
                                .frame(width: 40, height: 40)
                        )
                    Spacer()
                        .frame(height: 20)
                    Text("Gym")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                
                VStack{
                    Image(systemName: "washer")
                        .foregroundStyle(Color(.blue))
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.blue).opacity(0.1))
                                .frame(width: 40, height: 40)
                        )
                    Spacer()
                        .frame(height: 20)
                    Text("Laundry")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                    .frame(width: 20)
             
            }
            
            HStack{
                Image(systemName: "person.fill")
                    .clipped()
                    .background(
                        Circle()
                            .fill(Color(.gray).opacity(0.2))
                            .frame(width: 40, height: 40)
                    )
                Spacer()
                    .frame(width: 20)
                Text("George Games")
                Spacer()
                Button(action: {}){
                    Text("View Profile")
                        .font(Font.caption.bold())
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.gray.opacity(0.2))
                                .frame(width: 95, height: 30)
                            
                        )
                }
            }.padding()
            
            Spacer()
                .frame(height:20)
            Text("Location")
                .font(Font.subheadline.bold())
            
           MapCard(
               coordinate: apartmentCoordinate,
               locationName: location
           )
            
            Spacer()
            
            
            HStack{
                Spacer()
                Button(action: {}){
                    Text("Contact Landlord")
                        .foregroundStyle(Color.white)
                        .font(Font.subheadline.bold())
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 300, height: 30)
                        )
                }
                Spacer()
            }

           
            
            
        }.padding()
            .background(.background)
            .clipShape(
            RoundedRectangle(cornerRadius: 34)
        )
            .offset(y: -30)
    }


}

private var headerImage: some View {
    Image("apartment1") // your asset name
        .resizable()
        .scaledToFill()
        .frame(height: 320)
        .clipped()
        .ignoresSafeArea(edges: .top)
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
    ApartmentDetailView()
}
