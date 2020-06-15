import Foundation
import UIKit

class APICalls {
    func uploadImageToServer() {
        let url = URL(string: "https://pain.azurewebsites.net/api/predict")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(NSUUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Get image from the camera
        let image = UIImage(named: "Monalisa")
        let imageData = image!.jpegData(compressionQuality: 1.0)
        
        if (imageData == nil) {
            return
        }
        
        let body = createBody(boundary: boundary, data: imageData!)
        request.httpBody = body
        request.setValue(String(body.count), forHTTPHeaderField: "Content-Length")
        request.httpShouldHandleCookies = false
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error took place \(error)")
                return
            }
     
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                    print("Error with the response, unexpected status code: \(response)")
                return
            }
            
            do {
                let jsonResult = try JSONSerialization.jsonObject(with: data!, options: [])
                for painting in jsonResult as! [Dictionary<String, Any>] {
                    var testImage = self.downloadImage(imageName: painting["image_path"] as! String)
                    print(painting)
                }
            } catch let error {
                print("Failed to load: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }

    func getMoreFromMuseum(museumId: Int) {
        let url = URL(string: "https://pain.azurewebsites.net/api/list-museum/\(museumId)")
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
       
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error took place \(error)")
                return
            }
    
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Error with the response, unexpected status code: \(response)")
                return
            }
           
            do {
                let jsonResult = try JSONSerialization.jsonObject(with: data!, options: [])
                for painting in jsonResult as! [Dictionary<String, Any>] {
                    var testImage = self.downloadImage(imageName: painting["image_path"] as! String)
                    print(painting)
                }
            } catch let error {
                print("Failed to load: \(error.localizedDescription)")
            }
        }
       
        task.resume()
    }
    
    func downloadImage(imageName: String) -> UIImage {
        let url = URL(string: "https://pain.azurewebsites.net/user_content/\(imageName)")
        let data = try? Data(contentsOf: url!)
        return UIImage(data: data!)!
    }
    
    func createBody(boundary: String, data: Data) -> Data {
        var body = Data()
        let filename = "user-picture.jpg"
        let mimetype = "image/jpg"
        
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"payload\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimetype)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")
        
        return body
    }
}

extension Data {
    mutating func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}
