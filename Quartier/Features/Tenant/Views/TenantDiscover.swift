//
//  TenantDiscover.swift
//  Quartier
//

import SwiftUI
import MapKit
import SDWebImageSwiftUI
import FirebaseAuth

struct TenantDiscover: View {

    // MARK: - Environment
    
    @EnvironmentObject var firebase: FirebaseManager
    @EnvironmentObject var authService: AuthService

    @StateObject private var locationManager = LocationManager()

    // MARK: - State
    
    @State private var currentUserID: String? = Auth.auth().currentUser?.uid
    @State private var currentRent: Double?

    @State private var camera: MapCameraPosition = .automatic
    @State private var didAutoCenter = false
    @State private var currentCenter: CLLocationCoordinate2D?
    @State private var currentDistance: CLLocationDistance?
    @State private var zoomLevel: Double = 2000

    @State private var selectedListing: ListingSelection?


    @State private var selectedTab: TenantTab = .discover

    private let minZoom: CLLocationDistance = 500
    private let maxZoom: CLLocationDistance = 20000

    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            
      
            if authService.isRenting {
                Picker("", selection: $selectedTab) {
                    Text("Home").tag(TenantTab.home)
                    Text("Discover").tag(TenantTab.discover)
                }
                .pickerStyle(.segmented)
                .padding()
            }
            
         
            ZStack {
                if authService.isRenting {
                    switch selectedTab {
                    case .home:
                        TenantHome()
                    case .discover:
                        discoverMapView
                    }
                } else {
                    discoverMapView
                }
            }
        }
        .onAppear {
            setupCameraFallback()
            loadUserRent()
            firebase.fetchUserPreferences()
        }
    }

    // MARK: - Discover Map Extracted
    
    private var discoverMapView: some View {
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

            zoomControls
        }
    }

    // MARK: - Annotation UI
    
    @ViewBuilder
    private func annotationContent(for listing: Listing) -> some View {
        VStack(spacing: 2) {

            VStack(spacing: 2) {
                Text("$\(Int(listing.price))")
                    .font(.caption2.bold())

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

            if let firstImage = listing.existingImageURLs.first,
               let url = URL(string: firstImage) {

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

            Image(systemName: "triangle.fill")
                .font(.system(size: 10))
                .foregroundColor(.white)
                .offset(y: -6)
        }
    }

    // MARK: - Zoom Controls
    
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
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Button { zoomOut() } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Logic
    
    private func loadUserRent() {
        guard let uid = currentUserID else { return }
        firebase.fetchCurrentUserRent(uid: uid) { rent in
            self.currentRent = rent
        }
    }

    private func priceDifferenceText(for listingPrice: Double) -> String? {
        let baseline: Double
        
        if let currentRent, currentRent > 0 {
            baseline = currentRent
        } else if let maxBudget = firebase.userPreferences?.budgetMax, maxBudget > 0 {
            baseline = maxBudget
        } else {
            return nil
        }

        let diff = listingPrice - baseline

        if diff == 0 { return "On Budget" }
        return diff > 0 ? "+$\(Int(diff))" : "-$\(Int(abs(diff)))"
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

enum TenantTab {
    case home
    case discover
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
