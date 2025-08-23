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

struct CollectionViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal // LazyHGrid の横スクロールに合わせる
        layout.itemSize = CGSize(width: 100, height: 100)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        uiView.reloadData()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
        let items = Array(0..<10)
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return items.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
            cell.backgroundColor = .blue
            return cell
        }
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) var context
    @StateObject var viewModel: PhotoFRCViewModel
    @State private var isPickerPresented = false
    @State private var selectedItems: [PhotosPickerItem] = []

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: PhotoFRCViewModel(context: context))
    }

    let columns = [
        GridItem(.fixed(120)),
        GridItem(.fixed(120)),
        GridItem(.fixed(120))
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(viewModel.photos, id: \.id) { photo in
                        if let data = photo.imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipped()
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Photos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPickerPresented = true
                    }) {
                        Image(systemName: "plus") // + ボタン
                    }
                }
            }
            .photosPicker(isPresented: $isPickerPresented, selection: $selectedItems, matching: .images)
            .onChange(of: selectedItems) { newItems in
                for item in newItems {
                    item.loadTransferable(type: Data.self) { result in
                        switch result {
                        case .success(let data?):
                            if let uiImage = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    viewModel.addPhoto(uiImage)
                                }
                            }
                        case .success(nil):
                            break
                        case .failure(let error):
                            print("Picker error: \(error)")
                        }
                    }
                }
            }
        }
    }
}
