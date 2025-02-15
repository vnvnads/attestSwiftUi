//
//  TFText.swift
//  attestSwiftUi
//
//  Created by Nguyễn Xuân Thịnh on 15/2/25.
//

import Foundation

class TFText {
    public static func httpBuildQuery(array: [String: String]) -> String {
        

//        let dict = [1 : "one", 2 : "two", 3 : "three"]
//        let sortedDict = dict.sorted { $0.0 < $1.0 } .map { $0 }
//        let sortedValues = dict.sorted { $0.0 < $1.0 } .map { $0.1 }
//        let reverseSortedValues = dict.sorted { $0.0 > $1.0 } .map { $0.1 }
        
        
        let sortedDict = array.sorted { $0.0 < $1.0 } .map { $0 }

        
        var param = ""
        var stt = 0
        for (key, value) in sortedDict {
            if (stt == 0) {
                param = param + "?" + key + "=" + value + "&"
            } else if (stt == array.count - 1) {
                param = param + key + "=" + value
            } else {
                param = param + key + "=" + value + "&"
            }
            stt = stt + 1
        }
        return param
    }
    
}
