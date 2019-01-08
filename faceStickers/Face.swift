//
//  Face.swift
//  faceStickers
//
//  Created by Ivan Tkachenko on 1/8/19.
//  Copyright © 2019 steadyIvan. All rights reserved.
//

import ARKit
import Vision

class Face {
    static let comparePointDeriviation = CGFloat(0.08)
    
    public private (set) var faceIdentifier: String
    public var scnNode : SCNNode?
    
    public var faceObservation: VNFaceObservation
    
    private init() {
        self.faceIdentifier = UUID().uuidString
        self.faceObservation = VNFaceObservation(boundingBox: CGRect.zero)
    }
    
    convenience init(withFaceObservation faceObservation: VNFaceObservation) {
        self.init()
        self.faceObservation = faceObservation
    }
    
}

extension Face: Equatable {
    static func == (firstFace: Face, secondFace: Face) -> Bool {
        var result = false
        
        if let firstLandmarks = firstFace.faceObservation.landmarks?.allPoints, let secondLandmarks = secondFace.faceObservation.landmarks?.allPoints {
            for i in 0..<firstLandmarks.normalizedPoints.count {
                let firstPoint = firstLandmarks.normalizedPoints[i]
                let secondPoint = secondLandmarks.normalizedPoints[i]
                //  x1 - 0.07 <= x2 <= x1 + 0.07
                //  y1 - 0.07 <= y2 <= y1 + 0.07
                if (secondPoint.x <= firstPoint.x + comparePointDeriviation && secondPoint.x >= firstPoint.x - comparePointDeriviation &&
                    secondPoint.y <= firstPoint.y + comparePointDeriviation && secondPoint.y >= firstPoint.y - comparePointDeriviation) {
                    result = true
                } else {
                    result = false
                    break;
                }
            }
        }
        
        return result
    }
}
