import Foundation
import Network

protocol NetworkMonitoring: AnyObject {
    var isConnected: Bool { get }
    var onChange: ((Bool) -> Void)? { get set }
}

final class NetworkMonitor: NetworkMonitoring {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private(set) var isConnected: Bool = true

    var onChange: ((Bool) -> Void)?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            self?.isConnected = connected
            DispatchQueue.main.async {
                self?.onChange?(connected)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
