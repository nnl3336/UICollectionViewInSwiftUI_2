//
//  ContentView.swift
//  UICollectionViewInSwiftUI_2
//
//  Created by Yuki Sasaki on 2025/08/23.
//

import UIKit
import PhotosUI
import SwiftUI
import UIKit

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
    let rows = [GridItem(.fixed(120))] // LazyHGrid の行サイズ

    var body: some View {
        ScrollView(.horizontal) {
            LazyHGrid(rows: rows, spacing: 10) {
                ForEach(0..<5) { _ in
                    CollectionViewRepresentable()
                        .frame(width: 120, height: 120) // 表示サイズ必須
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
            }
            .padding()
        }
    }
}
