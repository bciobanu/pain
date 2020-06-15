import Foundation
import UIKit

class APICalls {
    func uploadImageToServer(image: UIImage) -> [Painting] {
        let url = URL(string: "https://pain.azurewebsites.net/api/predict")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(NSUUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let imageData = image.jpegData(compressionQuality: 1.0)
        
        if (imageData == nil) {
            return [Painting]()
        }
        
        let body = createBody(boundary: boundary, data: imageData!)
        request.httpBody = body
        request.setValue(String(body.count), forHTTPHeaderField: "Content-Length")
        request.httpShouldHandleCookies = false
        
        var paintings = [Painting]()
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error took place \(error)")
                return
            }
     
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                    print("Error with the response, unexpected status code: \(String(describing: response))")
                return
            }
            
            do {
                let jsonResult = try JSONSerialization.jsonObject(with: data!, options: [])
                for json in jsonResult as! [Dictionary<String, Any>] {
                    paintings.append(self.getPaintingFromJson(json: json))
                    print(json)
                }
            } catch let error {
                print("Failed to load: \(error.localizedDescription)")
            }
        }
        
        task.resume()
        return paintings
    }

    func getMoreFromMuseum(museumId: Int) -> [Painting] {
        let url = URL(string: "https://pain.azurewebsites.net/api/list-museum/\(museumId)")
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"

        var paintings = [Painting]()
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error took place \(error)")
                return
            }
    
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Error with the response, unexpected status code: \(String(describing: response))")
                return
            }
           
            do {
                let jsonResult = try JSONSerialization.jsonObject(with: data!, options: [])
                for json in jsonResult as! [Dictionary<String, Any>] {
                    paintings.append(self.getPaintingFromJson(json: json))
                    print(json)
                }
            } catch let error {
                print("Failed to load: \(error.localizedDescription)")
            }
        }
       
        task.resume()
        return paintings
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
        var image = UIImage(named: "NoPhoto")
        if data != nil {
            image = UIImage(data: data!)
        }
        return image!
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
