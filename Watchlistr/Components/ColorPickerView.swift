//
//  ColorPickerView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 11/20/23.
//

import SwiftUI

struct ColorPickerView: View {
    @EnvironmentObject var tabBarVisibilityManager: TabBarVisibilityManager
    @Binding var selectedPrimaryTextColor: Color
    @Binding var selectedSecondaryTextColor: Color
    @State private var showAlert = false

    var body: some View {
        VStack {
            ColorPicker("Choose a color for your Primary text", selection: $selectedPrimaryTextColor.onChange { newColor in
                ColorManager.shared.savePrimaryColor(newColor)
            })
            .foregroundColor(selectedPrimaryTextColor)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemBackground)))
            .shadow(radius: 3)
            
            ColorPicker("Choose a color for your Secondary text", selection: $selectedSecondaryTextColor.onChange { newColor in
                ColorManager.shared.saveSecondaryColor(newColor)
            })
            .foregroundColor(selectedSecondaryTextColor)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemBackground)))
            .shadow(radius: 3)
            
            Button(action: {
                saveColors()
            }) {
                HStack {
                    Text("Save")
                    Image(systemName: "paintbrush.pointed.fill")
                }
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [selectedPrimaryTextColor, selectedSecondaryTextColor]), startPoint: .leading, endPoint: .trailing).opacity(0.6))
                .cornerRadius(10)
                .foregroundColor(.primary)
            }
        }
        .padding()
        .onAppear {
            tabBarVisibilityManager.hideTabBar()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Settings Saved"),
                message: Text("Please restart the app to apply the new color settings."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func saveColors() {
        ColorManager.shared.savePrimaryColor(selectedPrimaryTextColor)
        ColorManager.shared.saveSecondaryColor(selectedSecondaryTextColor)

        showAlert = true
    }
}

struct ColorPickerView_Previews: PreviewProvider {
    @State static var primaryColor = Color.red
    @State static var secondaryColor = Color.blue

    static var previews: some View {
        ColorPickerView(selectedPrimaryTextColor: $primaryColor, selectedSecondaryTextColor: $secondaryColor)
            .environmentObject(AuthViewModel())
            .environmentObject(WatchlistState())
            .environmentObject(TabBarVisibilityManager())
    }
}
