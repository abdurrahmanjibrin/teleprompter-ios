import SwiftUI
import UIKit

/// UIViewRepresentable yang menampung AVSampleBufferDisplayLayer untuk Picture-in-Picture
struct PiPContainerView: UIViewRepresentable {
    let prompterManager: PiPPrompterManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        prompterManager.attachToView(view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Tidak perlu update frame manual
    }
}

