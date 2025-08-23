//
//  UICollectionViewInSwiftUI_2App.swift
//  UICollectionViewInSwiftUI_2
//
//  Created by Yuki Sasaki on 2025/08/23.
//

import SwiftUI
import UIKit
import CoreData

/*@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let nav = UINavigationController()
        let rootVC = PhotoPickerViewController()
        nav.viewControllers = [rootVC]

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()

        return true
    }
}*/

@main
struct MyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(context: persistenceController.container.viewContext)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
