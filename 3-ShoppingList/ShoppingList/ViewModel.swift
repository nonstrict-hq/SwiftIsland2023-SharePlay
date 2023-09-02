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

        // TODO: Step 3
        // Send message
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)

        // TODO: Step 3
        // Send message
    }

    func remove(atOffsets offsets: IndexSet) {
        items.remove(atOffsets: offsets)

        // TODO: Step 3
        // Send message
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

                // TODO: Step 4
                // Support late joiners
            }
            .store(in: &subscriptions)

        // TODO: Step 2
        // Listen for messages

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
