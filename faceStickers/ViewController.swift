//
//  ViewController.swift
//  faceStickers
//
//  Created by Ivan Tkachenko on 1/7/19.
//  Copyright © 2019 steadyIvan. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    private var scanTimer: Timer?
    private var foundFacesView = [UIView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]

        // Run the view's session
        sceneView.session.run(configuration)
        
        self.scanTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(findFaces), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
        self.scanTimer?.invalidate()
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        print("render nodes")
        
        
        
        return nil
    }

    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        print("scene rendered")
        
    }
    
    @objc private func findFaces() {
        self.foundFacesView.forEach { (faceView) in
            faceView.removeFromSuperview()
        }
        self.foundFacesView.removeAll()
        
        guard let capturedImage = self.sceneView.session.currentFrame?.capturedImage else { return }
        
        let image = CIImage(cvPixelBuffer: capturedImage)
        
        let detectedFaceRequest = VNDetectFaceLandmarksRequest { (request, error) in
            DispatchQueue.main.async {
                if let faces = request.results as? [VNFaceObservation] {
                    for face in faces {
                        let faceView = UIView(frame: self.faceFrame(from: face.boundingBox))
                        
                        faceView.backgroundColor = UIColor.clear
                        faceView.layer.borderColor = UIColor.yellow.cgColor
                        faceView.layer.borderWidth = 2.0
                        
                        self.sceneView.addSubview(faceView)
                        
                        self.foundFacesView.append(faceView)
                    }
                }
            }
        }
        
        DispatchQueue.global().async {
            try? VNImageRequestHandler(ciImage: image, orientation: self.imageOrientation).perform([detectedFaceRequest])
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .limited(.initializing):
            print("Initializaint")
        case .normal:
            print("works fine")
        case .notAvailable:
            print("ooppssss")
        case .limited(.excessiveMotion):
            print("slower please")
        case .limited(.insufficientFeatures):
            print("control your camera")
        case .limited(.relocalizing):
            print("wait please")
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    private func faceFrame(from boundingBox: CGRect) -> CGRect {
        
        //translate camera frame to frame inside the ARSKView
        let origin = CGPoint(x: boundingBox.minX * self.sceneView.bounds.width, y: (1 - boundingBox.maxY) * self.sceneView.bounds.height)
        let size = CGSize(width: boundingBox.width * self.sceneView.bounds.width, height: boundingBox.height * self.sceneView.bounds.height)
        
        return CGRect(origin: origin, size: size)
    }
    
    private var imageOrientation: CGImagePropertyOrientation {
        switch UIDevice.current.orientation {
        case .portrait: return .right
        case .landscapeRight: return .down
        case .portraitUpsideDown: return .left
        case .unknown: fallthrough
        case .faceUp: fallthrough
        case .faceDown: fallthrough
        case .landscapeLeft: return .up
        }
    }
}
