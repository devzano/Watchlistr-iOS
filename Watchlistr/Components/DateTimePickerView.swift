//
//  DateTimePickerView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 11/10/23.
//

import Foundation
import SwiftUI

struct DateTimePickerView: View {
    @Binding var selectedDate: Date?
    @Binding var isDatePickerVisible: Bool
    let action: () -> Void

    var body: some View {
        Group {
            if isDatePickerVisible {
                VStack {
                    DatePicker("Choose a date and time", selection: Binding($selectedDate) ?? Binding.constant(Date()), in: ...Date(), displayedComponents: [.date, .hourAndMinute])

                    HStack {
                        Button("Cancel") {
                            isDatePickerVisible = false
                            selectedDate = nil
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 10)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)

                        Button(action: {
                            action()
                            isDatePickerVisible = false
                        }) {
                            Text("Set")
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 10)
                        .background(Color.yellow.opacity(0.8))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
                .shadow(radius: 10)
            }
        }
    }
}
