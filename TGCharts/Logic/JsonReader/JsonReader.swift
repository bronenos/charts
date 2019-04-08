//
//  JsonReader.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation

protocol IJsonReader {
    var dictionary: [String: Any]? { get }
    var array: [Any]? { get }
    var string: String? { get }
    var stringValue: String { get }
    var int: Int? { get }
    var intValue: Int { get }
    var bool: Bool? { get }
    var boolValue: Bool { get }
    subscript(key: String) -> IJsonReader { get }
    subscript(index: Int) -> IJsonReader { get }
}

struct JsonReader: IJsonReader {
    private let object: Any?
    
    init(data: Data) {
        self.object = try? JSONSerialization.jsonObject(with: data, options: [])
    }
    
    init(object: Any?) {
        self.object = object
    }
    
    var dictionary: [String: Any]? {
        return object as? [String: Any]
    }
    
    var array: [Any]? {
        return object as? [Any]
    }
    
    var string: String? {
        return object as? String
    }
    
    var stringValue: String {
        return string ?? String()
    }
    
    var int: Int? {
        return object as? Int
    }
    
    var intValue: Int {
        return int ?? 0
    }
    
    var bool: Bool? {
        return object as? Bool
    }
    
    var boolValue: Bool {
        return bool ?? false
    }
    
    subscript(key: String) -> IJsonReader {
        return JsonReader(object: dictionary?[key])
    }
    
    subscript(index: Int) -> IJsonReader {
        return JsonReader(object: array?[index])
    }
}
