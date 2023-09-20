//
//  ButtonView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct ButtonView: View {
    var action: () -> Void
    var label: String
    var imageName: String?
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                if let imageName = imageName {
                    Image(systemName: imageName)
                }
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Color(.systemBlue))
        .cornerRadius(10)
    }
}

struct ButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonView(action: {}, label: "Test")
    }
}
