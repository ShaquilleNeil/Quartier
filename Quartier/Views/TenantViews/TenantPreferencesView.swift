//
//  TenantPreferences.swift
//  Quartier
//

import SwiftUI
import FirebaseFirestore // Need this to save!

struct TenantPreferencesView: View {
    @Environment(\.dismiss) var dismiss
<<<<<<< Updated upstream
    @EnvironmentObject var authService: AuthService // Need this to get the user ID
=======
    @Environment(\.managedObjectContext) private var context
>>>>>>> Stashed changes
    
    // MARK: - Form State
    @State private var locationQuery = ""
    @State private var budgetMin: Double = 1000
    @State private var budgetMax: Double = 3000
    @State private var selectedBedroom = "Studio"
    @State private var petsAllowed = false
    @State private var fullyFurnished = false
    @State private var parkingIncluded = false
    @State private var userloggedin = true
    
    @EnvironmentObject private var holder: CoreDataManager
    
    let bedroomOptions = ["Studio", "1", "2", "3+"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "f6f7f8").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                
                    
                    ScrollView {
                        VStack(spacing: 32) {
                            
                            if(userloggedin == true){
                                Text("Preferences")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                           
                            // MARK: Title Section
                            if (userloggedin == false){
                                // MARK: Header
                                HStack {
                                    Button(action: { dismiss() }) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Color(hex: "0d141b"))
                                            .padding(8)
                                    }
                                    Spacer()
                                    Text("Profile Setup")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Color.clear.frame(width: 40, height: 40)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                
                                
                                
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Find your perfect home")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(Color(hex: "0d141b"))
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Text("Set your preferences so we can curate the best listings for you.")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "64748b"))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            
                            // MARK: 1. Location Input
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Desired Location")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(Color(hex: "94a3b8"))
                                    TextField("Search neighborhoods (e.g. Laval)", text: $locationQuery)
                                }
                                .padding()
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                            }
                            
                            // MARK: 2. Budget Input
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Budget Range")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("$\(Int(budgetMin)) - $\(Int(budgetMax))")
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.quartierBlue)
                                }
                                
                                VStack(spacing: 20) {
                                    // Min Slider
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("Minimum: $\(Int(budgetMin))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        
                                        Slider(value: $budgetMin, in: 500...5000, step: 50)
                                            .tint(Color.quartierBlue)
                                            .onChange(of: budgetMin) { _, newValue in
                                                if newValue > budgetMax {
                                                    budgetMax = newValue
                                                }
                                            }
                                    }
                                    
                                    // Max Slider
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("Maximum: $\(Int(budgetMax))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        
                                        Slider(value: $budgetMax, in: 500...5000, step: 50)
                                            .tint(Color.quartierBlue)
                                            .onChange(of: budgetMax) { _, newValue in
                                                if newValue < budgetMin {
                                                    budgetMin = newValue
                                                }
                                            }
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                            }
                            
                            // MARK: 3. Bedrooms Input
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Bedrooms")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                HStack(spacing: 4) {
                                    ForEach(bedroomOptions, id: \.self) { option in
                                        Button(action: { selectedBedroom = option }) {
                                            Text(option)
                                                .font(.system(size: 14, weight: selectedBedroom == option ? .semibold : .medium))
                                                .foregroundColor(selectedBedroom == option ? Color(hex: "0d141b") : Color(hex: "64748b"))
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 40)
                                                .background(selectedBedroom == option ? Color.white : Color.clear)
                                                .cornerRadius(8)
                                                .shadow(color: selectedBedroom == option ? Color.black.opacity(0.1) : .clear, radius: 2)
                                        }
                                    }
                                }
                                .padding(4)
                                .background(Color(hex: "e2e8f0"))
                                .cornerRadius(12)
                            }
                            
                            // MARK: 4. Features (Toggles)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Key Features")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                VStack(spacing: 0) {
                                    PreferenceToggleRow(
                                        icon: "pawprint.fill",
                                        iconColor: .orange,
                                        iconBg: Color.orange.opacity(0.1),
                                        title: "Pets Allowed",
                                        isOn: $petsAllowed
                                    )
                                    
                                    Divider().padding(.leading, 64)
                                    
                                    PreferenceToggleRow(
                                        icon: "sofa.fill",
                                        iconColor: .blue,
                                        iconBg: Color.blue.opacity(0.1),
                                        title: "Fully Furnished",
                                        isOn: $fullyFurnished
                                    )
                                    
                                    Divider().padding(.leading, 64)
                                    
                                    PreferenceToggleRow(
                                        icon: "car.fill",
                                        iconColor: .gray,
                                        iconBg: Color.gray.opacity(0.1),
                                        title: "Parking Included",
                                        isOn: $parkingIncluded
                                    )
                                }
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                            }
                            
                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // MARK: Save Button
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Button(action: {
                            holder.savePreferences(
                                locationQuery: locationQuery,
                                budgetMin: budgetMin,
                                budgetMax: budgetMax,
                                selectedBedroom: selectedBedroom,
                                petsAllowed: petsAllowed,
                                fullyFurnished: fullyFurnished,
                                parkingIncluded: parkingIncluded,
                                context
                            )
                            // Optionally dismiss after saving
                            dismiss()
                        }) {
                            Text("Save & Continue")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.quartierBlue)
                                .cornerRadius(12)
                                .shadow(color: Color.quartierBlue.opacity(0.3), radius: 10, y: 5)
                        }
                    }
                    .padding(20)
                    .background(Rectangle().fill(.ultraThinMaterial).ignoresSafeArea())
                }
            }
        }.onAppear {
            if let saved = holder.preferences {
                locationQuery = saved.locationQuery ?? ""
                budgetMin = saved.budgetMin
                budgetMax = saved.budgetMax
                selectedBedroom = saved.selectedBedroom ?? "Studio"
                petsAllowed = saved.petsAllowed
                fullyFurnished = saved.fullyFurnished
                parkingIncluded = saved.parkingIncluded
            }
        }
    }
    
<<<<<<< Updated upstream
    // MARK: - Logic
    func handleSavePreferences() {
        guard let uid = authService.userSession?.uid else { return }
        
        // This packages up the exact settings they chose
        let prefsData: [String: Any] = [
            "hasCompletedPreferences": true,
            "preferences": [
                "location": locationQuery,
                "budgetMin": budgetMin,
                "budgetMax": budgetMax,
                "bedrooms": selectedBedroom,
                "petsAllowed": petsAllowed,
                "fullyFurnished": fullyFurnished,
                "parkingIncluded": parkingIncluded
            ]
        ]
        
        // Push to Firebase and dismiss the sheet/view!
        Firestore.firestore().collection("users").document(uid).setData(prefsData, merge: true) { error in
            if let error = error {
                print("Failed to save: \(error)")
            } else {
                // If you want this to trigger ContentView routing, call authService.fetchUserData() here!
                authService.fetchUserData()
                dismiss()
            }
        }
    }
=======
 
>>>>>>> Stashed changes
}

// MARK: - Helper Components

struct PreferenceToggleRow: View {
    let icon: String
    let iconColor: Color
    let iconBg: Color
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            ZStack {
                Circle().fill(iconBg).frame(width: 40, height: 40)
                Image(systemName: icon).foregroundColor(iconColor)
            }
            .padding(.trailing, 8)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "0d141b"))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.quartierBlue)
        }
        .padding(16)
    }
}

#Preview {
    TenantPreferencesView()
        .environmentObject(AuthService.shared)
}
