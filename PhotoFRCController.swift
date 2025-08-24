//
//  PhotoFRCController.swift
//  UICollectionViewInSwiftUI_2
//
//  Created by Yuki Sasaki on 2025/08/24.
//

import SwiftUI
import CoreData

// MARK: - ViewModel (CoreData + FRC)
class PhotoFRCController: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    private let context: NSManagedObjectContext
    private var frc: NSFetchedResultsController<Photo>!
    private weak var collectionView: UICollectionView?

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        setupFRC()
    }

    private func setupFRC() {
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Photo.creationDate, ascending: true)]
        request.fetchBatchSize = 50

        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: context,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        frc.delegate = self

        do {
            try frc.performFetch()
        } catch {
            print("FRC fetch error: \(error)")
        }
    }

    // MARK: - Public API
    func attach(collectionView: UICollectionView) {
        self.collectionView = collectionView
        collectionView.reloadData()
    }

    var numberOfItems: Int {
        frc.fetchedObjects?.count ?? 0
    }

    func photo(at index: Int) -> Photo? {
        frc.fetchedObjects?[index]
    }

    func delete(_ photo: Photo) {
        context.delete(photo)
        do {
            try context.save()
        } catch {
            print("Delete failed: \(error)")
        }
    }

    // MARK: - NSFetchedResultsControllerDelegate
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.reloadData()
    }
}
