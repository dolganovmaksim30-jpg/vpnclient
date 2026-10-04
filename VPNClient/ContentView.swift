import SwiftUI
import NetworkExtension

struct ContentView: View {
    @State private var subscriptionURL: String = ""
    @State private var nodes: [ProxyNode] = []
    @State private var status: String = "Отключено"
    @State private var isConnected = false
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ссылка на подписку (base64)").font(.caption)
                    TextField("https://...", text: $subscriptionURL)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }.padding(.horizontal)

                Button(action: loadSubscription) {
                    HStack {
                        if isLoading { ProgressView().tint(.white) }
                        Text("Загрузить серверы")
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.blue).foregroundColor(.white).cornerRadius(10)
                }.padding(.horizontal).disabled(isLoading || subscriptionURL.isEmpty)

                List(nodes, id: \.self) { node in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(node.name).font(.headline)
                        Text("\(node.type) - \(node.server):\(node.port)")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }.listStyle(.plain)

                VStack {
                    Text(status).font(.footnote).foregroundColor(.secondary)
                    Button(action: toggleVPN) {
                        Text(isConnected ? "Отключить" : "Подключить")
                            .frame(maxWidth: .infinity).padding()
                            .background(isConnected ? Color.red : Color.green)
                            .foregroundColor(.white).cornerRadius(10)
                    }
                }.padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("VPN Client")
        }
    }

    private func loadSubscription() {
        isLoading = true
        SubscriptionParser.fetchAndParse(urlString: subscriptionURL) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let parsed):
                    self.nodes = parsed
                    self.status = "Загружено: \(parsed.count)"
                case .failure(let err):
                    self.status = "Ошибка: \(err.localizedDescription)"
                }
            }
        }
    }

    private func toggleVPN() {
        guard let first = nodes.first else { status = "Нет серверов"; return }
        let config = ConfigGenerator.makeConfig(for: first)
        VPNManager.shared.toggle(config: config) { success in
            DispatchQueue.main.async {
                self.isConnected = success
                self.status = success ? "Подключено" : "Отключено"
            }
        }
    }
}