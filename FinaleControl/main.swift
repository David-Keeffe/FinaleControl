import Cocoa

let applog = Logger(appname: "com.music3149.jsplugin", location: "delegate")
let applicationDelegate = AppDelegate()
let application = NSApplication.shared
application.setActivationPolicy(NSApplication.ActivationPolicy.accessory)
application.delegate = applicationDelegate
//application.run()
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
