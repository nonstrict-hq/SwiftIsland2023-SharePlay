//
//  ViewModel.swift
//  ShoppingList
//
//  Created by Nonstrict on 2023-07-19.
//

import Foundation
import Combine
import GroupActivities

class ViewModel: ObservableObject {
    static let initialItems: [Item] = []
    @Published private(set) var items: [Item] = initialItems

    func append(_ newElement: Item) {
        items.append(newElement)

        Task {
            try? await messenger?.send(ModificationMessage.append(newElement))
        }
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)

        Task {
            try? await messenger?.send(ModificationMessage.move(source: source, destination: destination))
        }
    }

    func remove(atOffsets offsets: IndexSet) {
        items.remove(atOffsets: offsets)

        Task {
            try? await messenger?.send(ModificationMessage.remove(offsets))
        }
    }

    func reset() {
        items = ViewModel.initialItems

        // Tear down the existing groupSession.
        messenger = nil
        for task in tasks {
            task.cancel()
        }
        tasks = []
        subscriptions = []
        if groupSession != nil {
            groupSession?.leave()
            groupSession = nil
            self.startSharing()
        }
    }

    func createShoppingActivity() -> ShoppingActivity {
        ShoppingActivity(shoppingList: ShoppingList(title: "My First List", createdAt: Date()))
    }


    // MARK: - GroupActivities

    @Published var groupSession: GroupSession<ShoppingActivity>?
    var messenger: GroupSessionMessenger?

    var subscriptions = Set<AnyCancellable>()
    var tasks = Set<Task<Void, Never>>()

    func configureGroupSession(_ groupSession: GroupSession<ShoppingActivity>) {
        items = ViewModel.initialItems

        self.groupSession = groupSession
        let messenger = GroupSessionMessenger(session: groupSession)
        self.messenger = messenger

        groupSession.$state
            .sink { state in
                if case .invalidated = state {
                    self.groupSession = nil
                    self.reset()
                }
            }
            .store(in: &subscriptions)

        groupSession.$activeParticipants
            .sink { activeParticipants in
                let newParticipants = activeParticipants.subtracting(groupSession.activeParticipants)

                Task {
                    try? await messenger.send(InitialListMessage(items: self.items), to: .only(newParticipants))
                }
            }
            .store(in: &subscriptions)

        tasks.insert(Task {
            for await (message, _) in messenger.messages(of: InitialListMessage.self) {
                await handle(message)
            }
        })
        tasks.insert(Task {
            for await (message, _) in messenger.messages(of: ModificationMessage.self) {
                await handle(message)
            }
        })

        groupSession.join()
    }

    func startSharing() {
        Task {
            do {
                _ = try await createShoppingActivity().activate()
            } catch {
                print("Failed to activate ShoppingList activity: \(error)")
            }
        }
    }

    @MainActor
    func handle(_ message: InitialListMessage) {
        guard message.items.count > 0 else { return }

        print("Received", message)
        self.items = message.items
    }

    @MainActor
    func handle(_ message: ModificationMessage) {
        print("Received", message)
        switch message {
        case let .append(item):
            self.items.append(item)
            
        case let .move(source, destination):
            self.items.move(fromOffsets: source, toOffset: destination)

        case let .remove(offsets):
            self.items.remove(atOffsets: offsets)
        }
    }
}

let examples: [String] = [
    "Bananas",
    "Tomatoes",
    "Onions",
    "Olives",
    "Milk",
    "Soup",
    "Cheese",
    "Ham",
    "Salt",
    "Sugar",
    "Stroopwaffel",
]
