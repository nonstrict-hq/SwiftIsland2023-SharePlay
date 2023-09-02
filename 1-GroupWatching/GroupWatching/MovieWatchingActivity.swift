/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The group movie watching activity.
*/

import UIKit
import Foundation
import Combine
import GroupActivities
import LinkPresentation
import UniformTypeIdentifiers

// A type that represents a movie to watch with others.
struct Movie: Hashable, Codable {
    var url: URL
    var title: String
    var description: String
    var posterTime: TimeInterval
    var website: URL
}

// A group activity to watch a movie together.
struct MovieWatchingActivity: GroupActivity {

    // The movie to watch.
    let movie: Movie

    // Metadata that the system displays to participants.
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.type = .watchTogether
        metadata.fallbackURL = movie.url
        metadata.title = movie.title
        metadata.subtitle = movie.description
        metadata.previewImage = Poster(url: movie.url, posterTime: movie.posterTime).posterImage?.cgImage
        return metadata
    }
}
