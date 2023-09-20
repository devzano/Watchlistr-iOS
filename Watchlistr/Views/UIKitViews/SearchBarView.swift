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
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.placeholder = placeholder
        searchBar.searchBarStyle = .minimal
        searchBar.enablesReturnKeyAutomatically = false
        searchBar.delegate = context.coordinator
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            let placeholderAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.systemBlue
            ]
            textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: placeholderAttributes)
            textField.leftViewMode = .always
            textField.textColor = .systemBlue
            let imageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .systemIndigo
            textField.leftView = imageView
            if let clearButton = textField.value(forKey: "_clearButton") as? UIButton {
                clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
                clearButton.tintColor = .systemRed
            }
        }
        return searchBar
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
