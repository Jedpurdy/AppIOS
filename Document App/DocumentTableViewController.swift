import UIKit
import QuickLook

func listFileInBundle() -> [DocumentFile] {
    // Initialise le FileManager pour naviguer dans le système de fichiers.
    let fm = FileManager.default
    
    // Récupère le chemin du bundle de l'application.
    let path = Bundle.main.resourcePath!
    
    // Récupère tous les fichiers et dossiers du répertoire spécifié dans le bundle.
    let items = try! fm.contentsOfDirectory(atPath: path)
    
    // Initialise un tableau pour stocker les documents de type DocumentFile.
    var documentListBundle = [DocumentFile]()
    
    // Parcours chaque élément du répertoire.
    for item in items {
        // Ignore les fichiers "DS_Store" (qui sont des fichiers systèmes macOS) et sélectionne uniquement les fichiers ".jpg".
        if !item.hasSuffix("DS_Store") && item.hasSuffix(".jpg") {
            // Crée une URL pour accéder au fichier dans le bundle.
            let currentUrl = URL(fileURLWithPath: path + "/" + item)
            
            // Récupère les métadonnées du fichier, comme le type, le nom et la taille du fichier.
            let resourcesValues = try! currentUrl.resourceValues(forKeys: [.contentTypeKey, .nameKey, .fileSizeKey])
            
            // Ajoute un nouvel objet DocumentFile à la liste avec les informations récupérées.
            documentListBundle.append(DocumentFile(
                title: resourcesValues.name!,                      // Nom du fichier
                size: resourcesValues.fileSize ?? 0,               // Taille du fichier (par défaut à 0 si non disponible)
                imageName: item,                                   // Nom de l'image (le nom du fichier)
                url: currentUrl,                                   // URL du fichier
                type: resourcesValues.contentType!.description    // Type MIME du fichier
            ))
        }
    }
    
    // Retourne la liste des documents.
    return documentListBundle
}
// Your document structure
struct DocumentFile {
    var title: String
    var size: Int
    var imageName: String? = nil
    var url: URL
    var type: String

    // Set la soucre de test documents au fichiers dans l'explorer
    static let documents: [DocumentFile] = listFileInBundle()
}

extension Int {
    func formattedSize() -> String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.countStyle = .file
        return byteCountFormatter.string(fromByteCount: Int64(self))
    }
}

class DocumentTableViewController: UITableViewController, QLPreviewControllerDataSource {

    
    var previewItem: QLPreviewItem?
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DocumentFile.documents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DocumentCell", for: indexPath)
        let document = DocumentFile.documents[indexPath.row]
        
        // Use the .subtitle style to show both title and detail text
        cell.textLabel?.text = document.title
        cell.detailTextLabel?.text = document.size.formattedSize()
        

        


        cell.imageView?.image = UIImage(systemName: "doc.fill") //
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
          let document = DocumentFile.documents[indexPath.row]
          instantiateQLPreviewController(withUrl: document.url)
      }
    
    func instantiateQLPreviewController(withUrl url: URL) {
            let previewController = QLPreviewController()
            previewController.dataSource = self
            previewItem = url as QLPreviewItem
            navigationController?.pushViewController(previewController, animated: true)
        }

        // MARK: - QLPreviewControllerDataSource

        // Fournir le nombre d'éléments à prévisualiser (1 dans ce cas)
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        // Fournir l'élément à prévisualiser
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return previewItem!
        }

    
}
