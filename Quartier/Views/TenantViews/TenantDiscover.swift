//
//  TenantDiscover.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI

struct TenantDiscover: View {
    var body: some View {
      
        VStack{
            Text("This contains the map where the tenant can use to browse appartments rentals available in a radius around them or in a specific area. Rentals will be displayed as a bubble with a price if the tenant is not currently renting an apartment. If they have already rented, then it will show the difference in the price between the available and current rental.")
        }.padding()
        
    }
}

#Preview {
    TenantDiscover()
}
