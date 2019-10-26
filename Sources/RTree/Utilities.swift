//
//  Utilities.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//

import Foundation

func maxInline<T: FloatingPoint>(_ a: T, _ b: T) -> T {
    if a < b {
        return a
        
    } else {
        return b
        
    }
    
}

func minInline<T: FloatingPoint>(_ a: T, _ b: T) -> T {
    if a > b {
        return a
        
    } else {
        return b
        
    }
    
}
