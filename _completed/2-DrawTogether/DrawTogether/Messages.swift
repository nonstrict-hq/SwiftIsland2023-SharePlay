/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The messages between multiple participants in a group session.
*/

import Foundation
import SwiftUI

// Current state of canvas, to be sent to new participants
struct CanvasMessage: Codable {
    let strokes: [Stroke]
    let pointCount: Int
}

// Active Store, sent via UDP
struct UpsertStrokeMessage: Codable {
    let id: UUID
    let color: Stroke.Color
    let point: CGPoint
}

// Finished stroke, sent via reliable message
struct UpsertFinishedMessage: Codable {
    let id: UUID
    let color: Stroke.Color
    let points: [CGPoint]
}

// Metadata of image attachment
struct ImageMetadataMessage: Codable {
    let location: CGPoint
}
