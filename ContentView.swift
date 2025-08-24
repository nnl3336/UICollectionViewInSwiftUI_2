//
//  ContentView.swift
//  UICollectionViewInSwiftUI_2
//
//  Created by Yuki Sasaki on 2025/08/23.
//
import SwiftUI
import CoreData
import UIKit

// MARK: - SwiftUI View
struct ContentView: View {
    @StateObject var viewModel = PhotoFRCController(context: PersistenceController.shared.container.viewContext)
    @State private var selectedPhoto: Photo?
    @State private var selectedPhotos: [Photo] = []
    @State private var isSelectionMode = false
    
    var body: some View {
        VStack {
            PhotoCollectionViewRepresentable(viewModel: viewModel,
                                             onSelectPhoto: { photo in
                selectedPhoto = photo
            },
                                             onSelectMultiple: { photos in
                selectedPhotos = photos
            })
            
            /*if let photo = selectedPhoto,
               let data = photo.imageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }*/
            
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
        .onChange(of: selectedPhotos) { newValue in
            if newValue.isEmpty {
                isSelectionMode = false
            } else {
                isSelectionMode = true
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
