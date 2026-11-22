import SwiftUI
import Playgrounds

struct ContentView: View {
    @State private var host: String = "8.8.8.8"
    @State private var statusText: String = "Готов к запуску"
    @State private var isRunning: Bool = false
    @State private var pingTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 16) {
            TextField("IP или домен:", text: $host)
                .textFieldStyle(.roundedBorder)
                .disabled(isRunning)

            Text(statusText)

            Button(isRunning ? "Остановить" : "Начать проверку (1 час)") {
                if isRunning {
                    stopPing()
                } else {
                    startPing()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(isRunning ? .red : .green)
        }
        .padding()
        .frame(width: 320, height: 180)
    }

    private func startPing() {
        isRunning = true
        statusText = "Проверяю \(host)..."

        pingTask = Task {
            let endTime = Date().addingTimeInterval(3600)

            while Date() < endTime && !Task.isCancelled {
                let success = await runPingProcess(target: host)

                if success {
                    statusText = "Хост \(host) доступен!"
                    NSSound.beep() // Звуковой сигнал при успехе
                    isRunning = false
                    return
                }

                statusText = "Нет ответа. Повтор через 5 секунд..."
                try? await Task.sleep(for: .seconds(5))
            }

            if !Task.isCancelled {
                statusText = "Время вышло (1 час)."
                isRunning = false
            }
        }
    }

    private func stopPing() {
        pingTask?.cancel()
        isRunning = false
        statusText = "Остановлено пользователем"
    }

    private func runPingProcess(target: String) async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                let process = Process()
                process.executableURL = URL(filePath: "/sbin/ping")
                process.arguments = ["-c", "4", "-t", "5", target]
                process.standardOutput = FileHandle.nullDevice
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()
                    continuation.resume(returning: process.terminationStatus == 0)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

#Playground {
    _ = 1 + 2
}
