/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that contains the Canvas's selected image.
*/

import Foundation
import SwiftUI
import PhotosUI

struct PhotoPlacementView: View {
    @State private var location: CGPoint = CGPoint(x: 50, y: 50)
    @ObservedObject var canvas: Canvas

    var body: some View {
        if let imageData = canvas.selectedImageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                 .resizable()
                 .scaledToFit()
                 .opacity(0.6)
                 .overlay {
                     Rectangle()
                         .inset(by: -2)
                         .strokeBorder(style: StrokeStyle(lineWidth: 4, dash: [10]))
                 }
                 .overlay {
                     Button {
                         canvas.finishImagePlacement(location: location)
                         location = CGPoint(x: 50, y: 50)
                     } label: {
                         Image(systemName: "arrow.down.to.line")
                             .foregroundStyle(.white)
                             .font(.title)
                             .padding()
                             .background(.black.opacity(0.8))
                             .clipShape(Circle())
                     }
                 }
                 .frame(width: 250, height: 250)
                 .position(location)
                 .gesture(simpleDrag)
         }
    }

    var simpleDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                self.location = value.location
            }
    }
}
