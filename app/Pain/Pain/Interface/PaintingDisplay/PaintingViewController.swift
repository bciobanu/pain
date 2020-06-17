import UIKit
import AVFoundation

class PaintingViewController: UIViewController {
    //MARK: Variables
    var painting: Painting? = nil
    var fromDetection = false

    private let speaker = AVSpeechSynthesizer()
    private let api = APICalls()

    @IBOutlet weak var visitMuseumButton: UIBarButtonItem!
    
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var paintingDescription: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !fromDetection {
            visitMuseumButton.isEnabled = false
            visitMuseumButton.title = ""
        }
        if let painting = painting {
            photo.image = painting.photo
            
            var description = painting.title + "\n"
            description += painting.artist + ", "
            description += String(painting.year) + "\n"
            description += painting.medium + "\n"
            description += "\n    " + painting.description
            
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(named: "customFontColor")!,
                .font: UIFont.systemFont(ofSize: 14)
            ]
            
            let titleLocation = 0
            let artistLocation = titleLocation + 1 + painting.title.count
            let attributedString = NSMutableAttributedString(string: description, attributes: attributes)
            attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: NSRange(location: titleLocation, length: painting.title.count))
            attributedString.addAttribute(.font, value: UIFont.italicSystemFont(ofSize: 14), range: NSRange(location: artistLocation, length: painting.artist.count))
            paintingDescription.attributedText = attributedString
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if speaker.isSpeaking {
            speaker.stopSpeaking(at: .immediate)
        }
    }
    @IBAction func openCamera(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "DetailsToCamera", sender: self)
    }
    
    @IBAction func textToSpeech(_ sender: UIBarButtonItem) {
        let dialogue = AVSpeechUtterance(string: paintingDescription.text)
        dialogue.rate = AVSpeechUtteranceDefaultSpeechRate
        dialogue.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_female_en-GB_compact")
        
        if speaker.isSpeaking {
            speaker.stopSpeaking(at: .immediate)
        } else {
            speaker.speak(dialogue)
        }
    }
    
    @IBAction func visitMuseum(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "ShowMoreFromMuseum", sender: self)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch (segue.identifier ?? "") {
        case "ShowMoreFromMuseum":
            guard let paintingTableController = segue.destination as? PaintingTableViewController else {
                fatalError("Unexpected segue destination: \(segue.destination)")
            }
            let museumId = self.painting!.museum
            api.getMoreFromMuseum(museumId: museumId) { (paintings, err) in
                if let paintings = paintings {
                    paintingTableController.paintings = paintings
                    paintingTableController.tableView.reloadData()
                }
            }
        case "BackToCamera":
            break
        default:
            print(segue.identifier ?? "<nil>")
            fatalError("Unexpected transition")
        }
    }

}
