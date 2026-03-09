//
//  TenantDiscover.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI
import MapKit

struct TenantDiscover: View {

    @EnvironmentObject var firebase: FirebaseManager

    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )

    var body: some View {
        Map(position: $position) {

            ForEach(firebase.allListings) { listing in
                if let lat = listing.latitude,
                   let lon = listing.longitude {

                    Marker(
                        listing.address,
                        coordinate: CLLocationCoordinate2D(
                            latitude: lat,
                            longitude: lon
                        )
                    )
                }
            }
        }
    }
}
