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

enum PlayerNodeState {
    case prepare
    case adding
    case added
    case canceled
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var addButton: UIButton!
    
    private var scanTimer: Timer?
    
    private var scannedFaceViews = [UIView]()
    private var foundFaces = [Face]()
    
    private var playerCreateState = PlayerNodeState.prepare
    private var lastFaceRecognized: VNFaceObservation?
    private var lastSceneBounds: CGRect!
    private var lastCameraTransform: simd_float4x4!
    
    private var newPlayer: STCPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
        self.addButton.layer.cornerRadius = self.addButton.frame.width / 2
        self.addButton.layer.borderColor = UIColor.white.cgColor
        self.addButton.layer.borderWidth = 2.0
        self.lastSceneBounds = self.sceneView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]

        // Run the view's session
        sceneView.session.run(configuration)
        
        self.scanTimer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(findFaces), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        self.scanTimer?.invalidate()
    }
    
    @IBAction func addPlayerButtonPressed(withButton button: UIButton) {
        print("button add pressed")
        self.playerCreateState = .adding
        
        let alertController = UIAlertController(title: "Add new player 😊", message: "Enter the name of the celebrity for the current player", preferredStyle: .alert)
        
        alertController.addTextField { (celebrityTextField) in
            celebrityTextField.placeholder = "Celebrity name"
        }
        
        alertController.addAction(UIAlertAction(title: "Create", style: .default, handler: { (alertAction) in
            self.playerCreateState = .added
            if let firstTextField = alertController.textFields?.first {
                self.newPlayer = STCPlayer(withCelebrityName: firstTextField.text!)
                if let lastFace = self.lastFaceRecognized {
                    self.playerCreateState = .prepare
                    DispatchQueue.main.async {
                        let face = Face(withFaceObservation: lastFace)
                        face.sceneViewBounds = self.lastSceneBounds
                        self.addFaceNode(withFaceObservation: face, andText: self.newPlayer!.celebrityName)
                        
                        let faceAnchor = ARAnchor(name: "face anchor", transform: self.lastCameraTransform)
                        self.sceneView.session.add(anchor: faceAnchor)
                        print("create action add node")
                    }
                }
            }
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (cancelAction) in
            self.playerCreateState = .prepare
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc private func findFaces() {
        self.scannedFaceViews.forEach { (frame) in
            frame.removeFromSuperview()
        }
        self.scannedFaceViews.removeAll()
        
        guard let capturedImage = self.sceneView.session.currentFrame?.capturedImage else { return }
        
        let image = CIImage(cvPixelBuffer: capturedImage)
        
        let detectedFaceRequest = VNDetectFaceLandmarksRequest { (request, error) in
            DispatchQueue.main.async {
                if let faces = request.results as? [VNFaceObservation] {
                    for face in faces {
                        if (self.playerCreateState == .prepare) {
                            let faceView = UIView(frame: face.recalculateBoundingBoxForCurrentSceneBounds(currentSceneBounds: self.sceneView.bounds))
                            
                            faceView.backgroundColor = .clear
                            faceView.layer.borderWidth = 2.0
                            faceView.layer.borderColor = UIColor.yellow.cgColor
                            
                            self.sceneView.addSubview(faceView)
                            self.scannedFaceViews.append(faceView)
                        }
                        self.lastFaceRecognized = face
                        self.lastSceneBounds = self.sceneView.bounds
                        if let currentFrame = self.sceneView.session.currentFrame {
                            self.lastCameraTransform = currentFrame.camera.transform
                        }
                    }
                }
            }
        }
        
        DispatchQueue.global().async {
            try? VNImageRequestHandler(ciImage: image, orientation: UIDevice.imageOrientation).perform([detectedFaceRequest])
        }
    }
    
    func addFaceNode(withFaceObservation newFace: Face, andText playerText: String) {
        let transformedFaceFrame = newFace.faceObservation.recalculateBoundingBoxForCurrentSceneBounds(currentSceneBounds: newFace.sceneViewBounds)
        
        if let vectorPosition = self.normalizeWorldCoord(transformedFaceFrame) {
            // Create text SCNNode
            let text = "№ " + String(Int.random(in: 0...10)) + " \(playerText)"
            var scnNodeWithText : SCNNode!
            if let fontSize = self.calculateFontSizeDependingOnDistanseBetweenCameraPointAndCurrePoint(withARFrame: self.sceneView.session.currentFrame, withCurrentPoint: vectorPosition) {
                scnNodeWithText = SCNNode(withText: text, position: vectorPosition, fontSize: CGFloat(fontSize))
            } else {
                scnNodeWithText = SCNNode(withText: text, position: vectorPosition)
            }
            
            newFace.scnNode = scnNodeWithText
            self.foundFaces.append(newFace)
            
            // Add to current scene this node
            self.sceneView.scene.rootNode.addChildNode(scnNodeWithText)
            scnNodeWithText.show()
        }
    }
}

extension ViewController {
    fileprivate func normalizeWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
        
        var array: [SCNVector3] = []
        for _ in 0...1 {
            if let position = self.determineWorldCoord(boundingBox) {
                array.append(position)
            }
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
        print("determine hit test with bounding box \(boundingBox)")
        let arHitTestResults = self.sceneView.hitTest(CGPoint(x: boundingBox.minX, y: boundingBox.maxY), types: [.featurePoint])
        
        // Filter results that are to close
        if let closestResult = arHitTestResults.filter({ $0.distance > 0.10 }).first {
            return SCNVector3.positionFromTransform(closestResult.worldTransform)
        }
        return nil
    }

}

extension ViewController {
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
}
