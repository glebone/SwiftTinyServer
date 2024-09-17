#if os(Linux)
import Foundation

func linuxMain() {
    linuxLaunch()
}

//@main
struct LinuxApp {
    static func main() {
        linuxMain()
    }
}
#endif
