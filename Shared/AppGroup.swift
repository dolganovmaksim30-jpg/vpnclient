import Foundation

enum AppGroup {
    static let identifier = "group.com.example.vpnclient"
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}