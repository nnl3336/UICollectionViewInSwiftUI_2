//
//  ContentView.swift
//  UICollectionViewInSwiftUI_2
//
//  Created by Yuki Sasaki on 2025/08/23.
//

import UIKit
import PhotosUI
import SwiftUI
import CoreData

class PhotoFRCController: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    private let frc: NSFetchedResultsController<Photo>
    private weak var collectionView: UICollectionView?

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
        } catch {
            print("Fetch failed: \(error)")
        }
    }

    var numberOfItems: Int {
        frc.fetchedObjects?.count ?? 0
    }

    func photo(at index: Int) -> Photo? {
        frc.fetchedObjects?[index]
    }

    func attach(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }

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

class PhotoCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var collectionView: UICollectionView!
    var viewModel: PhotoFRCController!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)

        viewModel.attach(collectionView: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.numberOfItems
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.backgroundColor = .lightGray

        // 画像を追加
        if let photo = viewModel.photo(at: indexPath.item),
           let data = photo.imageData,
           let uiImage = UIImage(data: data) {
            let imageView = UIImageView(image: uiImage)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.frame = cell.contentView.bounds
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            cell.contentView.addSubview(imageView)
        }
        return cell
    }
}

struct PhotoCollectionViewRepresentable: UIViewControllerRepresentable {
    @ObservedObject var viewModel: PhotoFRCController

    func makeUIViewController(context: Context) -> PhotoCollectionViewController {
        let vc = PhotoCollectionViewController()
        vc.viewModel = viewModel
        return vc
    }

    func updateUIViewController(_ uiViewController: PhotoCollectionViewController, context: Context) {}
}

struct ContentView: View {
    @Environment(\.managedObjectContext) var context
    @StateObject var viewModel: PhotoFRCController

    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: PhotoFRCController(context: context))
    }

    var body: some View {
        NavigationView {
            PhotoCollectionViewRepresentable(viewModel: viewModel)
                .navigationTitle("Photos")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // テスト用: ランダム色画像を追加
                            let size = CGSize(width: 100, height: 100)
                            UIGraphicsBeginImageContext(size)
                            UIColor.random.setFill()
                            UIRectFill(CGRect(origin: .zero, size: size))
                            let image = UIGraphicsGetImageFromCurrentImageContext()!
                            UIGraphicsEndImageContext()
                            viewModel.addPhoto(image)
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
        }
    }
}

extension UIColor {
    static var random: UIColor {
        UIColor(red: .random(in: 0...1),
                green: .random(in: 0...1),
                blue: .random(in: 0...1),
                alpha: 1)
    }
}

