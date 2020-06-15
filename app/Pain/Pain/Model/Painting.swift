import UIKit

class Painting {
    var photo: UIImage?
    var title: String
    var description: String
    var artist: String
    var medium: String
    var museum: Int
    
    init(photo: UIImage?, title: String, description: String, artist: String, medium: String, museum: Int) {
        self.photo = photo
        self.title = title
        self.description = description
        self.artist = artist
        self.medium = medium
        self.museum = museum
    }
}
