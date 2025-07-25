//
//  DrawerSheet.swift
//  Andare
//
//  Created by neg2sode on 2025/7/1.
//

import SwiftUI
import UIKit

// A custom UIHostingController subclass that manages its own sheet.
private class CustomSheetHostingController<Content: View>: UIViewController {
    // State properties
    var isPresented: Binding<Bool>
    let sheetContent: AnyView
    let coordinator: SheetPresenter<Content>.Coordinator
    
    // The currently presented sheet, so we can dismiss it.
    private var presentedSheet: UIViewController?

    // Initializer
    init(isPresented: Binding<Bool>, sheetContent: Content, coordinator: SheetPresenter<Content>.Coordinator) {
        self.isPresented = isPresented
        // Type-erase the content to store it
        self.sheetContent = AnyView(sheetContent)
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
        // The controller's own view is clear, it's just a presenter.
        self.view.backgroundColor = .clear
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // This is more reliable than the parent's onAppear.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // When this controller appears, immediately check if it should present the sheet.
        updateSheet(animated: false)
    }
    
    // The core logic to show or hide the sheet
    func updateSheet(animated: Bool = true) {
        // Show the sheet if isPresented is true AND we haven't already presented it.
        if isPresented.wrappedValue && presentedSheet == nil {
            let hostingController = UIHostingController(rootView: sheetContent)
            
            hostingController.modalPresentationStyle = .pageSheet
            hostingController.isModalInPresentation = true

            if let sheet = hostingController.sheetPresentationController {
                sheet.detents = [
                    .custom(identifier: .init("tiny")) { _ in 100 },
                    .large()
                ]
                sheet.largestUndimmedDetentIdentifier = .init("tiny")
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = true
                sheet.delegate = self.coordinator
            }
            
            self.present(hostingController, animated: animated)
            self.presentedSheet = hostingController
        }
        // Hide the sheet if isPresented is false AND we have a sheet to dismiss.
        else if !isPresented.wrappedValue && presentedSheet != nil {
            presentedSheet?.dismiss(animated: animated)
            presentedSheet = nil
        }
    }
}


// The UIViewControllerRepresentable that bridges UIKit's presentation logic
fileprivate struct SheetPresenter<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let content: Content
    let drawerState: DrawerState
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UISheetPresentationControllerDelegate {
        var parent: SheetPresenter

        init(parent: SheetPresenter) {
            self.parent = parent
        }
        
        // This delegate method is called whenever the detent changes.
        func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
            // Update the shared state object on the main thread.
            DispatchQueue.main.async {
                self.parent.drawerState.selectedDetent = sheetPresentationController.selectedDetentIdentifier
            }
        }
    }

    func makeUIViewController(context: Context) -> CustomSheetHostingController<Content> {
        return CustomSheetHostingController(isPresented: $isPresented, sheetContent: content, coordinator: context.coordinator)
    }

    func updateUIViewController(_ uiViewController: CustomSheetHostingController<Content>, context: Context) {
        uiViewController.isPresented = $isPresented
        uiViewController.updateSheet()
    }
}

// The convenient View extension and Modifier are unchanged.
fileprivate struct DrawerSheetViewModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let sheetContent: SheetContent
    let drawerState: DrawerState

    func body(content: Content) -> some View {
        content
            .background(
                SheetPresenter(isPresented: $isPresented, content: sheetContent, drawerState: drawerState)
            )
    }
}

extension View {
    func drawerSheet<Content: View>(
        isPresented: Binding<Bool>,
        drawerState: DrawerState,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(DrawerSheetViewModifier(isPresented: isPresented, sheetContent: content(), drawerState: drawerState))
    }
}
