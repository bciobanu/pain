import Foundation
import UIKit

class APICalls {
    func uploadImageToServer(image: UIImage, callback: @escaping ([Painting]?, String?) -> Void) {
        let url = URL(string: "https://pain.azurewebsites.net/api/predict")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(NSUUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let imageData = image.jpegData(compressionQuality: 1.0)
        
        if (imageData == nil) {
            DispatchQueue.main.async {
                callback(nil, "Invalid image")
            }
        }
        
        let body = createBody(boundary: boundary, data: imageData!)
        request.httpBody = body
        request.setValue(String(body.count), forHTTPHeaderField: "Content-Length")
        request.httpShouldHandleCookies = false
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error took place \(error)")
                DispatchQueue.main.async {
                    callback(nil, "Http error")
                }
                return
            }
     
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Error with the response, unexpected status code: \(String(describing: response))")
                DispatchQueue.main.async {
                    callback(nil, "Http response error")
                }
                return
            }

            do {
                var paintings = [Painting]()
                let jsonResult = try JSONSerialization.jsonObject(with: data!, options: [])
                for json in jsonResult as! [Dictionary<String, Any>] {
                    paintings.append(self.getPaintingFromJson(json: json))
                }
                DispatchQueue.main.async {
                    callback(paintings, nil)
                }
            } catch let error {
                print("Failed to load: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    callback(nil, "JSON serialization error")
                }
            }
        }
        
        task.resume()
    }

    func getMoreFromMuseum(museumId: Int, callback: @escaping ([Painting]?, String?) -> Void) {
        let url = URL(string: "https://pain.azurewebsites.net/api/list-museum/\(museumId)")
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error took place \(error)")
                DispatchQueue.main.async {
                    callback(nil, "Http error")
                }
                return
            }
    
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Error with the response, unexpected status code: \(String(describing: response))")
                DispatchQueue.main.async {
                    callback(nil, "Http response error")
                }
                return
            }

            do {
                var paintings = [Painting]()
                let jsonResult = try JSONSerialization.jsonObject(with: data!, options: [])
                for json in jsonResult as! [Dictionary<String, Any>] {
                    paintings.append(self.getPaintingFromJson(json: json))
                }
                DispatchQueue.main.async {
                    callback(paintings, nil)
                }
            } catch let error {
                print("Failed to load: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    callback(nil, "JSON serialization error")
                }
            }
        }
       
        task.resume()
    }
    
    func getPaintingFromJson(json: Dictionary<String, Any>) -> Painting {
        let photo: UIImage? = self.downloadImage(imageName: json["image_path"] as! String)
        let title: String = json["name"] as! String
        let description: String = json["description"] as! String
        let artist: String = json["artist"] as! String
        let medium: String = json["medium"] as! String
        let museum: Int = json["museum"] as! Int
        
        return Painting(photo: photo, title: title, description: description, artist: artist, medium: medium, museum: museum)
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
