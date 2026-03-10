//
//  TenantDiscover.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI
import MapKit
import SDWebImageSwiftUI

struct TenantDiscover: View {

    @EnvironmentObject var firebase: FirebaseManager
    @StateObject private var locationManager = LocationManager()
    @State private var camera: MapCameraPosition = .automatic
    @State private var didAutoCenter = false
    @State private var currentCenter: CLLocationCoordinate2D?
    @State private var currentDistance: CLLocationDistance?
    @State private var zoomLevel: Double = 2000
    @State private var selectedListing: Listing?


    var body: some View {
        ZStack {

            Map(position: $camera) {

                UserAnnotation()

                ForEach(firebase.allListings) { listing in
                    if let lat = listing.latitude,
                       let lon = listing.longitude {

                        Annotation(
                            "",
                            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        ) {

                            Button {
                                selectedListing = listing
                            } label: {
                                VStack(spacing: 2) {

                                    Text("$\(Int(listing.price))")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(.white)
                                        .clipShape(Capsule())
                                        .shadow(radius: 2)

                                    if let firstImage = listing.existingImageURLs.first,
                                       let url = URL(string: firstImage) {

                                        WebImage(url: url)
                                            .resizable()
                                            .indicator(.activity)
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle().stroke(.white, lineWidth: 3)
                                            )
                                            .shadow(radius: 5)

                                    } else {

                                        Image("apartment1")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    }

                                    Image(systemName: "triangle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white)
                                        .offset(y: -6)
                                }
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedListing){
                listing in
                ApartmentDetailView(listing: listing)
            }
            .onMapCameraChange { cameraUpdate in
                let cam = cameraUpdate.camera
                currentCenter = cam.centerCoordinate
                currentDistance = cam.distance
            }
            .onReceive(locationManager.$userLocation) { newLocation in
                guard !didAutoCenter,
                      let loc = newLocation else { return }

                didAutoCenter = true

                camera = .camera(
                    MapCamera(
                        centerCoordinate: loc,
                        distance: zoomLevel
                    )
                )
            }


            VStack {
                Spacer()

                HStack {
                    Spacer()

                    VStack(spacing: 12) {

                        Button {
                            zoomIn()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .padding()
                                .foregroundStyle(.white)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }

                        Button {
                            zoomOut()
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .padding()
                                .foregroundStyle(.white)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                    }
                }
            }
            .padding()
        }
        
        
        
        
        
        
        
       
    }
    private func zoomIn() {
        let center = currentCenter ?? locationManager.userLocation
        let distance = (currentDistance ?? zoomLevel) * 0.8

        if let center {
            camera = .camera(MapCamera(centerCoordinate: center, distance: distance))
        }
    }

    private func zoomOut() {
        let center = currentCenter ?? locationManager.userLocation
        let distance = (currentDistance ?? zoomLevel) * 1.2

        if let center {
            camera = .camera(MapCamera(centerCoordinate: center, distance: distance))
        }
    }
}
