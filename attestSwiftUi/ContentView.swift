import SwiftUI
import DeviceCheck
import CryptoKit

struct ContentView: View {
    @State private var resultMessage = ""
    @State private var challenge: String = ""
    @State private var challengeReplayAttack: String = ""
    @State private var keyID: String = ""
    @State private var attestationBase64: String = ""

    
    var body: some View {
        
        List {
            Section {
                Text(resultMessage)
            }
            Section {
                Button {
                    resultMessage = "Đang lấy challenge.."
                    callChallenge()
                } label: {
                    Text("Generate Key & Attest")
                }
                
                Button {
                    callChallengeReplayAttack()
                    resultMessage = "Đang tạo challenge mới trong server..."
                } label: {
                    Text("Replay attack: Call vào API để tạo session challenge, sau đó Call Api vào verify  dựa vào thông số keyID và attestationBase64 của lần khởi tạo lần trước")
                }
                .disabled(disableReCall)
            }
            
            Text("challenge:" + challenge)
            Text("keyID:" + keyID)
            Text("attestationBase64:" + attestationBase64)

        }
        .onChange(of: challenge) {
            resultMessage = "Lấy challenge thành công. Đang xác thực..."
            performAppAttest()
        }
        .onChange(of: challengeReplayAttack) {
            resultMessage = "Tạo challenge mới thành công. Đang xác thực dựa vào thông số keyID và attestationBase64 của lần khởi tạo lần trước..."
            callVerify(keyID: keyID, attestationBase64: attestationBase64)
        }
    }
        
    
    var disableReCall: Bool {
        return challenge == "" || keyID == "" || attestationBase64 == ""
    }
    
    

    func performAppAttest() {
        let attestationService = DCAppAttestService.shared
        
        guard attestationService.isSupported else {
            resultMessage = "Thiết bị này không hỗ trợ App Attest."
            return
        }
        
        // Tạo key mới
        attestationService.generateKey { keyID, error in
            if let error = error {
                resultMessage = "Lỗi khi tạo key: \(error.localizedDescription)"
                return
            }
            
            guard let keyID = keyID else {
                resultMessage = "Tạo key thất bại: không nhận được keyID."
                return
            }
                        
            
            guard let challengeData = challenge.data(using: .utf8)  else {
                resultMessage = "Không thể lấy challenge từ server."
                return
            }

            
            // Tính băm SHA256 của challenge
            let clientDataHashDigest = SHA256.hash(data: challengeData)
            let clientDataHash = Data(clientDataHashDigest)
            

            // Gọi attestKey để nhận attestation object
            attestationService.attestKey(keyID, clientDataHash: clientDataHash) { attestationData, error in
                if let error = error {
                    resultMessage = "Lỗi attestation: \(error.localizedDescription)"
                    return
                }
                
                guard let attestationData = attestationData else {
                    resultMessage = "Attestation thất bại: không nhận được dữ liệu."
                    return
                }
                
                self.keyID = keyID
                self.attestationBase64 = attestationData.base64EncodedString()
                
                callVerify(keyID: keyID, attestationBase64: attestationData.base64EncodedString())
            }
        }
    }
    
    
    func callVerify(keyID: String, attestationBase64: String) {
        // Gửi keyID và attestationBase64 lên server qua HTTP POST để xác thực
        let query: [String: String] = [
            "keyID": keyID,
            "attestation": attestationBase64
        ]
        ServiceAlamofire.callMain(api: "https://vietnix.linkjj.com/attest/verify.php", parameters: query, method: .post) { (result: VerifyParam) in
            if (result.success == false) {
                resultMessage = result.message
            } else {
                resultMessage = "Xác thực thành công"
            }
        } failBlock: { status in
            resultMessage = status
        }
    }
    
    
    func callChallenge() {
        let query: [String: String] = [:]
        ServiceAlamofire.callMain(api: "https://vietnix.linkjj.com/attest/challenge.php", parameters: query, method: .get) { (response: [String: String]) in
            if let challenge = response["challenge"] {
                self.challenge = challenge
                print("Challenge in server: \(challenge)")
            }
        } failBlock: { status in
            print(status)
        }
    }
    
    func callChallengeReplayAttack() {
        let query: [String: String] = [:]
        ServiceAlamofire.callMain(api: "https://vietnix.linkjj.com/attest/challenge.php", parameters: query, method: .get) { (response: [String: String]) in
            if let challenge = response["challenge"] {
                self.challengeReplayAttack = challenge
            }
        } failBlock: { status in
            print(status)
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
