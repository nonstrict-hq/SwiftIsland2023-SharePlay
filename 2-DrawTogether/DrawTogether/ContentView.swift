/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary entry point for the app's user interface.
*/

import SwiftUI
import GroupActivities

struct ContentView: View {
    @StateObject var canvas = Canvas()

    var body: some View {
        VStack {
            HStack {
                Spacer()
                StrokeColorIndicator(color: canvas.strokeColor.uiColor)
            }
            .padding()

            ZStack {
                CanvasView(canvas: canvas)
                PhotoPlacementView(canvas: canvas)
            }

            ControlBar(canvas: canvas)
                .padding()

        }
        .task {
            // TODO: Step 1
            // 1. Loop over sessions for DrawTogether activity
            // 2. Call configureGroupSession(:_) on Canvas

        }
    }
}
