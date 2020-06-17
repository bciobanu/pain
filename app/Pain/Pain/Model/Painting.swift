import UIKit

class Painting {
    var photo: UIImage?
    var title: String
    var description: String
    var artist: String
    var medium: String
    var museum: Int
    var year: String
    
    init(photo: UIImage?, title: String, description: String, artist: String, medium: String, museum: Int, year: String) {
        self.photo = photo
        self.title = title
        self.description = description
        self.artist = artist
        self.medium = medium
        self.museum = museum
        self.year = year
    }
}
