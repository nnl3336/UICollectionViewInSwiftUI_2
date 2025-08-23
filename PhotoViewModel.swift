//
//  PhotoViewModel.swift
//  UICollectionViewInSwiftUI_2
//
//  Created by Yuki Sasaki on 2025/08/23.
//

import SwiftUI
import CoreData

class PhotoFRCViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    @Published var photos: [Photo] = []
    private let frc: NSFetchedResultsController<Photo>

    init(context: NSManagedObjectContext) {
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Photo.creationDate, ascending: true)]
        request.fetchBatchSize = 20

        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: context,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)

        super.init()
        frc.delegate = self

        do {
            try frc.performFetch()
            photos = frc.fetchedObjects ?? []
        } catch {
            print("Fetch failed: \(error)")
        }
    }

    // NSFetchedResultsControllerDelegate
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let updated = controller.fetchedObjects as? [Photo] {
            DispatchQueue.main.async {
                self.photos = updated
            }
        }
    }

    // 新しい写真を追加
    func addPhoto(_ uiImage: UIImage) {
        let context = frc.managedObjectContext
        let newPhoto = Photo(context: context)
        newPhoto.id = UUID()
        newPhoto.creationDate = Date()
        newPhoto.imageData = uiImage.jpegData(compressionQuality: 0.8)

        do {
            try context.save()
        } catch {
            print("Save failed: \(error)")
        }
    }
}
