import UIKit

class PaintingViewController: UIViewController {
    //MARK: Variables
    var painting: Painting? = nil
    
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var paintingDescription: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let painting = painting {
            photo.image = painting.photo
//            paintingDescription.text = painting.description
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(paintingDescription.text)
        print(self.view.subviews[0].subviews[0])
        print(self.view.subviews[0])
    }
    
    @IBAction func openCamera(_ sender: UIButton) {
        print("Camera stuff I guess")
        self.performSegue(withIdentifier: "DetailsToCamera", sender: self)
    }
    

    @IBAction func testServerUpload(_ sender: UIButton) {
        print("Test pressed")
        let network = APICalls()
        network.uploadImageToServer(image: UIImage(named: "Monalisa")!)
        network.getMoreFromMuseum(museumId: 1)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
