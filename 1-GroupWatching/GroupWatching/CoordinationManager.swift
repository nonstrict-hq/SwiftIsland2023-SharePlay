/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A shared object that observes GroupActivities sessions and prepares
 the system for coordinated playback of movies.
*/

import Foundation
import Combine
import GroupActivities

class CoordinationManager {

    static let shared = CoordinationManager()

    private var subscriptions = Set<AnyCancellable>()

    // Published values that the player, and other UI items, observe.
    @Published var enqueuedMovie: Movie?
    @Published var groupSession: GroupSession<MovieWatchingActivity>?

    private init() {
        // TODO: Step 2
        // 1. Loop over sessions for MovieWatchingActivity
        // 2. Update @Published groupSession
        // 3. Observe session activity and update @Published enqueuedMovie
        // 4. Observe state to reset @Published variables when leaving session (optional)
        // 5. Join GroupSession


    }

    // Prepares the app to play the movie.
    func prepareToPlay(_ selectedMovie: Movie) {
        // Return early if the app enqueues the movie.
        guard enqueuedMovie != selectedMovie else { return }

        // TODO: Step 1
        // 1. Remove non-SharePlay code
        // 2. Create MovieWatchingActivity
        // 3. Call prepareForActivation
        //     - If user wants to share with group: Activate Activity
        //     - If user doesn't want to share:     Enqueue movie for local playback


        // Non-SharePlay: Immediately enqueue movie for local playback
        self.enqueuedMovie = selectedMovie


    }
}
