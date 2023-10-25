//
//  SafariView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: self.url)
        return safariVC
    }
}
