import SwiftUI
import Foundation

#if os(macOS) || os(iOS)
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
#elseif os(Linux)
//linuxLaunch()
#endif
