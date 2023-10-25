//
//  SwiftMessage.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 10/6/23.
//

import Foundation
import SwiftMessages

func showMessage(withTitle title: String, message: String, theme: Theme, duration: TimeInterval = 3.0) {
    let view = MessageView.viewFromNib(layout: .cardView)
    view.configureTheme(theme)
    view.configureDropShadow()
    view.configureContent(title: title, body: message)
    view.button?.isHidden = true
    
    var config = SwiftMessages.Config()
    config.presentationContext = .window(windowLevel: .normal)
    config.duration = .seconds(seconds: duration)
    SwiftMessages.show(config: config, view: view)
}

func showError(withTitle title: String = "Error", message: String, duration: TimeInterval = 3.0) {
    showMessage(withTitle: title, message: message, theme: .error, duration: duration)
}

func showSuccess(withTitle title: String = "Success", message: String, duration: TimeInterval = 3.0) {
    showMessage(withTitle: title, message: message, theme: .success, duration: duration)
}
