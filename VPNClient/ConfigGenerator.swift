import Foundation

final class ConfigGenerator {
    static func makeConfig(for node: ProxyNode) -> String {
        var stream: [String: Any] = [:]
        stream["network"] = node.network ?? "tcp"
        stream["security"] = node.security ?? "none"

        if node.security == "reality" {
            stream["realitySettings"] = [
                "serverName": node.sni ?? node.server,
                "fingerprint": node.fp ?? "chrome",
                "publicKey": node.pbk ?? "",
                "shortId": node.sid ?? "",
                "spiderX": "/"
            ]
        } else if node.security == "tls" {
            stream["tlsSettings"] = [
                "serverName": node.sni ?? node.server,
                "allowInsecure": false,
                "fingerprint": node.fp ?? "chrome"
            ]
        }

        switch node.network {
        case "grpc":
            stream["grpcSettings"] = ["serviceName": node.serviceName ?? "", "multiMode": false]
        case "xhttp":
            stream["xhttpSettings"] = ["path": node.path ?? "/", "mode": "auto", "host": node.sni ?? node.server]
        case "ws":
            stream["wsSettings"] = ["path": node.path ?? "/", "headers": ["Host": node.sni ?? node.server]]
        default: break
        }

        let user: [String: Any] = ["id": node.uuid ?? "", "encryption": "none", "flow": node.flow ?? ""]
        let outbound: [String: Any] = [
            "protocol": "vless",
            "settings": ["vnext": [["address": node.server, "port": node.port, "users": [user]]]],
            "streamSettings": stream
        ]

        let config: [String: Any] = [
            "log": ["loglevel": "warning"],
            "inbounds": [["type": "tun", "tag": "tun-in", "settings": ["domainStrategy": "UseIP"], "sniffing": ["enabled": true, "destOverride": ["http", "tls"]]]],
            "outbounds": [outbound, ["protocol": "freedom", "tag": "direct"], ["protocol": "blackhole", "tag": "block"]],
            "routing": ["domainStrategy": "IPIfNonMatch", "rules": [["type": "field", "outboundTag": "direct", "domain": ["geosite:private"]]]]
        ]

        let data = try? JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted])
        return String(data: data ?? Data(), encoding: .utf8) ?? "{}"
    }
}