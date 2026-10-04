import Foundation

struct ProxyNode: Hashable {
    var name: String
    var type: String
    var server: String
    var port: Int
    var uuid: String?
    var password: String?
    var security: String?
    var sni: String?
    var flow: String?
    var network: String?
    var path: String?
    var serviceName: String?
    var pbk: String?
    var sid: String?
    var fp: String?
}

final class SubscriptionParser {
    static func fetchAndParse(urlString: String, completion: @escaping (Result<[ProxyNode], Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "bad url", code: 0))); return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else {
                completion(.failure(NSError(domain: "no data", code: 0))); return
            }
            let raw = String(data: data, encoding: .utf8) ?? ""
            let decoded = decodeBase64IfNeeded(raw)
            completion(.success(parseLines(decoded)))
        }.resume()
    }

    private static func decodeBase64IfNeeded(_ text: String) -> String {
        if text.contains("://") { return text }
        let cleaned = text.replacingOccurrences(of: "\n", with: "")
                           .replacingOccurrences(of: "\r", with: "")
                           .trimmingCharacters(in: .whitespaces)
        if let data = Data(base64Encoded: cleaned, options: .ignoreUnknownCharacters),
           let decoded = String(data: data, encoding: .utf8) { return decoded }
        return text
    }

    private static func parseLines(_ text: String) -> [ProxyNode] {
        var result: [ProxyNode] = []
        for line in text.components(separatedBy: .newlines) {
            let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { continue }
            if t.lowercased().hasPrefix("vless://"), let n = parseVLESS(t) { result.append(n) }
            if t.lowercased().hasPrefix("hysteria2://") || t.lowercased().hasPrefix("hy2://"),
               let n = parseHysteria2(t) { result.append(n) }
        }
        return result
    }

    private static func parseVLESS(_ link: String) -> ProxyNode? {
        guard let c = URLComponents(string: link) else { return nil }
        var p: [String: String] = [:]
        c.queryItems?.forEach { p[$0.name.lowercased()] = $0.value ?? "" }
        return ProxyNode(name: c.fragment?.removingPercentEncoding ?? (c.host ?? ""),
                         type: "vless", server: c.host ?? "", port: c.port ?? 443,
                         uuid: c.user, password: nil,
                         security: p["security"], sni: p["sni"], flow: p["flow"],
                         network: p["type"] ?? "tcp", path: p["path"],
                         serviceName: p["servicename"], pbk: p["pbk"],
                         sid: p["sid"], fp: p["fp"] ?? "chrome")
    }

    private static func parseHysteria2(_ link: String) -> ProxyNode? {
        guard let c = URLComponents(string: link) else { return nil }
        var p: [String: String] = [:]
        c.queryItems?.forEach { p[$0.name.lowercased()] = $0.value ?? "" }
        return ProxyNode(name: c.fragment?.removingPercentEncoding ?? (c.host ?? ""),
                         type: "hysteria2", server: c.host ?? "", port: c.port ?? 443,
                         uuid: nil, password: c.user?.removingPercentEncoding ?? "",
                         security: p["security"] ?? "tls", sni: p["sni"],
                         flow: nil, network: nil, path: p["path"],
                         serviceName: nil, pbk: nil, sid: nil, fp: p["fp"])
    }
}