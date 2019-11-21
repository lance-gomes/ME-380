//
//  Stewart.swift
//  Stewart Platform Controller
//
//  Created by Lance Gomes on 2019-09-30.
//  Copyright © 2019 Christopher Louie. All rights reserved.
//

import Foundation
import Accelerate
import simd

class Stewart {
    
    let BASE_RADIUS = 8.739
    let PLATFORM_RADIUS = 6.523
    let BASE_PLATFORM_RADIUS = 15.2
    let HORN_RADIUS = 3.0
    
    let ROD_LENGTH = 17.3
    let RUBBER_BEARING_WIDTH = 0.4

    let BASE_ANGLES = [358.55, 58.55, 121.45, 178.56, 241.45, 298.56 ]
    let PLATFORM_ANGLES = [342.59, 77.41, 102.59, 197.41, 222.59, 317.41]
    let MOTOR_ORIENTATIONS  = [4.163, Double.pi , 0 , 5.26129503 , 2.11970237641, 1.0218903]

    var baseLocation: [SIMD3<Double>] = []
    var platformLocation : [SIMD3<Double>] = []

    init() {
        
        let baseMotorRads = BASE_ANGLES.map({$0 * Double.pi/180.0})
        let platformMotorRads = PLATFORM_ANGLES.map({$0 * Double.pi/180.0})
    
        for i in 0...5 {
            baseLocation.append(simd_double3(
                cos(baseMotorRads[i]) * BASE_RADIUS,
                sin(baseMotorRads[i]) * BASE_RADIUS,
                0
            ))

            platformLocation.append(simd_double3(
                cos(platformMotorRads[i]) * (PLATFORM_RADIUS + RUBBER_BEARING_WIDTH),
                sin(platformMotorRads[i]) * (PLATFORM_RADIUS + RUBBER_BEARING_WIDTH),
                0
            ))
        }
    }
    
    
    /// Return motor angles for a desired platform x and y angle
    /// - Parameters:
    ///   - xAngle: in radians
    ///   - yAngle: in radians
    func motorAngles(xAngle: Double, yAngle: Double) -> [Double] {
        
        let (legLengths, legVectors) = self.legLengths(xAngle: xAngle, yAngle: yAngle)
        
        var motorAngles : [Double] = []
        
        for i in 0...5 {
            let L = length_squared(legLengths[i]) + (HORN_RADIUS * HORN_RADIUS) - ( ROD_LENGTH * ROD_LENGTH)
            let M = HORN_RADIUS * 2 * (legVectors[i].z)
            let N = HORN_RADIUS * 2 * (
                cos(MOTOR_ORIENTATIONS[i]) * (legVectors[i].x - baseLocation[i].x)
                + sin(MOTOR_ORIENTATIONS[i]) * (legVectors[i].y - baseLocation[i].y)
            );
            
            motorAngles.append(asin(L/(sqrt(M*M + N*N))) - atan(N/M))
            
            if motorAngles[i] < 0 {
                motorAngles[i] = 2 * Double.pi + motorAngles[i]
            }
            
        }
        return motorAngles
    }

    func legLengths(xAngle: Double, yAngle: Double) -> (legLengths :[SIMD3<Double>], legVectors: [SIMD3<Double>]) {

        let rotationMatrix = self.rotationMatrix(xAngle: xAngle, yAngle: yAngle)
        let translationVector = simd_double3(0 , 0 , BASE_PLATFORM_RADIUS)

        var legLengths : [SIMD3<Double>] = []
        var legVectors : [SIMD3<Double>] = []

        for i in 0...5 {
            legVectors.append(translationVector + rotationMatrix * platformLocation[i])
            legLengths.append(legVectors[i] - baseLocation[i])
        }
        return (legLengths , legVectors)
    }

    func rotationMatrix(xAngle: Double, yAngle: Double) -> double3x3 {

        let yRows = [
            simd_double3(cos(yAngle), 0, sin(yAngle)),
            simd_double3(0,           1,           0),
            simd_double3(-sin(yAngle),0, cos(yAngle))
        ]

        let xRows = [
            simd_double3(1,           0,            0),
            simd_double3(0, cos(xAngle), -sin(xAngle)),
            simd_double3(0, sin(xAngle),  cos(xAngle))
        ]

        let yRotation = double3x3(rows: yRows)
        let xRotation = double3x3(rows: xRows)

        return yRotation * xRotation

    }
}
