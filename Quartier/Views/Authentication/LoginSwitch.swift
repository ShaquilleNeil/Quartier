//
//  LoginSwitch.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI

struct LoginSwitch: View {
    @State private var isTenant: Bool = true
    var body: some View {
        Picker("", selection: $isTenant) {
            Text("Tenant").tag(true)
            Text("Landlord").tag(false)
            
            if(isTenant ){
                TenantLogin()
            } else { LandlordLogin()}
        }
    }
}

#Preview {
    LoginSwitch()
}
