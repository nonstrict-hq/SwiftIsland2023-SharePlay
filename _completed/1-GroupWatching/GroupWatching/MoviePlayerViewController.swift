/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that plays media using AVPlayer and AVPlayerViewController.
*/
import AVKit
import Combine
import GroupActivities

extension AVCoordinatedPlaybackSuspension.Reason {
    static var whatHappened = AVCoordinatedPlaybackSuspension.Reason(rawValue: "com.example.groupwatching.suspension.what-happened")
}

class MoviePlayerViewController: UIViewController {

    // The app's player object.
    private let player = AVPlayer()

    var isWhatHappenedEnabled = true

    init() {
        super.init(nibName: nil, bundle: nil)

        // The movie subscriber.
        CoordinationManager.shared.$enqueuedMovie
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateMovie($0) }
            .store(in: &subscriptions)

        // The group session subscriber.
        CoordinationManager.shared.$groupSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateGroupSession($0) }
            .store(in: &subscriptions)

        player.publisher(for: \.timeControlStatus, options: [.initial])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                if [.playing, .waitingToPlayAtSpecifiedRate].contains($0) {
                    // Only show the poster view if playback is in a paused state.
                    self?.posterView.isHidden = true
                }
            }
            .store(in: &subscriptions)

        // Observe audio session interruptions.
        NotificationCenter.default
            .publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in

                // Wrap the notification in helper type that extracts the interruption type and options.
                guard let result = InterruptionResult(notification) else { return }

                // Resume playback, if appropriate.
                if result.type == .ended && result.options == .shouldResume {
                    self?.player.play()
                }
            }.store(in: &subscriptions)
    }

    private var subscriptions = Set<AnyCancellable>()
    private let posterView = PosterImageView()

    private lazy var playerViewController: AVPlayerViewController = {
        let controller = AVPlayerViewController()
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.player = player
        return controller
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        modalPresentationStyle = .fullScreen
        guard let playerView = playerViewController.view else {
            fatalError("Unable to get player view controller view.")
        }
        addChild(playerViewController)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerView)
        playerViewController.didMove(toParent: self)
        playerView.pinToSuperviewEdges()

        playerViewController.contentOverlayView?.addSubview(posterView)
        posterView.pinToSuperviewEdges()
    }

    // The group session to coordinate playback with.
    private func updateGroupSession(_ groupSession: GroupSession<MovieWatchingActivity>?) {
        guard let session = groupSession else {
            // Stop playback if a session terminates.
            player.rate = 0
            return
        }
        let avPlayer = player

        // Coordinate playback with the active session.
        avPlayer.playbackCoordinator.coordinateWithSession(session)
    }

    // The movie the player enqueues for playback.
    private func updateMovie(_ movie: Movie?) {
        guard let movie = movie else {
            updatePoster(for: nil)
            player.replaceCurrentItem(with: nil)
            return
        }
        updatePoster(for: movie)

        let playerItem = AVPlayerItem(url: movie.url)
        player.replaceCurrentItem(with: playerItem)
        print("🍿 \(movie.title) enqueued for playback.")
    }

    private func updatePoster(for movie: Movie?) {
        posterView.movie = movie
        guard let currentRate = player.currentItem?.timebase?.rate else { return }
        DispatchQueue.main.async {
            self.posterView.isHidden = currentRate > 0
        }
    }

    // Start a custom suspension. Rewind 10 seconds and play at double speed
    // until the viewer catches up with the group, and then end the suspension.
    func performWhatHappened() {

        // Rewind 10 seconds.
        let rewindDuration = CMTime(value: 10, timescale: 1)
        let rewindTime = player.currentTime() - rewindDuration

        // Start a custom suspension.
        let suspension = player.playbackCoordinator.beginSuspension(for: .whatHappened)
        player.pause()
        player.seek(to: rewindTime) { [player] finished in
            player.rate = 2.0
        }

        let delay: Double = rewindDuration.seconds

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // End the suspension and resume playback with the group.
            suspension.end()
        }
    }
}

struct InterruptionResult {

    let type: AVAudioSession.InterruptionType
    let options: AVAudioSession.InterruptionOptions

    init?(_ notification: Notification) {
        // Determine the interruption type and options.
        guard let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? AVAudioSession.InterruptionType,
              let options = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? AVAudioSession.InterruptionOptions else {
                  return nil
              }
        self.type = type
        self.options = options
    }
}
