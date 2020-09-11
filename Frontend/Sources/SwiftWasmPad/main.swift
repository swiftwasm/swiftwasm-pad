enum Mode: UInt8 {
    case linker = 0
    case application = 1
}

#if Xcode
func provideMode() -> Mode { fatalError() }
#else
@_silgen_name("_provide_mode")
func provideMode() -> Mode
#endif

switch provideMode() {
case .linker:
    try linkerMain()
case .application:
    appMain()
}
