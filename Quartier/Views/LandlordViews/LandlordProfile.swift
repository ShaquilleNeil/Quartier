//
//  LandlordProfile.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI

struct LandlordProfile: View {
    var body: some View {
        LandlordProfileView()
    }
}

private struct LandlordProfileView: View {
    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    @State private var isLandlordMode = true

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {

                    // Top bar
                    HStack {
                        Text("Profile")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                        Button {} label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .padding(10)
                                .background(Circle().fill(Color.primary.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    // Header card
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(primary.opacity(0.15))
                                .frame(width: 92, height: 92)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 38, weight: .semibold))
                                        .foregroundStyle(primary)
                                )
                                .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 3))

                            Circle()
                                .fill(.green)
                                .frame(width: 22, height: 22)
                                .overlay(Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white))
                                .offset(x: 2, y: 2)
                        }

                        Text("Shaquille O’Neil")
                            .font(.system(size: 22, weight: .bold))

                        Text("Verified Landlord • Member since 2024")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            chip("ID Verified", fg: .green)
                            chip("Ownership Verified", fg: primary)
                        }

                        Button {} label: {
                            Text("Edit Profile")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 14).fill(primary))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 18).fill(cardBg))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(border, lineWidth: 1))
                    .padding(.horizontal, 16)

                    // Role switcher
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundStyle(primary)
                            .font(.system(size: 18, weight: .semibold))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Switch Role")
                                .font(.system(size: 14, weight: .bold))
                            Text("Enable Tenant mode to browse listings")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $isLandlordMode)
                            .labelsHidden()
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 18).fill(cardBg))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(border, lineWidth: 1))
                    .padding(.horizontal, 16)

                    // Documents
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("My Documents")
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                            Text("2/3 COMPLETED")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(primary.opacity(0.12)))
                        }

                        docRow(title: "Government ID", status: "Verified", statusColor: .green, rightIcon: "checkmark.seal.fill")
                        docRow(title: "Proof of Ownership", status: "Updated 2 days ago", statusColor: .secondary, rightIcon: "doc.text.fill")
                        docRow(title: "Insurance Certificate", status: "Action Required", statusColor: .orange, rightIcon: "plus.circle.fill")
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 18).fill(cardBg))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(border, lineWidth: 1))
                    .padding(.horizontal, 16)

                    // Settings list
                    VStack(spacing: 0) {
                        settingRow("Notifications", icon: "bell.fill")
                        Divider().opacity(0.15)
                        settingRow("Privacy & Security", icon: "lock.fill")
                        Divider().opacity(0.15)
                        Button {} label: {
                            HStack(spacing: 12) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundStyle(.red)
                                Text("Log Out")
                                    .foregroundStyle(.red)
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                            }
                            .padding(14)
                        }
                        .buttonStyle(.plain)
                    }
                    .background(RoundedRectangle(cornerRadius: 18).fill(cardBg))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(border, lineWidth: 1))
                    .padding(.horizontal, 16)

                    Spacer(minLength: 20)
                }
                .padding(.bottom, 18)
            }
        }
    }

    private func chip(_ text: String, fg: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(fg.opacity(0.12)))
    }

    private func docRow(title: String, status: String, statusColor: Color, rightIcon: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(primary.opacity(0.10))
                .frame(width: 42, height: 42)
                .overlay(Image(systemName: "doc.text").foregroundStyle(primary))

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(status).font(.system(size: 11)).foregroundStyle(statusColor)
            }

            Spacer()

            Image(systemName: rightIcon)
                .foregroundStyle(statusColor == .secondary ? primary : statusColor)
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(.vertical, 6)
    }

    private func settingRow(_ title: String, icon: String) -> some View {
        Button {} label: {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundStyle(primary)
                Text(title).font(.system(size: 14, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }

    private var bg: Color {
        Color(uiColor: UIColor { tc in
            tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.10, blue: 0.13, alpha: 1.0)
            : UIColor(red: 0.96, green: 0.97, blue: 0.97, alpha: 1.0)
        })
    }

    private var cardBg: Color { Color(uiColor: .secondarySystemBackground) }
    private var border: Color { Color.primary.opacity(0.08) }
}

#Preview {
    LandlordProfile()
}
