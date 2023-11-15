//
//  UserInfoRow.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 11/6/23.
//

import Foundation
import SwiftUI

struct UserInfoRow: View {
    var iconName: String
    var iconColor: Color
    var text: String
    var textColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: 20)
            Text(text)
                .foregroundColor(textColor)
                .lineLimit(1)
        }
    }
}
