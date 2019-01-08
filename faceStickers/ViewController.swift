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
    private var foundFaces = [Face]()
    
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
        
        self.scanTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(findFaces), userInfo: nil, repeats: true)
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
    
    
    @objc private func findFaces() {
        guard let capturedImage = self.sceneView.session.currentFrame?.capturedImage else { return }
        
        let image = CIImage(cvPixelBuffer: capturedImage)
        
        let detectedFaceRequest = VNDetectFaceLandmarksRequest { (request, error) in
            DispatchQueue.main.async {
                if let faces = request.results as? [VNFaceObservation] {
                    for face in faces {
                        let newFace = Face(withFaceObservation: face)
                        if (!self.foundFaces.contains(newFace)) {
                            self.addFaceNode(withFaceObservation: newFace)
                        }
                    }
                }
            }
        }
        
        DispatchQueue.global().async {
            try? VNImageRequestHandler(ciImage: image, orientation: self.imageOrientation).perform([detectedFaceRequest])
        }
    }
    
    func addFaceNode(withFaceObservation newFace: Face) {
        let transformedFaceFrame = self.faceFrame(from: newFace.faceObservation.boundingBox)
        if (self.normalizeWorldCoord(transformedFaceFrame) != nil) {
            let position = self.normalizeWorldCoord(transformedFaceFrame)!
            // Create text SCNNode
            let text = "Hello face " + String(Int.random(in: 0...10))
            let scnNodeWithText = SCNNode(withText: text, position: position)
            
            newFace.scnNode = scnNodeWithText
            self.foundFaces.append(newFace)
            
            // Add to current scene this node
            self.sceneView.scene.rootNode.addChildNode(scnNodeWithText)
            scnNodeWithText.show()
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
        sceneView.session.run(session.configuration!,
                              options: [.resetTracking,
                                        .removeExistingAnchors])
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
    
    private func normalizeWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
        
        var array: [SCNVector3] = []
        Array(0...2).forEach{_ in
            if let position = determineWorldCoord(boundingBox) {
                array.append(position)
            }
            //usleep(12000) // .012 seconds
        }
        
        if array.isEmpty {
            return nil
        }
        
        return SCNVector3.center(array)
    }
    
    
    /// Determine the vector from the position on the screen.
    ///
    /// - Parameter boundingBox: Rect of the face on the screen
    /// - Returns: the vector in the sceneView
    private func determineWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
        let arHitTestResults = sceneView.hitTest(CGPoint(x: boundingBox.midX, y: boundingBox.midY), types: [.featurePoint])
        
        // Filter results that are to close
        if let closestResult = arHitTestResults.filter({ $0.distance > 0.10 }).first {
            //            print("vector distance: \(closestResult.distance)")
            return SCNVector3.positionFromTransform(closestResult.worldTransform)
        }
        return nil
    }
}
