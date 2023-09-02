//
//  ContentView.swift
//  ShoppingList
//
//  Created by Nonstrict on 2023-07-17.
//

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif
import SwiftUI
import GroupActivities

struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    @StateObject var groupStateObserver = GroupStateObserver()
    @State var showAddSheet = false
    @State var showActivitySharing = false
    @State var textInput = ""

    var body: some View {
        NavigationStack {
            if let session = viewModel.groupSession {
                Text("\(String(describing: session.state))")
            } else {
                Text("not shared")
            }
            List {
                ForEach(viewModel.items) { item in
                    Text(item.title)
                }
                .onMove(perform: viewModel.move)
                .onDelete(perform: viewModel.remove)
            }
            .sheet(isPresented: $showActivitySharing) {
                ActivitySharingViewController(viewModel: viewModel)
            }
            .alert("Add Item", isPresented: $showAddSheet) {
                TextField("Item", text: $textInput)
                Button("Cancel", role: .cancel) {}
                Button("Add") {
                    guard textInput != "" else { return }
                    viewModel.append(.init(title: textInput))
                }
            }
            .navigationTitle("My First List")
            .toolbar {
                toolbarContent
            }
        }
        .task {
            for await session in ShoppingActivity.sessions() {
                viewModel.configureGroupSession(session)
            }
        }
    }

    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .destructive) {
                viewModel.reset()
            } label: {
                Image(systemName: "trash")
                    .accessibilityLabel("Reset")
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                if groupStateObserver.isEligibleForGroupSession {
                    viewModel.startSharing()
                } else {
                    showActivitySharing = true
                }
            } label: {
                Image(systemName: "shareplay")
            }
            .disabled(viewModel.groupSession != nil)
        }
        ToolbarItem(placement: .primaryAction) {
            Menu("Add", systemImage: "plus") {
                ForEach(examples, id: \.self) { example in
                    Button {
                        viewModel.append(.init(title: example))
                    } label: {
                        Text(example)
                    }
                }
                Divider()
                Button("Custom...") {
                    showAddSheet = true
                }
            }

        }
    }
}

#if canImport(UIKit)
struct ActivitySharingViewController: UIViewControllerRepresentable {
    @ObservedObject var viewModel: ViewModel

    typealias UIViewControllerType = GroupActivitySharingController

    func makeUIViewController(context: Context) -> GroupActivitySharingController {
        try! GroupActivitySharingController(viewModel.createShoppingActivity())
    }

    func updateUIViewController(_ uiViewController: GroupActivitySharingController, context: Context) {
    }
}
#endif

#if canImport(AppKit)
struct ActivitySharingViewController: NSViewControllerRepresentable {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) var dismiss

    typealias NSViewControllerType = SharingContainerController

    func makeNSViewController(context: Context) -> NSViewControllerType {
        let container = SharingContainerController()
        container.viewModel = viewModel
        container.dismiss = dismiss

        return container
    }

    func updateNSViewController(_ nsViewController: NSViewControllerType, context: Context) {
        nsViewController.viewModel = viewModel
        nsViewController.dismiss = dismiss
    }
}

class SharingContainerController: NSViewController {

    var viewModel: ViewModel!
    var dismiss: DismissAction!

    override func loadView() {
        view = NSView()
        view.widthAnchor.constraint(equalToConstant: 100).isActive = true
        view.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        let vc = try! GroupActivitySharingController(viewModel.createShoppingActivity())
        Task {
            _ = await vc.result
            self.dismiss()
        }
        self.presentAsSheet(vc)
    }

}
#endif

