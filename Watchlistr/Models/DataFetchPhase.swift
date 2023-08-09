//
//  DataFetchPhase.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 5/20/23.
//

import Foundation

enum DataFetchPhase<V> {
    
    case empty
    case success(V)
    case failure(Error)
    
    var value: V? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
}
