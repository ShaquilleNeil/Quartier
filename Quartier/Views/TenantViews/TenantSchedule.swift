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
        
        VStack{
            DatePicker("Schedule", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            Text("If not renting as yet, the tenant will see scheduled visits on a calendar. if renting already, the tenant will see scheduled maintenance requests on a calendar. They can also see when notices take effect etc")
        }.padding()
        
    }
}

#Preview {
    TenantSchedule()
}
