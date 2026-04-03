//
//  StepperCard.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-04-03.
//

import SwiftUI


 struct StepperCard: View {
        let title: String
        @Binding var value: Int
        
        var body: some View {
            VStack {
                Text(title)
                
                HStack {
                    Button { if value > 0 { value -= 1 } } label: {
                        Image(systemName: "minus.circle")
                    }
                    
                    Text("\(value)")
                        .font(.title3.bold())
                        .frame(minWidth: 40)
                    
                    Button { value += 1 } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .padding()
            .background(.white)
            .cornerRadius(14)
        }
    }
