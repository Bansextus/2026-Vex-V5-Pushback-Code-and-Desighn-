import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case home = "Home"
    case build = "Build & Upload"
    case portMap = "Port Map"
    case sdCard = "SD Card"
    case field = "Field Replay"
    case readme = "README"
    case github = "Repository Settings"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .home:
            return "house.fill"
        case .build:
            return "hammer.fill"
        case .portMap:
            return "point.3.connected.trianglepath.dotted"
        case .sdCard:
            return "sdcard.fill"
        case .field:
            return "map.fill"
        case .readme:
            return "book.closed.fill"
        case .github:
            return "lock.shield.fill"
        }
    }
}

struct ProsProject: Identifiable {
    let id = UUID()
    var name: String
    var relativePath: String
    var slot: Int
}

struct PortValue {
    var value: Int
    var reversed: Bool

    func signed() -> Int {
        reversed ? -abs(value) : abs(value)
    }
}

struct PortMap {
    var leftOuter1 = PortValue(value: 1, reversed: true)
    var leftOuter2 = PortValue(value: 3, reversed: true)
    var leftMiddle = PortValue(value: 2, reversed: false)
    var rightOuter1 = PortValue(value: 4, reversed: false)
    var rightOuter2 = PortValue(value: 6, reversed: false)
    var rightMiddle = PortValue(value: 5, reversed: true)
    var intakeLeft = PortValue(value: 7, reversed: false)
    var intakeRight = PortValue(value: 8, reversed: false)
    var imu = 11
    var gps = 10
}
