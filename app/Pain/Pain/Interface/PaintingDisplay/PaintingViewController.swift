import UIKit
import AVFoundation // for text to speech

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
    
    let speaker = AVSpeechSynthesizer()
    @IBAction func testTextToSpeech(_ sender: UIButton) {
        let utterance = AVSpeechUtterance(string: "Unfortunately Apple does not list all of the supported language codes in the class documentation but mentions they need to be BCP-47 codes")
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_female_en-GB_compact")
        utterance.rate = 0.5

        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
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
