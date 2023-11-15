//
//  ColorPicker.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 11/11/23.
//

import SwiftUI

//struct ColorPickerView: View {
//    @EnvironmentObject var colorSettings: ColorSettings
//
//    var body: some View {
//        VStack(spacing: 20) {
//            ColorPicker("Choose A Color for your Primary Text", selection: $colorSettings.primaryColor)
//                .foregroundColor(colorSettings.primaryColor)
//                .padding()
//                .background(RoundedRectangle(cornerRadius: 10)
//                                .fill(Color(UIColor.secondarySystemBackground)))
//                .shadow(radius: 3)
//
//            ColorPicker("Choose A Color for your Secondary Text", selection: $colorSettings.secondaryColor)
//                .foregroundColor(colorSettings.secondaryColor)
//                .padding()
//                .background(RoundedRectangle(cornerRadius: 10)
//                                .fill(Color(UIColor.secondarySystemBackground)))
//                .shadow(radius: 3)
//        }
//        .padding()
//        .navigationBarTitle("Customize Colors", displayMode: .inline)
//    }
//}
//
//struct ColorPickerView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            ColorPickerView().environmentObject(ColorSettings())
//        }
//    }
//}
//
//class ColorSettings: ObservableObject {
//    @Published var primaryColor: Color = .indigo {
//        didSet { updateNavigationBarColors() }
//    }
//    @Published var secondaryColor: Color = .blue {
//        didSet { updateNavigationBarColors() }
//    }
//
//    private func updateNavigationBarColors() {
//        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(primaryColor)]
//        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(secondaryColor)]
//        
//        UINavigationBar.appearance().tintColor = UIColor(secondaryColor)
//    }
//}

struct DefaultTextColor: ViewModifier {
//    @EnvironmentObject var colorSettings: ColorSettings
    func body(content: Content) -> some View {
        content
            .foregroundColor(.indigo)
    }
}

extension View {
    func defaultTextColor() -> some View {
        self.modifier(DefaultTextColor())
//            .environmentObject(ColorSettings())
    }
}
