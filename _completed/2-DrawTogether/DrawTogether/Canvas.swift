/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents the canvas to draw on.
*/

import Foundation
import Combine
import SwiftUI
import GroupActivities

struct CanvasImage: Identifiable {
    var id: UUID
    let location: CGPoint
    let imageData: Data
}

@MainActor
class Canvas: ObservableObject {
    @Published var strokes = [Stroke]()
    @Published var activeStroke: Stroke?
    @Published var images = [CanvasImage]()
    @Published var selectedImageData: Data?
    let strokeColor = Stroke.Color.random

    var subscriptions = Set<AnyCancellable>()
    var tasks = Set<Task<Void, Never>>()


    @Published var groupSession: GroupSession<DrawTogether>?
    private var messenger: GroupSessionMessenger?
    private var unreliableMessenger: GroupSessionMessenger?

    private var _journal: AnyObject?

    func configureGroupSession(_ groupSession: GroupSession<DrawTogether>) {
        strokes = []

        // Set the Canvas's active group session.
        self.groupSession = groupSession

        // Observe changes to the session state.
        groupSession.$state
            .sink { state in
                if case .invalidated = state {
                    self.groupSession = nil
                    self.reset()
                }
            }
            .store(in: &subscriptions)

        let messenger = GroupSessionMessenger(session: groupSession)
        self.messenger = messenger

        groupSession.$activeParticipants
            .sink { activeParticipants in
                let newParticipants = activeParticipants.subtracting(groupSession.activeParticipants)

                Task {
                    try? await messenger.send(CanvasMessage(strokes: self.strokes, pointCount: self.pointCount), to: .only(newParticipants))
                }
            }
            .store(in: &subscriptions)

        let canvasMessagesTask = Task {
            for await (message, _) in messenger.messages(of: CanvasMessage.self) {
                handle(message)
            }
        }
        tasks.insert(canvasMessagesTask)

        let upsertFinishedMessagesTask = Task {
            for await (message, _) in messenger.messages(of: UpsertFinishedMessage.self) {
                handle(message)
            }
        }
        tasks.insert(upsertFinishedMessagesTask)

        let unreliableMessenger = GroupSessionMessenger(session: groupSession, deliveryMode: .unreliable)
        self.unreliableMessenger = unreliableMessenger

        let upsertStrokeMessagesTask = Task {
            for await (message, _) in unreliableMessenger.messages(of: UpsertStrokeMessage.self) {
                handle(message)
            }
        }
        tasks.insert(upsertStrokeMessagesTask)

        if #available(iOS 17, *) {
            let journal = GroupSessionJournal(session: groupSession)
            self.journal = journal

            let attachmentsTask = Task {
                for await images in journal.attachments {
                    await handle(images)
                }
            }
            tasks.insert(attachmentsTask)
        }

        groupSession.join()
    }

    func finishStroke() {
        guard let activeStroke = activeStroke else {
            return
        }

        if let messenger = messenger {
            Task {
                try? await messenger.send(UpsertFinishedMessage(id: activeStroke.id, color: activeStroke.color, points: activeStroke.points))
            }
        }

        strokes.append(activeStroke)
        self.activeStroke = nil
    }

    func addPointToActiveStroke(_ point: CGPoint) {
        let stroke: Stroke
        if let activeStroke = activeStroke {
            stroke = activeStroke
        } else {
            stroke = Stroke(color: strokeColor)
            activeStroke = stroke
        }

        stroke.points.append(point)

        if let messenger = unreliableMessenger {
            Task {
                try? await messenger.send(UpsertStrokeMessage(id: stroke.id, color: stroke.color, point: point))
            }
        }
    }

    func finishImagePlacement(location: CGPoint) {
        if #available(iOS 17, *) {
            guard let selectedImageData = selectedImageData, let journal = journal else {
                return
            }

            Task(priority: .userInitiated) {
                try await journal.add(selectedImageData, metadata: ImageMetadataMessage(location: location))
            }

            self.selectedImageData = nil
        }
    }

    func reset() {
        // Clear the local drawing canvas.
        strokes = []
        images = []
        selectedImageData = nil

        // Tear down the existing groupSession.
        messenger = nil
        unreliableMessenger = nil
        if #available(iOS 17, *) {
            journal = nil
        }
        tasks.forEach { $0.cancel() }
        tasks = []
        subscriptions = []
        if groupSession != nil {
            groupSession?.leave()
            groupSession = nil
            self.startSharing()
        }
    }

    var pointCount: Int {
        return strokes.reduce(0) { $0 + $1.points.count }
    }

    func startSharing() {
        Task {
            do {
                _ = try await DrawTogether().activate()
            } catch {
                print("Failed to activate DrawTogether activity: \(error)")
            }
        }
    }

    private func handle(_ message: UpsertStrokeMessage) {
        if let stroke = strokes.first(where: { $0.id == message.id }) {
            stroke.points.append(message.point)
        } else {
            let stroke = Stroke(id: message.id, color: message.color)
            stroke.points.append(message.point)
            strokes.append(stroke)
        }
    }

    private func handle(_ message: UpsertFinishedMessage) {
        if let stroke = strokes.first(where: { $0.id == message.id }) {
            stroke.points = message.points
        } else {
            let stroke = Stroke(id: message.id, color: message.color)
            stroke.points = message.points
            strokes.append(stroke)
        }
    }

    private func handle(_ message: CanvasMessage) {
        guard message.pointCount > self.pointCount else { return }
        self.strokes = message.strokes
    }

    @available(iOS 17, *)
    private func handle(_ attachments: GroupSessionJournal.Attachments.Element) async {
        // Ensure that the canvas always has all the images from this sequence.
        self.images = await withTaskGroup(of: CanvasImage?.self) { group in
            var images = [CanvasImage]()

            attachments.forEach { attachment in
                group.addTask {
                    do {
                        let metadata = try await attachment.loadMetadata(of: ImageMetadataMessage.self)
                        let imageData = try await attachment.load(Data.self)
                        return .init(id: attachment.id, location: metadata.location, imageData: imageData)
                    } catch { return nil }
                }
            }

            for await image in group {
                if let image {
                    images.append(image)
                }
            }

            return images
        }
    }
}

@available(iOS 17, *)
extension Canvas {
    var journal: GroupSessionJournal? {
        get {
            _journal as? GroupSessionJournal
        }
        set {
            _journal = newValue
        }
    }
}
