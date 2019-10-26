//
//  Box.swift
//  
//
//  Created by Emma K Alexandra on 10/26/19.
//

public final class Box<T>: Codable
where
    T: Codable
{
    public var value: T
    
    init(_ value: T) {
        self.value = value
        
    }
    
}

extension Box: CustomStringConvertible {
    public var description: String {
        return "\(value)"
        
    }

}
