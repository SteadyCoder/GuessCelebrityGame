//
//  FaceRecognizeCalculations.swift
//  faceStickers
//
//  Created by Ivan Tkachenko on 1/9/19.
//  Copyright © 2019 steadyIvan. All rights reserved.
//

import Vision
import ARKit

extension VNFaceObservation {
    func recalculateBoundingBoxForCurrentSceneBounds(currentSceneBounds bounds: CGRect) -> CGRect {
        //translate camera frame to frame inside the ARSKView
        let origin = CGPoint(x: self.boundingBox.minX * bounds.width, y: (1 - self.boundingBox.maxY) * bounds.height)
        let size = CGSize(width: self.boundingBox.width * bounds.width, height: self.boundingBox.height * bounds.height)
        
        return CGRect(origin: origin, size: size)
    }
}

extension UIDevice {
    static var imageOrientation: CGImagePropertyOrientation {
        switch UIDevice.current.orientation {
            case .portrait:
                return .right
            case .landscapeRight:
                return .down
            case .portraitUpsideDown:
                return .left
            case .unknown: fallthrough
            case .faceUp: fallthrough
            case .faceDown: fallthrough
            case .landscapeLeft:
                return .up
        }
    }
}

extension ViewController {
    public func calculateFontSizeDependingOnDistanseBetweenCameraPointAndCurrePoint(withARFrame currentFrame: ARFrame?, withCurrentPoint currentPoint: SCNVector3) -> Float? {
        // Camera point
        var distanceBetweenPoint : Float? = nil
        if let currentFrame = currentFrame {
            let cameraPosition = currentFrame.camera.transform.columns.3
            distanceBetweenPoint = self.distanceTravelled(between: currentPoint, and: SCNVector3(cameraPosition.x, cameraPosition.y, cameraPosition.z))
        }
        
        var fontSize: Float? = nil
        if let distance = distanceBetweenPoint {
            if distance < 0.3 {
                fontSize = Float(0.085)
            } else if distance >= 0.3, distance <= 0.5 {
                fontSize = Float(0.1)
            } else if distance > 0.5, distance <= 0.7 {
                fontSize = Float(0.15)
            } else if distance > 0.7, distance <= 1.5 {
                fontSize = Float(0.3)
            } else if distance > 1.5 {
                fontSize = Float(0.25)
            }
        }
        return fontSize
    }
    
    
    private func distanceTravelled(xDist:Float, yDist:Float, zDist:Float) -> Float{
        return sqrt((xDist * xDist) + (yDist * yDist) + (zDist * zDist))
    }
    
    private func distanceTravelled(between v1:SCNVector3,and v2:SCNVector3) -> Float{
        let xDist = v1.x - v2.x
        let yDist = v1.y - v2.y
        let zDist = v1.z - v2.z
        
        return distanceTravelled(xDist: xDist, yDist: yDist, zDist: zDist)
    }
}
