/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A container view controller that displays a player and a list or movie detail
 view, depending on the platform.
*/

import UIKit
import Combine
import GroupActivities
import Network
import Foundation

class MovieDetailViewController: UIViewController {

    private var subscriptions = Set<AnyCancellable>()

    // The container view controller that plays movies.
    private var player: MoviePlayerViewController

    // The secondary view controller that displays either a list or an info panel, depending on the platform.
    private var list: MovieListViewController?
    private var info: MovieInfoViewController?

    private var stackView: UIStackView!
    private var bottomView: UIView!

    private var shareSheetButton: UIBarButtonItem!
    private var sharePlayButton: UIBarButtonItem!

    private lazy var whatHappenedButtonContainer: UIView = {
        let action = UIAction(title: "What Happened", image: UIImage(systemName: "person.fill.questionmark")) { [weak self] action in
            DispatchQueue.main.async {
                self?.player.performWhatHappened()
            }
        }
        var configuration = UIButton.Configuration.filled()
        configuration.imagePadding = 8
        configuration.cornerStyle = .capsule

        let button = UIButton(configuration: configuration, primaryAction: action)
        button.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView(frame: .zero)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.heightAnchor.constraint(equalToConstant: 32)
        ])
        return container
    }()

    init(player: MoviePlayerViewController, list: MovieListViewController? = nil, info: MovieInfoViewController? =  nil) {
        self.player = player
        self.list = list
        self.info = info
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("The view controller doesn't support this method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.shareSheetButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(presentShareSheet))
        self.sharePlayButton = UIBarButtonItem(title: "SharePlay", image: UIImage(systemName: "shareplay"), target: self, action: #selector(presentSharePlay))

        self.title = "Group Watching"
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.rightBarButtonItems = [shareSheetButton, sharePlayButton]

        CoordinationManager.shared.$enqueuedMovie
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateShareButtons() }
            .store(in: &subscriptions)
        CoordinationManager.shared.$groupSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateShareButtons() }
            .store(in: &subscriptions)

        view.backgroundColor = .contentBackground

        // Create a stack view to hold the player and the bottom view controller's view.
        stackView = UIStackView(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.spacing = 20
        view.addSubview(stackView)

        // Set an aspect ratio constraint on the player.
        let aspectRatio = player.view.widthAnchor.constraint(equalTo: player.view.heightAnchor, multiplier: 16 / 9)
        aspectRatio.priority = UILayoutPriority(999)
        aspectRatio.isActive = true

        // Add the player view controller.
        addChild(player)
        player.view.translatesAutoresizingMaskIntoConstraints = false
        // On iPad, add a four-point corner radius on the player.
        player.view.layer.cornerRadius = traitCollection.userInterfaceIdiom == .pad ? 4 : 0
        player.view.layer.masksToBounds = true
        stackView.addArrangedSubview(player.view)
        player.didMove(toParent: self)

        // Present the What Happened? button if it's in an enabled state.
        if player.isWhatHappenedEnabled {
            stackView.addArrangedSubview(whatHappenedButtonContainer)
        }

        // Add the bottom view controller.
        addChild(bottomController)
        bottomView = bottomController.view
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(bottomView)
        bottomController.didMove(toParent: self)

        let margin: CGFloat = traitCollection.userInterfaceIdiom == .phone ? 0 : 20
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: margin),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: margin),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -margin),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -margin)
        ])
    }

    private func updateShareButtons() {
        let hasMovie = CoordinationManager.shared.enqueuedMovie != nil
        let hasActivity = CoordinationManager.shared.groupSession?.activity != nil

        shareSheetButton.isEnabled = hasMovie
        sharePlayButton.isEnabled = hasMovie && !hasActivity
        if self.player.isWhatHappenedEnabled {
            self.whatHappenedButtonContainer.isHidden = !hasMovie
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Collapse the movie list below the player when the device rotates to landscape.
        if traitCollection.verticalSizeClass == .compact {
            bottomView.removeFromSuperview()
            stackView.removeArrangedSubview(bottomView)
            if player.isWhatHappenedEnabled {
                whatHappenedButtonContainer.removeFromSuperview()
                stackView.removeArrangedSubview(whatHappenedButtonContainer)
            }
            view.backgroundColor = .black
        } else {
            if player.isWhatHappenedEnabled {
                stackView.addArrangedSubview(whatHappenedButtonContainer)
            }
            stackView.addArrangedSubview(bottomView)
            view.backgroundColor = .contentBackground
        }
    }

    lazy var bottomController: UIViewController = {
        if let list = list {
            return list
        } else if let info = info {
            return info
        } else {
            fatalError()
        }
    }()


    @objc private func presentShareSheet(_ sender: UIBarButtonItem) {
        // TODO: Step 4
        // 1. Remove non-SharePlay code
        // 2. Create NSItemProvider
        // 3. Register current activity
        // 4. Present share sheet with item provider


        // Non-SharePlay: Share link to Swift Island website
        let vc = UIActivityViewController(activityItems: [URL(string: "https://swiftisland.nl")!], applicationActivities: nil)

        vc.popoverPresentationController?.sourceItem = sender
        self.present(vc, animated: true)
    }


    @objc private func presentSharePlay() {
        // TODO: Step 5
        // 1. Create MovieWatchingActivity for current movie
        // 2. Create GroupActivitySharingController
        // 3. Present view controller


    }
}
