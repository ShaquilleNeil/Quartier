//
//  TenantSchedule.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI

struct TenantSchedule: View {
    
    @State private var selectedDate = Date()

    
    var body: some View {
        NavigationStack {
            ZStack {
              
                    VStack(alignment: .leading, spacing: 24) {
                        
//                        HeaderView(monthTitle: monthTitle)
                        
                        
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .frame(height: 300)
                        
                      Divider()
                        
                        ScheduleTimelineView()
                            .frame(maxHeight: .infinity)
                        
                        
                    }
                    .padding()
                 
                
            }
            .navigationBarHidden(true)
            .background(Color(.systemBackground))
        }
    }
}

//////////////////////////////////////////////////////////////////
// MARK: Header
//////////////////////////////////////////////////////////////////

private struct HeaderView: View {
    
    let monthTitle: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Schedule")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(monthTitle)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "magnifyingglass"))
                
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
            }
        }
    }
}


//////////////////////////////////////////////////////////////////
// MARK: Timeline (still static for now)
//////////////////////////////////////////////////////////////////

private struct ScheduleTimelineView: View {
    
    var body: some View {
        ScrollView{
            
            VStack(alignment: .leading, spacing: 32)
            {
                
                Text("08:00 AM")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScheduleCard(
                    category: "Maintenance",
                    title: "Plumbing Repair",
                    subtitle: "Kitchen Sink Leak • Unit 402",
                    accentColor: .red
                )
                
                NowIndicator()
                
                Text("11:00 AM")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScheduleCard(
                    category: "Finance",
                    title: "Rent Payment Due",
                    subtitle: "Total: $1,450.00",
                    accentColor: .green
                )
                
                Text("01:00 PM")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScheduleCard(
                    category: "Administration",
                    title: "Move-in Inspection",
                    subtitle: "New Tenant: Sarah Miller • Unit 105",
                    accentColor: .blue
                )
            }
            
        }
        
    }
}

//////////////////////////////////////////////////////////////////
// MARK: Card
//////////////////////////////////////////////////////////////////

private struct ScheduleCard: View {
    
    let category: String
    let title: String
    let subtitle: String
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            Text(category.uppercased())
                .font(.caption)
                .foregroundColor(accentColor)
            
            Text(title)
                .font(.headline)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

//////////////////////////////////////////////////////////////////
// MARK: Now Indicator
//////////////////////////////////////////////////////////////////

private struct NowIndicator: View {
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
            
            Rectangle()
                .fill(Color.blue)
                .frame(height: 2)
            
            Text("NOW")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.15))
                .foregroundColor(.blue)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    TenantSchedule()
}

