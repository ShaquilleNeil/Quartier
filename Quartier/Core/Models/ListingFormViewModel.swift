//
//  ListingFormViewModel.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-04-03.
//


import Foundation
import CoreLocation
import FirebaseAuth
import SwiftUI
import Combine
import CoreData

@MainActor
class ListingFormViewModel: ObservableObject {

    @Published var isPublishing = false
    @Published var publishError: String?
    @Published var showPublishSuccess = false

    private var firebase: FirebaseManager!
    private var coreData: CoreDataManager!

    func configure(firebase: FirebaseManager, coreData: CoreDataManager) {
        self.firebase = firebase
        self.coreData = coreData
    }

    // MARK: - Draft

    func saveDraft(listing: Listing, context: NSManagedObjectContext) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        var updatedListing = listing
        updatedListing.landLordId = uid

        coreData.saveDraft(from: updatedListing, context: context)
    }

    // MARK: - Publish

    func publish(
        listing: Listing,
        selectedTenant: TenantItem?,
        originalTenantId: String,
        context: NSManagedObjectContext,
        existingImageURLs: [String],
        onComplete: @escaping (Listing) -> Void
    ) {

        guard let uid = Auth.auth().currentUser?.uid else {
            publishError = "User not authenticated."
            return
        }

        var updatedListing = listing
        updatedListing.landLordId = uid
        updatedListing.status = .published

        isPublishing = true
        let wasDraft = (listing.status == .draft)

        Task {
            do {
                // MARK: - Geocode

                if updatedListing.latitude == nil || updatedListing.longitude == nil {
                    let coord = try await geocode(address: updatedListing.address)
                    updatedListing.latitude = coord.latitude
                    updatedListing.longitude = coord.longitude
                }

                // MARK: - Upload Images

                firebase.uploadListingImages(
                    listingId: updatedListing.listingID,
                    images: updatedListing.images
                ) { newURLs in

                    let finalURLs = existingImageURLs + newURLs
                    let newTenantId = selectedTenant?.id ?? ""

                    // MARK: - Save Listing

                    self.firebase.saveListing(
                        listingId: updatedListing.listingID,
                        listingName: updatedListing.listingName,
                        landLordId: updatedListing.landLordId,
                        tenantId: newTenantId,
                        price: updatedListing.price,
                        squareFeet: updatedListing.squareFeet,
                        latitude: updatedListing.latitude ?? 0,
                        longitude: updatedListing.longitude ?? 0,
                        bedrooms: updatedListing.bedrooms,
                        bathrooms: updatedListing.bathrooms,
                        amenities: updatedListing.amenities,
                        status: updatedListing.status,
                        rules: updatedListing.rules,
                        imageURLs: finalURLs,
                        address: updatedListing.address,
                        isRented: !newTenantId.isEmpty
                    )

                    // MARK: - Tenant Sync

                    if originalTenantId.isEmpty && !newTenantId.isEmpty {

                        self.firebase.assignTenantToListing(
                            listingId: updatedListing.listingID.uuidString,
                            tenantId: newTenantId
                        )

                    } else if !originalTenantId.isEmpty && newTenantId.isEmpty {

                        self.firebase.removeTenantFromListing(
                            listingId: updatedListing.listingID.uuidString,
                            previousTenantId: originalTenantId
                        )

                    } else if originalTenantId != newTenantId {

                        self.firebase.removeTenantFromListing(
                            listingId: updatedListing.listingID.uuidString,
                            previousTenantId: originalTenantId
                        )

                        self.firebase.assignTenantToListing(
                            listingId: updatedListing.listingID.uuidString,
                            tenantId: newTenantId
                        )
                    }

                    // MARK: - Draft Cleanup

                    if wasDraft {
                        self.coreData.deleteDraft(
                            listingID: updatedListing.listingID,
                            context: context,
                            pushRemote: false
                        )
                    }

                    self.firebase.fetchListingsLandlord()
                    self.isPublishing = false
                    self.showPublishSuccess = true

                    onComplete(updatedListing) // ✅ return updated version
                }

            } catch {
                self.isPublishing = false
                self.publishError = error.localizedDescription
            }
        }
    }

    // MARK: - Geocode

    private func geocode(address: String) async throws -> CLLocationCoordinate2D {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)

        guard let location = placemarks.first?.location else {
            throw NSError(domain: "Geocode", code: 0)
        }

        return location.coordinate
    }
}
