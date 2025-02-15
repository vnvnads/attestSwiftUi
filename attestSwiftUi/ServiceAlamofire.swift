//
//  ServiceAlamofire.swift
//  TruyenHD
//
//  Created by Nguyễn Xuân Thịnh on 29/11/2023.
//

import Foundation
import Alamofire
import UIKit

class ServiceAlamofire {
        

    
    
    // trả về data: Codable rồi muốn làm gì thì làm
    static func callMain<T: Codable>(api: String, parameters: Parameters, method: HTTPMethod, successBlock: @escaping (T) -> Void, failBlock: @escaping (String) -> Void) {
        
        var request: DataRequest
        if method == .get {
            var parametersConvert: [String: String] = [:]
            for (key, value) in parameters {
                parametersConvert[key] = "\(value)"
            }
            request = AF.request(api + TFText.httpBuildQuery(array: parametersConvert), method: method,  encoding: JSONEncoding.default)
        } else {
            request = AF.request(api, method: method,  parameters: parameters, encoding: JSONEncoding.default)
        }

        //let request = AF.request(api, method: method,  parameters: parameters, encoding: JSONEncoding.default)
        request.cURLDescription { description in
//            print(description)
        }
        
        
        request
            .validate(statusCode: 200..<300)
            .response { response in
                switch response.result {
                    case .success:
                        do {
                            if let data = response.data {
                                let result = try JSONDecoder().decode(T.self, from: data)
                                successBlock(result)
                            } else {
                                failBlock("Lỗi decode")
                            }
                        } catch {
                            print(error)
                            let string = error.localizedDescription
                            do {
                                if let data = response.data {
                                    let result = try JSONDecoder().decode(ResultParam.self, from: data)
                                    failBlock(result.status)
                                } else {
                                    failBlock(string)
                                }
                            } catch {
                                failBlock(string)
                            }
                        }
                        
                    case .failure(let error):
                        var errorString = error.errorDescription ?? ""
                        if (errorString == "URLSessionTask failed with error: Could not connect to the server.") {
                            errorString = "Không thể kết nối tới máy chủ, thử bật VPN và thao tác lại"
                        }
                        failBlock(errorString)
                }
            }
            .responseData { response in
                print(response.debugDescription)
            }
    }
    
    
 
   

    
    
}

struct ResultParam: Codable {
    let status: String
    let error: Int
}


struct VerifyParam: Codable {
    let success: Bool
    let message: String
    let error_code: Int?

}
