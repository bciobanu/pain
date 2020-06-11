import UIKit

class Painting {
    var photo: UIImage?
    var title: String
    var description: String
    
    init(photo: UIImage?, title: String, description: String) {
        self.photo = photo
        self.title = title
        self.description = description
    }
}
