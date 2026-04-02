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

    // MARK: - Properties & Environment
    
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

    private let minZoom: CLLocationDistance = 500
    private let maxZoom: CLLocationDistance = 20000

    // MARK: - Main Body
    
    var body: some View {
        ZStack {
            Map(position: $camera) {
                UserAnnotation()

                ForEach(firebase.allListings) { listing in
                    if let lat = listing.latitude, let lon = listing.longitude {
                        Annotation(
                            "",
                            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        ) {
                            Button {
                                selectedListing = ListingSelection(id: listing.listingID)
                            } label: {
                                annotationContent(for: listing)
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedListing) { selection in
                if let listing = firebase.allListings.first(where: { $0.listingID == selection.id }) {
                    ApartmentDetailView(listing: listing)
                }
            }
            .onMapCameraChange { cameraUpdate in
                let cam = cameraUpdate.camera
                currentCenter = cam.centerCoordinate
                currentDistance = cam.distance
            }
            .onReceive(locationManager.$userLocation) { newLocation in
                guard !didAutoCenter, let loc = newLocation else { return }
                didAutoCenter = true
                camera = .camera(
                    MapCamera(centerCoordinate: loc, distance: zoomLevel)
                )
            }
            .onAppear {
                setupCameraFallback()
                loadUserRent()
                // Fetch preferences so we can use the budget for the map pins
                firebase.fetchUserPreferences()
            }

            zoomControls
        }
    }
    
    // MARK: - Annotation View
    
    @ViewBuilder
    private func annotationContent(for listing: Listing) -> some View {
        VStack(spacing: 2) {
            // Price Tag & Difference
            VStack(spacing: 2) {
                Text("$\(Int(listing.price))")
                    .font(.caption2.bold())
                    .foregroundColor(.primary)

                if let diff = priceDifferenceText(for: listing.price) {
                    Text(diff)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(diff.hasPrefix("+") ? .red : .green)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(radius: 2)

            // Image Pin
            if let firstImage = listing.existingImageURLs.first, let url = URL(string: firstImage) {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 3)
            } else {
                Image("apartment1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 3)
            }

            // Pointer
            Image(systemName: "triangle.fill")
                .font(.system(size: 10))
                .foregroundColor(.white)
                .offset(y: -6)
                .shadow(radius: 1)
        }
    }
    
    // MARK: - Zoom Controls UI
    
    private var zoomControls: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    Button { zoomIn() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .padding()
                            .foregroundStyle(.white)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }

                    Button { zoomOut() } label: {
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

    // MARK: - Logic & Helpers

    private func loadUserRent() {
        guard let uid = currentUserID else { return }
        firebase.fetchCurrentUserRent(uid: uid) { rent in
            self.currentRent = rent
        }
    }

    private func priceDifferenceText(for listingPrice: Double) -> String? {
        let baseline: Double
        
        // 1. If they currently rent a place, compare to their active lease
        if let currentRent = currentRent, currentRent > 0 {
            baseline = currentRent
        }
        // 2. If they don't rent, compare to the Max Budget in their preferences
        else if let maxBudget = firebase.userPreferences?.budgetMax, maxBudget > 0 {
            baseline = maxBudget
        }
        // 3. Fallback if no data exists
        else {
            return nil
        }

        let diff = listingPrice - baseline

        if diff == 0 {
            return "On Budget"
        } else if diff > 0 {
            return "+$\(Int(diff))"
        } else {
            return "-$\(Int(abs(diff)))"
        }
    }

    private func setupCameraFallback() {
        if locationManager.userLocation == nil {
            camera = .camera(
                MapCamera(
                    centerCoordinate: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
                    distance: zoomLevel
                )
            )
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

// MARK: - Supporting Types

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
