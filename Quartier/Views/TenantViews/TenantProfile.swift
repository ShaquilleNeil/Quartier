//
//  TenantProfile.swift
//  Quartier
//

import SwiftUI

struct TenantProfile: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingPreferences = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: Profile Header
                    ProfileHeaderView(userEmail: authService.userSession?.email ?? "Tenant User")
                    
                    // MARK: Edit Button
                    Button(action: {}) {
                        Text("Edit Profile")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // MARK: Search Preferences
                    SearchPreferencesCard(onUpdate: {
                        showingPreferences = true
                    })
                    
                    // MARK: Documents
                    DocumentsSection()
                    
                    // MARK: Account Settings
                    AccountSettingsSection(onLogout: {
                        authService.signOut()
                    })
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPreferences) {
                TenantPreferencesView()
            }
        }
    }
}

//////////////////////////////////////////////////////////////////
// MARK: Profile Header
//////////////////////////////////////////////////////////////////

private struct ProfileHeaderView: View {
    var userEmail: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(30)
                            .foregroundColor(.gray)
                    )
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
            }
            
            Text(userEmail)
                .font(.title3.bold())
            
            Text("Verified Tenant • Member since 2026")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Badge(text: "ID Verified")
                Badge(text: "Income Verified")
            }
        }
    }
}

private struct Badge: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.blue)
            Text(text)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .clipShape(Capsule())
    }
}

//////////////////////////////////////////////////////////////////
// MARK: Search Preferences Card
//////////////////////////////////////////////////////////////////

private struct SearchPreferencesCard: View {
    var onUpdate: () -> Void
    
    var body: some View {
        Button(action: onUpdate) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Housing Preferences")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Edit your budget, location, and needs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding(10)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct DocumentsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Documents")
                    .font(.headline)
                Spacer()
                Text("2/3 Completed")
                    .foregroundColor(.blue)
                    .font(.subheadline)
            }
            DocumentRow(title: "Government ID", status: "Verified", color: .green)
            DocumentRow(title: "Recent Paystubs", status: "Updated 2 days ago", color: .green)
            DocumentRow(title: "Tax Returns (W2)", status: "Action Required", color: .orange)
        }
    }
}

private struct DocumentRow: View {
    let title: String
    let status: String
    let color: Color
    private var isGoodStatus: Bool {
        let lower = status.lowercased()
        return lower.contains("verified") || lower.contains("updated")
    }
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.15)).frame(width: 44, height: 44).overlay(Image(systemName: "doc.fill"))
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(status).font(.subheadline).foregroundColor(color)
            }
            Spacer()
            Circle().fill(color).frame(width: 24, height: 24).overlay{ Image(systemName: isGoodStatus ? "checkmark" : "xmark.circle").foregroundStyle(.white) }
        }
        .padding().background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground))).shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

private struct AccountSettingsSection: View {
    var onLogout: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Settings").font(.headline)
            SettingsRow(title: "Notifications", icon: "bell.fill")
            SettingsRow(title: "Privacy & Security", icon: "lock.fill")
            Button("Log Out") { onLogout() }.foregroundColor(.red).padding(.top, 8)
        }
    }
}

private struct SettingsRow: View {
    let title: String; let icon: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.gray)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray)
        }
        .padding().background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground))).shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }
}
#Preview {
    TenantProfile()
        .environmentObject(AuthService.shared)
}
