/// Workaround:
/// Currently, `onAppear` modifier fires events on **virtual** view node is created.
/// But I want to hook when **real** DOM node is mounted on the DOM tree.

import CombineShim

class EventBus {
    static let mounted = PassthroughSubject<Void, Never>()
    static let stdout = PassthroughSubject<String, Never>()
    static let stderr = PassthroughSubject<String, Never>()
    static let flush = PassthroughSubject<Void, Never>()
}
