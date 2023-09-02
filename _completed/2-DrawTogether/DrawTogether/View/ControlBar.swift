/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that contains the buttons for interacting with the canvas or app.
*/

import SwiftUI
import GroupActivities
import PhotosUI
import UIKit

struct ControlBar: View {
    @ObservedObject var canvas: Canvas
    @StateObject var groupStateObserver = GroupStateObserver()
    @State private var selectedItem: PhotosPickerItem? = nil
    @State var isSharingControllerPresented: Bool = false
    @State var isShareSheetPresented: Bool = false

    var body: some View {
        HStack {
            if canvas.groupSession == nil {
                Button {
                    if groupStateObserver.isEligibleForGroupSession {
                        canvas.startSharing()
                    } else {
                        isSharingControllerPresented = true
                    }
                } label: {
                    Image(systemName: "shareplay")
                }
                .buttonStyle(.borderedProminent)
                .sheet (isPresented: $isSharingControllerPresented) {
                    ActivitySharingViewController()
                }

                Button {
                    isShareSheetPresented = true
                } label : {
                    Image(systemName: "square.and.arrow.up")
                }
                .sheet(isPresented: $isShareSheetPresented, content: {
                    ShareSheet()
                })
            }

            Spacer()

            if canvas.groupSession != nil {
                if #available(iOS 17, *) {
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()) {
                            Image(systemName: "photo.fill")
                                .foregroundColor(Color.white)
                                .background(Color.accentColor)
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                // Retrieve the selected asset in the form of Data
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    canvas.selectedImageData = data
                                    selectedItem = nil
                                }
                            }
                        }
                }
            }

            Button {
                canvas.reset()
            } label: {
                Image(systemName: "trash.fill")
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

struct ActivitySharingViewController: UIViewControllerRepresentable {
    typealias UIViewControllerType = GroupActivitySharingController

    func makeUIViewController(context: Context) -> GroupActivitySharingController {
        try! GroupActivitySharingController(DrawTogether())
    }

    func updateUIViewController(_ uiViewController: GroupActivitySharingController, context: Context) {
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let itemProvider = NSItemProvider()
        itemProvider.registerGroupActivity(DrawTogether())

        let configuration = UIActivityItemsConfiguration(itemProviders: [itemProvider])
        return UIActivityViewController(activityItemsConfiguration: configuration)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}
