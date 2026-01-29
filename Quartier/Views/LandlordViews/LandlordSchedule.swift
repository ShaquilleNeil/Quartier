//
//  LandlordSchedule.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI

struct LandlordSchedule: View {
    @State private var selectedDate: Date = Date()
    var body: some View {
        VStack {
          Text("Landlord Schedule")
            DatePicker("Schedule", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }.padding()
       
    }
}

#Preview {
    LandlordSchedule()
}
