//
//  SignUp.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI

struct SignUp: View {
    var body: some View {
        VStack{
            Text("sign up")
            
            Form{
                Section(header: Text("Sign Up")){
                    TextField("Email", text: .constant(""))
                    SecureField("Password", text: .constant(""))
                    Button(action:{})
                    {
                        
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                        
                    }
                    
                }
                
                Section(header: Text("Already have an account?")){
                    Button(action:{}){
                        Text("Log In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        
                    }
                }
            }
        }
    }
}

#Preview {
    SignUp()
}
