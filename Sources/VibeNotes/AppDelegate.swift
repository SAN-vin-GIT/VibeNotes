import SwiftUI
import AppKit

struct TriggerButtonView: View {
    var onToggle: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onToggle) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    // High-contrast adaptive background: dark with light border
                    .fill(Color(white: 0.15).opacity(isHovered ? 0.8 : 0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 1)
                
                Capsule()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 2, height: 20)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: SidePanel?
    var handleWindow: NSWindow?
    var noteStore = NoteStore()
    
    private var isExpanded = true
    private var isCompactHeight = false
    private let panelWidth: CGFloat = 390
    private let handleWidth: CGFloat = 8
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupPanel()
        setupHandle()
        setupMenu()
        // Start expanded, then collapse after a delay for effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.togglePanel(expand: false)
        }
    }
    
    func setupMenu() {
        let mainMenu = NSMenu()
        
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "Quit \(ProcessInfo.processInfo.processName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu
        
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(NSMenuItem.separator())
        
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        
        NSApp.mainMenu = mainMenu
    }
    
    func setupPanel() {
        let screen = NSScreen.main!
        let panelHeight = screen.visibleFrame.height
        
        let rect = NSRect(x: screen.visibleFrame.maxX - panelWidth, y: screen.visibleFrame.minY, width: panelWidth, height: panelHeight)
        
        let panel = SidePanel(
            contentRect: rect,
            backing: .buffered,
            defer: false
        )
        
        let contentView = ContentView()
            .environmentObject(noteStore)
        
        panel.contentView = NSHostingView(rootView: contentView)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }
    
    func setupHandle() {
        let screen = NSScreen.main!
        let buttonWidth: CGFloat = 14
        let buttonHeight: CGFloat = 100
        let rect = NSRect(x: screen.visibleFrame.maxX - buttonWidth, 
                          y: screen.visibleFrame.midY - (buttonHeight / 2), 
                          width: buttonWidth, 
                          height: buttonHeight)
        
        let window = NSWindow(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating + 1 // Always on top of the panel
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        let triggerView = TriggerButtonView { [weak self] in
            guard let self = self else { return }
            self.togglePanel(expand: !self.isExpanded)
        }
        
        window.contentView = NSHostingView(rootView: triggerView)
        window.makeKeyAndOrderFront(nil)
        self.handleWindow = window
    }
    
    func toggleHeight() {
        guard let panel = panel, let screen = NSScreen.main else { return }
        isCompactHeight.toggle()
        
        let screenFrame = screen.visibleFrame
        let targetHeight = isCompactHeight ? screenFrame.height / 2 : screenFrame.height
        let targetY = isCompactHeight ? screenFrame.midY - (targetHeight / 2) : screenFrame.minY
        
        var newFrame = panel.frame
        newFrame.size.height = targetHeight
        newFrame.origin.y = targetY
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(newFrame, display: true)
        }
    }
    
    func togglePanel(expand: Bool) {
        guard let panel = panel, let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let targetX = expand ? screenFrame.maxX - panelWidth : screenFrame.maxX
        
        // Respect current height and Y position
        var newFrame = panel.frame
        newFrame.origin.x = targetX
        
        let handleTargetX = (expand ? screenFrame.maxX - panelWidth : screenFrame.maxX) - (handleWindow?.frame.width ?? 0)
        var handleFrame = handleWindow?.frame ?? .zero
        handleFrame.origin.x = handleTargetX
        
        // When expanding, make visible immediately before animation starts
        if expand {
            panel.alphaValue = 1
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            panel.animator().setFrame(newFrame, display: true)
            handleWindow?.animator().setFrame(handleFrame, display: true)
        } completionHandler: {
            self.isExpanded = expand
            // When collapsed, make fully transparent so macOS can't flash it during Space transitions
            if !expand {
                panel.alphaValue = 0
            }
        }
    }
}
