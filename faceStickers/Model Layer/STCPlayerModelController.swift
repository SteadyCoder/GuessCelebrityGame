//
//  STCPlayerModelController.swift
//  faceStickers
//
//  Created by Ivan Tkachenko on 1/9/19.
//  Copyright © 2019 steadyIvan. All rights reserved.
//

import Foundation

class STCPlayerModelController {
    let playerModel = STCPlayerModel()
    
    func addPlayer(withCelebrityName celebrityName: String) -> STCPlayer  {
        let player = STCPlayer(withCelebrityName: celebrityName)
        player.playerId = UInt(self.playerModel.players.count) + 1
        
        self.playerModel.players.append(player)
        return player
    }
    
    func removePlayer(withPlayerId playerId: UInt) -> Bool {
        var result = false
        var playerIndex : Int? = nil
        for i in 0..<self.playerModel.players.count {
            let player = self.playerModel.players[i]
            if (playerId == player.playerId) {
                playerIndex = Int(playerId)
                break
            }
        }
        
        if let index = playerIndex {
            self.playerModel.players.remove(at: index)
            result = true
        }
        return result
    }
}
