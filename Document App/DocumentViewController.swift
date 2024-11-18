import UIKit

class DocumentViewController: UIViewController {

    // Outlet pour l'ImageView du Storyboard
    @IBOutlet weak var imageView: UIImageView!

    // Variable pour stocker le nom de l'image
    var imageName: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Vérifier que imageName n'est pas nil
        if let imageName = imageName {
            // 2. Afficher l'image dans l'ImageView
            imageView.image = UIImage(named: imageName)
        }
    }
}
