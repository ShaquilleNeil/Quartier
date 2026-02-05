//
//  TenantProfile.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI

struct TenantProfile: View {
    var body: some View {
        VStack(){
            //MARK: Shaq//////////////////
            //MARK: Profile image/////////////////////
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .background(
                    Circle().fill(.gray)
                )
            
            
            
            Text("John Doe")
                .font(Font.largeTitle.bold())
                .foregroundColor(.black)
            
                Text("JohnDoe@example.com")
            
            
            
            Spacer()
                .frame(height: 20)
            
            Button(action: {})
            {
                Text("Edit Profile")
                    .font(Font.subheadline.bold())
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .frame(width: 300, height: 40)
                    )
               
            }
            
            
            Spacer()
                .frame(height: 40)
            
            
            
            Text("My search Preferences")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(Font.title3.bold())
            
            //MARK: place holder card for preferences from core data
            HStack {
                VStack(alignment: .leading) {
                    Text("2BR in Miami, FL")

                    HStack {
                        Text("$1,200/mo")
                        Text("4.8/5")
                        Text("No Pets")
                    }
                    .font(.caption)

                    Spacer()

                    Button(action: {}) {
                        Text("Update Preferences")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 150, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.blue)
                            )
                    }
                }

                Spacer()

                Image(systemName: "person.crop.square.on.square.angled.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 170)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.5))
            )
            .clipShape(RoundedRectangle(cornerRadius: 15))

            
            
        Spacer()
            
            Button(action: {}){
                Text("Sign Out")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .frame(width: 300, height: 40)
                            .foregroundStyle(Color.red)
                            
                            
                    )
                
            }
            
          
           
                
            
        }
        .padding()
       
    }
}

#Preview {
    TenantProfile()
}
