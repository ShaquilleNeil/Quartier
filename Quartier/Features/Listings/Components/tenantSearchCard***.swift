//
//  tenantSearchCard.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-04-03.
//

import SwiftUI

struct tenantSearchCard: View {
    let user : User
    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
            Spacer().frame(width: 8)
            Text(user.email)
        }
        .frame(width: 150, height: 30)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.gray, lineWidth: 1)
                )
    }
}
//
//#Preview {
//    tenantSearchCard()
//}
