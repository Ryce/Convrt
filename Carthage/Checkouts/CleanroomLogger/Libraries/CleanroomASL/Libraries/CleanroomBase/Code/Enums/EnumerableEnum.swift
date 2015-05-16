//
//  EnumerableEnum.swift
//  CleanroomBase
//
//  Created by Evan Maloney on 4/22/15.
//  Copyright (c) 2015 Gilt Groupe. All rights reserved.
//

import Foundation

/**
A protocol intended to be adopted by `enum` implementations that wish to make
their individual values enumerable.
*/
public protocol EnumerableEnum
{
    typealias EnumType

    /**
    Returns an array containing the all possible values of the receiving `enum`
    type.
    
    :returns:       The possible values of the `enum`.
    */
    static func allValues() -> [EnumType]
}
