//
//  PhotoViewModel.swift
//  UICollectionViewInSwiftUI_2
//
//  Created by Yuki Sasaki on 2025/08/23.
//

import SwiftUI
import CoreData

class PhotoViewModel: ObservableObject {
    @Published var photos: [Photo] = []
    private var context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchPhotos()
    }

    func fetchPhotos() {
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Photo.creationDate, ascending: true)]
        
        do {
            photos = try context.fetch(request)
        } catch {
            print("Fetch failed: \(error)")
        }
    }

    func addPhoto(_ uiImage: UIImage) {
        let newPhoto = Photo(context: context)
        newPhoto.id = UUID()
        newPhoto.creationDate = Date()
        newPhoto.imageData = uiImage.jpegData(compressionQuality: 0.8)
        
        do {
            try context.save()
            fetchPhotos()
        } catch {
            print("Save failed: \(error)")
        }
    }
}
