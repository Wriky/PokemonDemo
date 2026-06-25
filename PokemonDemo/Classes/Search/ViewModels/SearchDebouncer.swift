import Combine
import Foundation

@MainActor
final class SearchDebouncer: ObservableObject {
    private let delay: Duration
    private var pendingTask: Task<Void, Never>?

    init(delay: Duration = .milliseconds(500)) {
        self.delay = delay
    }

    func schedule(action: @escaping @MainActor () async -> Void) {
        pendingTask?.cancel()
        pendingTask = Task {
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            pendingTask = nil

            Task {
                await action()
            }
        }
    }

    func cancel() {
        pendingTask?.cancel()
        pendingTask = nil
    }
}
