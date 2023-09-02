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
    private var modifications: Set<ModificationMessage> = []

    let clientID = UUID()

    func append(_ newElement: Item) {
        let append = ModificationOperation.append(newElement)
        let message = ModificationMessage(clientID: clientID, order: modifications.count, operation: append)

        modifications.insert(message)

        Task {
            await processModifications()
            try? await messenger?.send(message)
        }
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        let move = ModificationOperation.move(source: source.first!, destination: destination)
        let message = ModificationMessage(clientID: clientID, order: modifications.count, operation: move)

        modifications.insert(message)

        Task {
            await processModifications()
            try? await messenger?.send(message)
        }
    }

    func remove(atOffsets offsets: IndexSet) {
        let remove = ModificationOperation.remove(offsets.first!)
        let message = ModificationMessage(clientID: clientID, order: modifications.count, operation: remove)

        modifications.insert(message)

        Task {
            await processModifications()
            try? await messenger?.send(message)
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
                    try? await messenger.send(InitialMessage(modifications: self.modifications), to: .only(newParticipants))
                }
            }
            .store(in: &subscriptions)

        tasks.insert(Task {
            for await (message, _) in messenger.messages(of: InitialMessage.self) {
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
    func handle(_ message: InitialMessage) {
        guard message.modifications.count > 0 else { return }

        print("Received", message)
        modifications = message.modifications

        processModifications()
    }

    @MainActor
    func handle(_ message: ModificationMessage) {
        print("Received", message)
        modifications.insert(message)

        processModifications()
    }

    @MainActor
    func processModifications() {
        let sorted = modifications.sorted(by: { $0.order == $1.order ? $0.clientID.uuidString < $1.clientID.uuidString : $0.order < $1.order })

        var items: [Item] = []
        for modification in sorted {
            switch modification.operation {
            case .append(let item):
                items.append(item)
            case .move(let source, let destination):
                if items.indices.contains(source) && (items.indices.contains(destination) || items.count == destination) {
                    items.move(fromOffsets: IndexSet(integer: source), toOffset: destination)
                }
            case .remove(let index):
                if items.indices.contains(index) {
                    items.remove(at: index)
                }
            }
        }

        self.items = items
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
