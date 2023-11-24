//
//  ActivityIndicatorView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct ActivityIndicatorView: UIViewRepresentable {
    let primaryTextColor: UIColor
    let secondaryTextColor: UIColor
    
    init() {
        primaryTextColor = UIColor(ColorManager.shared.retrievePrimaryColor())
        secondaryTextColor = UIColor(ColorManager.shared.retrieveSecondaryColor())
    }

    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.startAnimating()
        activityIndicator.color = secondaryTextColor
        return activityIndicator
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        uiView.color = secondaryTextColor
    }
}

