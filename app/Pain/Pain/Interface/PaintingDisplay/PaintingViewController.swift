import UIKit
import AVFoundation

class PaintingViewController: UIViewController {
    //MARK: Variables
    var painting: Painting? = nil
    private let speaker = AVSpeechSynthesizer()
    
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var paintingDescription: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let painting = painting {
            photo.image = painting.photo
            paintingDescription.text = painting.description
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(paintingDescription.text)
        print(self.view.subviews[0].subviews[0])
        print(self.view.subviews[0])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if speaker.isSpeaking {
            speaker.stopSpeaking(at: .immediate)
        }
    }
    
    @IBAction func openCamera(_ sender: UIButton) {
        self.performSegue(withIdentifier: "DetailsToCamera", sender: self)
    }
    
    
    @IBAction func textToSpeech(_ sender: UIButton) {
        let dialogue = AVSpeechUtterance(string: painting!.description)
        dialogue.rate = AVSpeechUtteranceDefaultSpeechRate
        dialogue.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_female_en-GB_compact")
        
        if speaker.isSpeaking {
            speaker.stopSpeaking(at: .immediate)
        } else {
            speaker.speak(dialogue)
        }
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
