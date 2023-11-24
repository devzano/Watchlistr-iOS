//
//  SearchBarView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct SearchBarView: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    let primaryTextColor: UIColor
    let secondaryTextColor: UIColor

    init(placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
        self.primaryTextColor = UIColor(ColorManager.shared.retrievePrimaryColor())
        self.secondaryTextColor = UIColor(ColorManager.shared.retrieveSecondaryColor())
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.placeholder = placeholder
        searchBar.searchBarStyle = .minimal
        searchBar.enablesReturnKeyAutomatically = false
        searchBar.delegate = context.coordinator

        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            let placeholderAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: primaryTextColor
            ]
            textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: placeholderAttributes)
            textField.leftViewMode = .always
            textField.textColor = primaryTextColor

            let imageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = secondaryTextColor
            textField.leftView = imageView

            if let clearButton = textField.value(forKey: "_clearButton") as? UIButton {
                clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
                clearButton.tintColor = .red
            }
        }

        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: self.$text)
    }

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            self.text = searchText
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
    }
}
