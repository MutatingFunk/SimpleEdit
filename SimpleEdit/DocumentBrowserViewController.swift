//
//  DocumentBrowserViewController.swift
//  SimpleEdit
//
//  Created by James Froggatt on 20.09.2017.
//  Copyright © 2017 James Froggatt. All rights reserved.
//

import UIKit

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate, UIViewControllerTransitioningDelegate {
	override func viewDidLoad() {
		super.viewDidLoad()
		ud.register(defaults: [
			keyFontSize: -1,
			keyKeyboardType: -1,
			keyDarkMode: false,
			keyEditMode: true
		])
		
		browserUserInterfaceStyle = .light
		
		delegate = self
		
		allowsDocumentCreation = true
		allowsPickingMultipleItems = false
		
		self.customActions = [
			UIDocumentBrowserAction(identifier: "Open in New Window", localizedTitle: "Open in New Window", availability: .menu) { urls in
				urls
					.map(Document.init)
					.forEach(UIApplication.shared.resumeSession)
			}
		]
	}
	
	// MARK: UIDocumentBrowserViewControllerDelegate
	
	func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
		do {
			let url = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Untitled.txt")
			let document = Document(fileURL: url)
			document.save(to: url, for: .forCreating) {success in
				guard success else {
					importHandler(nil, .none)
					return UIAlertController(title: "Error", message: "Failed to save created document", preferredStyle: .alert)
						.addAction("OK")
						.present(in: self, animated: true)
				}
				importHandler(url, .move)
			}
		} catch {
			importHandler(nil, .none)
			UIAlertController(title: "Error", message: "Error creating document: \(error.localizedDescription)", preferredStyle: .alert)
				.addAction("OK")
				.present(in: self, animated: true)
		}
	}
	
	func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentURLs documentURLs: [URL]) {
		guard let sourceURL = documentURLs.first else { return }
		
		// Present the Document View Controller for the first document that was picked.
		// If you support picking multiple items, make sure you handle them all.
		presentDocument(at: sourceURL)
	}
	
	func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
		// Present the Document View Controller for the new newly created document
		presentDocument(at: destinationURL)
	}
	
	func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
		let message = (error?.localizedDescription).map{": " + $0} ?? ""
		UIAlertController(title: "Import Error", message: "Error importing document\(message)", preferredStyle: .alert)
			.addAction("OK")
			.present(in: self, animated: true)
	}
	
	// MARK: Document Presentation
	var transitioningController: UIDocumentBrowserTransitionController?
	func presentDocument(at documentURL: URL, animated: Bool = true) {
		
		let storyboard = UIStoryboard(name: "Auxiliary", bundle: nil)
		let nav = storyboard.instantiateViewController(withIdentifier: "DocumentViewControllerNav") as! UINavigationController
		nav.modalPresentationStyle = .fullScreen
		let documentViewController = nav.viewControllers.first! as! DocumentViewController
		
		nav.transitioningDelegate = self
		let transitioningController = transitionController(forDocumentAt: documentURL)
		transitioningController.targetView = documentViewController.documentBodyTextView
		self.transitioningController = transitioningController
		
		documentViewController.document = Document(fileURL: documentURL)
		present(nav, animated: animated, completion: nil)
	}
	
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return transitioningController
	}
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return transitioningController
	}
}
