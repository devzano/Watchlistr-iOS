//
//  DataFetchPhaseOverlayView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

protocol EmptyData {
    var isEmpty: Bool { get }
}

struct DataFetchPhaseOverlayView<V: EmptyData>: View {
    let phase: DataFetchPhase<V>
    let retryAction: () -> ()
    
    var body: some View {
        switch phase {
        case .empty:
            ActivityIndicatorView()
        case .success(let value) where value.isEmpty:
            EmptyPlaceholderView(text: "No Data", image: Image(systemName: "film"))
        case .failure(let error):
            RetryView(text: error.localizedDescription, retryAction: retryAction)
                .onAppear {
                    print("Error phase: \(error.localizedDescription)")
                }
        default:
            EmptyView()
        }
    }

}

extension Array: EmptyData {}
extension Optional: EmptyData {
    var isEmpty: Bool {
        if case .none = self {
            return true
        }
        return false
    }
}

struct DataFetchPhaseOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DataFetchPhaseOverlayView(phase: .success([Movie]())) {
                print("Retry")
            }
            
            DataFetchPhaseOverlayView<[Movie]>(phase: .empty) {
                print("Retry")
            }
            DataFetchPhaseOverlayView<Movie?>(phase: .failure(MovieError.invalidResponse)) {
                print("Retry")
            }
        }
    }
}
