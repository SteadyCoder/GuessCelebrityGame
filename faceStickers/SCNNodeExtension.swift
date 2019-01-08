//
//  SCNNodeExtension.swift
//  faceStickers
//
//  Created by Ivan Tkachenko on 1/8/19.
//  Copyright © 2019 steadyIvan. All rights reserved.
//

import Foundation
import ARKit

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(red:   .random(),
                       green: .random(),
                       blue:  .random(),
                       alpha: 1.0)
    }
}

extension SCNNode {
    convenience init(withText text : String, position: SCNVector3) {
        let bubbleDepth : Float = 0.01 // the 'depth' of 3D text
        
        // TEXT BILLBOARD CONSTRAINT
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // BUBBLE-TEXT
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        bubble.font = UIFont(name: "Futura", size: 0.15)?.withTraits(traits: .traitBold)
        bubble.alignmentMode =  CATextLayerAlignmentMode.center.rawValue
        bubble.firstMaterial?.diffuse.contents = UIColor.white
        bubble.firstMaterial?.specular.contents = UIColor.black
        bubble.firstMaterial?.isDoubleSided = true
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation(maxBound.x, minBound.y, bubbleDepth / 2)
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.1, 0.1, 0.1)
        bubbleNode.simdPosition = simd_float3.init(x: 0.06, y: 0.09, z: 0)
        
        self.init()
        addChildNode(bubbleNode)
        constraints = [billboardConstraint]
        self.position = position
    }
    
    func transformNodeMethod(withText text: String) {
        let bubbleDepth : Float = 0.01 // the 'depth' of 3D text
        
        // TEXT BILLBOARD CONSTRAINT
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // BUBBLE-TEXT
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        bubble.font = UIFont(name: "Futura", size: 0.1)?.withTraits(traits: .traitBold)
        bubble.alignmentMode =  CATextLayerAlignmentMode.center.rawValue
        bubble.firstMaterial?.diffuse.contents = UIColor.random()
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation(maxBound.x, minBound.y, bubbleDepth / 2)
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.1, 0.1, 0.1)
        bubbleNode.simdPosition = simd_float3.init(x: 0, y: 0, z: 0)
        
        addChildNode(bubbleNode)
        constraints = [billboardConstraint]
    }
    
    func move(_ position: SCNVector3)  {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.4
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.linear)
        self.position = position
        opacity = 1
        SCNTransaction.commit()
    }
    
    func hide()  {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.linear)
        opacity = 0
        SCNTransaction.commit()
    }
    
    func show()  {
        opacity = 0
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.4
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.linear)
        opacity = 1
        SCNTransaction.commit()
    }
    
}

private extension UIFont {
    // Based on: https://stackoverflow.com/questions/4713236/how-do-i-set-bold-and-italic-on-uilabel-of-iphone-ipad
    func withTraits(traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
}


