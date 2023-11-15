//
//  ImageLoader.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import Foundation
import UIKit

private let _imageCache = NSCache<AnyObject, AnyObject>()

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    var imageCache = _imageCache
    
    func loadImage(with url: URL) {
        let urlString = url.absoluteString

        if let imageFromCache = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
            self.image = imageFromCache
            return
        }

        isLoading = true

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let data = data, let image = UIImage(data: data) else {
                    print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self?.imageCache.setObject(image, forKey: urlString as AnyObject)
                self?.image = image
            }
        }.resume()
    }
}
