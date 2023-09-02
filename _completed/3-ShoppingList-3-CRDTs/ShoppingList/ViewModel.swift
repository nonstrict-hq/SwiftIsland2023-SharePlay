//
//  ViewModel.swift
//  ShoppingList
//
//  Created by Nonstrict on 2023-07-19.
//

import Foundation
import Combine
import GroupActivities
import CRDTs

class ViewModel: ObservableObject {
    static let initialItems: [Item] = []
    @Published private(set) var items: LSeq<Item> = LSeq(siteID: UUID().uuidString)

    func append(_ newElement: Item) {
        items.insert(newElement, at: items.count)

        Task {
            try? await messenger?.send(items)
        }
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        // LSeq move doesn't work correctly

        // Reset UI:
        objectWillChange.send()
    }

    func remove(atOffsets offsets: IndexSet) {
        items.remove(at: offsets.first!)

        Task {
            try? await messenger?.send(items)
        }
    }

    func reset() {
        items = LSeq(siteID: UUID().uuidString)

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
        items = LSeq(siteID: UUID().uuidString)

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
                    try? await messenger.send(self.items, to: .only(newParticipants))
                }
            }
            .store(in: &subscriptions)

        tasks.insert(Task {
            for await (message, _) in messenger.messages(of: LSeq<Item>.self) {
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
    func handle(_ items: LSeq<Item>) {
        self.items = self.items.merged(items)
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
