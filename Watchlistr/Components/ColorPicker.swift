//
//  ColorPicker.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 11/11/23.
//

import Foundation
import SwiftUI
import UIKit

extension UserDefaults {
    func setColor(_ color: Color, forKey key: String) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false)
            set(data, forKey: key)
        } catch {
            print("Error archiving color: \(error.localizedDescription)")
        }
    }
    
    func color(forKey key: String) -> Color? {
        guard let data = data(forKey: key) else { return nil }
        do {
            guard let uiColor = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else { return nil }
            return Color(uiColor)
        } catch {
            print("Error unarchiving color: \(error.localizedDescription)")
            return nil
        }
    }
}

class ColorManager {
    static let shared = ColorManager()
    private let userDefaults = UserDefaults.standard

    private let primaryColorKey = "userSelectedPrimaryColor"
    private let secondaryColorKey = "userSelectedSecondaryColor"

    func savePrimaryColor(_ color: Color) {
        guard let colorData = color.toData() else { return }
        userDefaults.set(colorData, forKey: primaryColorKey)
    }

    func retrievePrimaryColor() -> Color {
        guard let colorData = userDefaults.data(forKey: primaryColorKey),
              let color = Color(data: colorData) else {
            return Color.blue
        }
        return color
    }

    func saveSecondaryColor(_ color: Color) {
        guard let colorData = color.toData() else { return }
        userDefaults.set(colorData, forKey: secondaryColorKey)
    }

    func retrieveSecondaryColor() -> Color {
        guard let colorData = userDefaults.data(forKey: secondaryColorKey),
              let color = Color(data: colorData) else {
            return Color.indigo
        }
        return color
    }
}

extension Color {
    func toData() -> Data? {
        UIColor(self).toData()
    }

    init?(data: Data) {
        guard let uiColor = UIColor(data: data) else { return nil }
        self.init(uiColor)
    }
}

extension UIColor {
    func toData() -> Data? {
        try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }

    convenience init?(data: Data) {
        if let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
            self.init(cgColor: color.cgColor)
        } else {
            return nil
        }
    }
}

struct DefaultTextColor: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        content
            .foregroundColor(color)
    }
}

extension View {
    func defaultTextColor(_ color: Color) -> some View {
        self.modifier(DefaultTextColor(color: color))
    }
}

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}
