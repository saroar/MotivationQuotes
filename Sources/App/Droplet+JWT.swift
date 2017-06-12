//
//  Droplet+JWT.swift
//  MotivationQuotes
//
//  Created by Alif on 12/06/2017.
//
//

import Vapor
import HTTP
import JWT

extension Droplet {
    func  createJwtToken(_ userId: String)  throws -> String {
        
        guard  let sig = self.signer else {
            throw Abort.unauthorized
        }
        
        let timeToLive = 5 * 60.0 // 5 minutes
        let claims:[Claim] = [
            ExpirationTimeClaim(date: Date().addingTimeInterval(timeToLive)),
            SubjectClaim(string: userId)
        ]
        
        let payload = JSON(claims)
        let jwt = try JWT(payload: payload, signer: sig)
        
        return try jwt.createToken()
    }
}
