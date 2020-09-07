import JavaScriptKit

class KeyBinding {
    enum Event: Equatable {
        case ctrlAndEnter

        init?(keyboardEvent event: JSObjectRef) {
            let isCtrlKey = event.ctrlKey.boolean!
            let isMetaKey = event.metaKey.boolean!
            let isEnter = event.keyCode.number == 13
            if (isCtrlKey || isMetaKey) && isEnter {
                self = .ctrlAndEnter
            } else {
                return nil
            }
        }
    }
    
    typealias Handler = (Event) -> Void
    private var eventTarget: JSObjectRef
    private var handlers: [Handler] = []
    
    private lazy var jsListener = JSClosure { [weak self] args in
        guard let event = KeyBinding.Event(keyboardEvent: args[0].object!) else {
            return .undefined
        }
        self?.handleEvent(event)
        return .undefined
    }
    
    
    private func handleEvent(_ event: Event) {
        handlers.forEach { $0(event) }
    }

    func listen(_ handler: @escaping Handler) {
        handlers.append(handler)
    }

    init(on window: JSObjectRef) {
        self.eventTarget = window
        _ = window.addEventListener!("keydown", jsListener)
    }
    
    deinit {
        _ = eventTarget.removeEventListener!("keydown", jsListener)
        jsListener.release()
    }
}

import TokamakDOM

let keyBinding = KeyBinding(on: JSObjectRef.global)

extension View {
    func bindKey(_ event: KeyBinding.Event, _ handler: @escaping () -> Void) -> some View {
        _onMount {
            keyBinding.listen {
                guard $0 == event else { return }
                handler()
            }
        }
    }
}
