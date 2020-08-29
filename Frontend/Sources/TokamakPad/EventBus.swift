/// Workaround:
/// Currently, `onAppear` modifier fires events on **virtual** view node is created.
/// But I want to hook when **real** DOM node is mounted on the DOM tree.

import CombineShim

class EventBus {
    static let mounted = PassthroughSubject<Void, Never>()
}
