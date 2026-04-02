//
//  TenantDiscover.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI
import MapKit
import SDWebImageSwiftUI
import FirebaseAuth

struct TenantDiscover: View {

    @EnvironmentObject var firebase: FirebaseManager
    @StateObject private var locationManager = LocationManager()

    @State private var currentUserID: String? = Auth.auth().currentUser?.uid
    @State private var currentRent: Double?

    @State private var camera: MapCameraPosition = .automatic
    @State private var didAutoCenter = false

    @State private var currentCenter: CLLocationCoordinate2D?
    @State private var currentDistance: CLLocationDistance?
    @State private var zoomLevel: Double = 2000

    @State private var selectedListing: ListingSelection?

    // Zoom limits
    private let minZoom: CLLocationDistance = 500
    private let maxZoom: CLLocationDistance = 20000

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
                                selectedListing = ListingSelection(id: listing.listingID)
                            } label: {

                                VStack(spacing: 2) {

                                    // PRICE + DIFFERENCE
                                    VStack(spacing: 2) {

                                        Text("$\(Int(listing.price))")
                                            .font(.caption2.bold())

                                        if let diff = priceDifferenceText(for: listing.price) {
                                            Text(diff)
                                                .font(.caption2)
                                                .foregroundColor(
                                                    diff.hasPrefix("+") ? .red : .green
                                                )
                                        }
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(.white)
                                    .clipShape(Capsule())
                                    .shadow(radius: 2)

                                    // DOT
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            Circle().stroke(.blue, lineWidth: 2)
                                        )
                                        .shadow(radius: 3)

                                    // POINTER
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

            // SHEET
            .sheet(item: $selectedListing) { selection in
                if let listing = firebase.allListings.first(where: {
                    $0.listingID == selection.id
                }) {
                    ApartmentDetailView(listing: listing)
                }
            }

            // CAMERA TRACKING
            .onMapCameraChange { cameraUpdate in
                let cam = cameraUpdate.camera
                currentCenter = cam.centerCoordinate
                currentDistance = cam.distance
            }

            // AUTO CENTER
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

            // LOAD DATA
            .onAppear {
                setupCameraFallback()
                loadUserRent()
            }

            // ZOOM CONTROLS
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

    // MARK: - USER RENT

    private func loadUserRent() {
        guard let uid = currentUserID else { return }

        firebase.fetchCurrentUserRent(uid: uid) { rent in
            self.currentRent = rent
        }
    }

    // MARK: - PRICE DIFFERENCE

    private func priceDifferenceText(for listingPrice: Double) -> String? {
        guard let currentRent else { return nil }

        let diff = listingPrice - currentRent

        if diff == 0 {
            return "Same"
        } else if diff > 0 {
            return "+$\(Int(diff))"
        } else {
            return "-$\(Int(abs(diff)))"
        }
    }

    // MARK: - CAMERA FALLBACK

    private func setupCameraFallback() {
        if locationManager.userLocation == nil {
            camera = .camera(
                MapCamera(
                    centerCoordinate: CLLocationCoordinate2D(
                        latitude: 45.5017,
                        longitude: -73.5673
                    ),
                    distance: zoomLevel
                )
            )
        }
    }

    // MARK: - ZOOM

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

struct ListingSelection: Identifiable {
    let id: UUID
}

#Preview {
    let firebase = FirebaseManager()
    let auth = AuthService(firebase: firebase)

    return TenantDiscover()
        .environmentObject(firebase)
        .environmentObject(auth)
}
