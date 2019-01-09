//
//  STCPlayer.swift
//  faceStickers
//
//  Created by Ivan Tkachenko on 1/8/19.
//  Copyright © 2019 steadyIvan. All rights reserved.
//

import Foundation

class STCPlayer {
    var playerId: UInt!
    var celebrityName: String
    
    init(withCelebrityName celebrityName: String) {
        self.celebrityName = celebrityName
    }
}
