import UIKit
import os.log

class PaintingTableViewController: UITableViewController {
    
    // MARK: Properties
    var paintings: [Painting] = []
    var fromDetection = false
    
    override var prefersStatusBarHidden: Bool {
        false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Results"
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return paintings.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PaintingTableViewCell", for: indexPath) as? PictureTableViewCell else {
            fatalError("Wrong type of cell in painting table")
        }

        let painting = paintings[indexPath.row]
        cell.photo.image = painting.photo
        cell.title.text = painting.title
        cell.artist.text = painting.artist

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch (segue.identifier ?? "") {
        case "ShowPainting":
            os_log("Showing painting", log: OSLog.default, type: .debug)
            guard let paintingViewController = segue.destination as? PaintingViewController else {
                fatalError("Unexpected segue destination: \(segue.destination)")
            }
            guard let selectedPaintingCell = sender as? PictureTableViewCell else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let indexPath = tableView.indexPath(for: selectedPaintingCell) else {
                fatalError("Unexpected cell: \(selectedPaintingCell)")
            }
            let selectedPainting = paintings[indexPath.row]
            paintingViewController.fromDetection = self.fromDetection
            paintingViewController.painting = selectedPainting
        default:
            print(segue.identifier ?? "<nil>")
            fatalError("Unexpected transition")
        }
    }

    private func loadSamplePaintings() {
        let painting1 = Painting(photo: UIImage(named: "Monalisa"), title: "Monalisa", description: "Etc etc etc", artist: "Leonardo da Vinci", medium: "Oil", museum: 1, year: "1898")
        let painting2 = Painting(photo: nil, title: "Monalisa", description: "Etc etc etc", artist: "Leonardo da Vinci", medium: "Oil", museum: 1, year: "1989")
        let painting3 = Painting(photo: UIImage(named: "Monalisa"), title: "Monalisa", description: "Etc etc etc Etc etc etc Etc etc etc Etc etc etc Etc etc etc Etc etc etc Etc etc etc Etc etc etc Etc etc etc Etc etc etc Etc etc etc Etc etc etc Etc etc etc Etc etc etc ", artist: "Leonardo da Vinci", medium: "Oil", museum: 1, year: "1569")
        paintings = [painting1, painting2, painting3]
    }
}
