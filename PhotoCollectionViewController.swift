//
//  PhotoCollectionViewController.swift
//  UICollectionViewInSwiftUI_2
//
//  Created by Yuki Sasaki on 2025/08/24.
//

import SwiftUI
import UIKit

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
        
        // 選択状態にしてもOKだが、通常タップで選択されないように
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true

        view.addSubview(collectionView)
        
        viewModel.attach(collectionView: collectionView)
        
        // 長押しで選択モードに入る
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPress)
    }

    // 長押しで選択モード開始
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: point) {
            isSelectionMode = true
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
            notifySelectionChanged()
        }
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
                print("isSelectionMode: \(isSelectionMode)")
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
