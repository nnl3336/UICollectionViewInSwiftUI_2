//
//  ContentView.swift
//  UICollectionViewInSwiftUI_2
//
//  Created by Yuki Sasaki on 2025/08/23.
//
import SwiftUI
import CoreData
import UIKit

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

// MARK: - UICollectionViewController
class PhotoCollectionViewController: UIViewController,
                                     UICollectionViewDataSource,
                                     UICollectionViewDelegateFlowLayout {
    private var collectionView: UICollectionView!
    var viewModel: PhotoFRCController!

    var onSelectPhoto: ((Photo) -> Void)?
    var onSelectMultiple: (([Photo]) -> Void)?

    private var isSelectionMode = false   // ← 選択モードフラグ追加

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
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.allowsMultipleSelection = true
        view.addSubview(collectionView)

        viewModel.attach(collectionView: collectionView)
    }

    // MARK: - Context Menu
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {

        guard let photo = viewModel.photo(at: indexPath.item) else { return nil }

        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil) { _ in
            let select = UIAction(title: "選択モードに入る",
                                  image: UIImage(systemName: "checkmark.circle")) { _ in
                self.isSelectionMode = true
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
                self.notifySelectionChanged()
            }

            let delete = UIAction(title: "削除",
                                  image: UIImage(systemName: "trash"),
                                  attributes: .destructive) { _ in
                self.viewModel.delete(photo)
            }

            return UIMenu(title: "", children: [select, delete])
        }
    }

    // MARK: - Delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isSelectionMode {
            notifySelectionChanged()
        } else {
            if let photo = viewModel.photo(at: indexPath.item) {
                onSelectPhoto?(photo)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if isSelectionMode {
            notifySelectionChanged()
        }
    }

    private func notifySelectionChanged() {
        let selectedIndexPaths = collectionView.indexPathsForSelectedItems ?? []
        let photos = selectedIndexPaths.compactMap { viewModel.photo(at: $0.item) }
        onSelectMultiple?(photos)
    }

    // MARK: - DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.numberOfItems
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoCollectionViewCell
        if let photo = viewModel.photo(at: indexPath.item),
           let data = photo.imageData,
           let uiImage = UIImage(data: data) {
            cell.imageView.image = uiImage
        }
        return cell
    }

    // MARK: - Public API
    func exitSelectionMode() {
        isSelectionMode = false
        collectionView.indexPathsForSelectedItems?.forEach {
            collectionView.deselectItem(at: $0, animated: false)
        }
        notifySelectionChanged()
    }
}

class PhotoCollectionViewCell: UICollectionViewCell {
    let imageView = UIImageView()
    private let overlayView = UIView()
    private let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))

    override init(frame: CGRect) {
        super.init(frame: frame)

        // 画像ビュー
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = contentView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(imageView)

        // 半透明オーバーレイ
        overlayView.backgroundColor = UIColor(white: 0, alpha: 0.3)
        overlayView.frame = contentView.bounds
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.isHidden = true
        contentView.addSubview(overlayView)

        // チェックマーク
        checkmark.tintColor = .systemBlue
        checkmark.frame = CGRect(x: contentView.bounds.width - 24, y: 4, width: 20, height: 20)
        checkmark.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        checkmark.isHidden = true
        contentView.addSubview(checkmark)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            overlayView.isHidden = !isSelected
            checkmark.isHidden = !isSelected
            layer.borderWidth = isSelected ? 2 : 0
            layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : nil
        }
    }
}


// MARK: - SwiftUI Wrapper
struct PhotoCollectionViewRepresentable: UIViewControllerRepresentable {
    @ObservedObject var viewModel: PhotoFRCController
    var onSelectPhoto: ((Photo) -> Void)?
    var onSelectMultiple: (([Photo]) -> Void)?

    func makeUIViewController(context: Context) -> PhotoCollectionViewController {
        let vc = PhotoCollectionViewController()
        vc.viewModel = viewModel
        vc.onSelectPhoto = onSelectPhoto
        vc.onSelectMultiple = onSelectMultiple
        return vc
    }

    func updateUIViewController(_ uiViewController: PhotoCollectionViewController, context: Context) {}
}

// MARK: - SwiftUI View
struct ContentView: View {
    @StateObject var viewModel = PhotoFRCController(context: PersistenceController.shared.container.viewContext)
    @State private var selectedPhoto: Photo?
    @State private var selectedPhotos: [Photo] = []
    
    var body: some View {
        VStack {
            PhotoCollectionViewRepresentable(viewModel: viewModel,
                                             onSelectPhoto: { photo in
                selectedPhoto = photo
            },
                                             onSelectMultiple: { photos in
                selectedPhotos = photos
            })
            
            if let photo = selectedPhoto,
               let data = photo.imageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            
            if !selectedPhotos.isEmpty {
                Text("\(selectedPhotos.count) 枚選択中")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Button("選択解除") {
                    // PhotoCollectionViewController に公開している API を呼ぶ
                    if let controller = findController() {
                        controller.exitSelectionMode()
                    }
                    selectedPhotos.removeAll()
                }
                .padding()
            }
        }
    }
    
    // Representable から UIViewController を引っ張り出すヘルパー
    private func findController() -> PhotoCollectionViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .flatMap { getAllChildren($0) }
            .compactMap { $0 as? PhotoCollectionViewController }
            .first
    }
    
    private func getAllChildren(_ vc: UIViewController) -> [UIViewController] {
        return [vc] + vc.children.flatMap { getAllChildren($0) }
    }
}

// MARK: - Helper
extension UIColor {
    static var random: UIColor {
        UIColor(red: .random(in: 0...1),
                green: .random(in: 0...1),
                blue: .random(in: 0...1),
                alpha: 1)
    }
}
