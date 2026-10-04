import Foundation
import NetworkExtension

final class VPNManager {
    static let shared = VPNManager()
    private init() {}
    private var manager: NETunnelProviderManager?

    func toggle(config: String, completion: @escaping (Bool) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { managers, _ in
            let mgr = managers?.first ?? NETunnelProviderManager()
            self.manager = mgr
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = "com.example.vpnclient.tunnel"
            proto.serverAddress = "VPNClient"
            proto.providerConfiguration = ["config": config]
            mgr.protocolConfiguration = proto
            mgr.localizedDescription = "VPNClient"
            mgr.isEnabled = true
            mgr.saveToPreferences { error in
                if error != nil { completion(false); return }
                mgr.loadFromPreferences { _ in
                    do {
                        try mgr.connection.startVPNTunnel()
                        completion(true)
                    } catch { completion(false) }
                }
            }
        }
    }

    func stop() { manager?.connection.stopVPNTunnel() }
}