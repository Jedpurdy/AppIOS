import UIKit
import QuickLook
import UniformTypeIdentifiers

// Fonction pour lister les fichiers dans le bundle de l'application
func listFileInBundle() -> [DocumentFile] {
    // Initialisation du gestionnaire de fichiers
    let fm = FileManager.default
    // Chemin vers le bundle de l'application
    let path = Bundle.main.resourcePath!
    // Liste des fichiers et dossiers dans le bundle
    let items = try! fm.contentsOfDirectory(atPath: path)
    // Tableau pour stocker les fichiers sous forme de DocumentFile
    var documentListBundle = [DocumentFile]()
    
    for item in items {
        // Ignorer les fichiers système "DS_Store" et récupérer tous les fichiers
        if !item.hasSuffix("DS_Store") {
            let currentUrl = URL(fileURLWithPath: path + "/" + item)
            // Récupérer les informations sur le fichier
            let resourcesValues = try! currentUrl.resourceValues(forKeys: [.contentTypeKey, .nameKey, .fileSizeKey])
            
            // Ajouter le fichier à la liste en tant que DocumentFile
            documentListBundle.append(DocumentFile(
                title: resourcesValues.name!,                      // Nom du fichier
                size: resourcesValues.fileSize ?? 0,              // Taille du fichier
                imageName: item,                                   // Nom de l'image (facultatif)
                url: currentUrl,                                   // URL du fichier
                type: resourcesValues.contentType!.description     // Type MIME du fichier
            ))
        }
    }
    return documentListBundle
}

// Structure pour représenter un fichier
struct DocumentFile {
    var title: String       // Titre du fichier
    var size: Int           // Taille du fichier en octets
    var imageName: String?  // Nom de l'image (facultatif)
    var url: URL            // URL du fichier
    var type: String        // Type MIME du fichier

    // Liste des documents (source initiale : bundle)
    static let documents: [DocumentFile] = listFileInBundle()
}

// Extension pour formater la taille des fichiers en unités lisibles
extension Int {
    func formattedSize() -> String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.countStyle = .file
        return byteCountFormatter.string(fromByteCount: Int64(self))
    }
}

// Classe pour gérer la liste des documents
class DocumentTableViewController: UITableViewController, QLPreviewControllerDataSource {

    // Propriété pour le fichier actuellement prévisualisé
    var previewItem: QLPreviewItem?
    // Tableau des fichiers importés par l'utilisateur
    var userImportedFiles: [DocumentFile] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Ajouter un bouton pour importer des fichiers
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addDocument)),
            UIBarButtonItem(title: "Photos", style: .plain, target: self, action: #selector(pickImageFromPhotos))
        ]
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // Une seule section
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Nombre total de documents : bundle + fichiers importés
        return DocumentFile.documents.count + userImportedFiles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Obtenir une cellule réutilisable
        let cell = tableView.dequeueReusableCell(withIdentifier: "DocumentCell", for: indexPath)
        
        // Identifier le fichier correspondant
        let document: DocumentFile
        if indexPath.row < DocumentFile.documents.count {
            // Fichiers dans le bundle
            document = DocumentFile.documents[indexPath.row]
        } else {
            // Fichiers importés
            document = userImportedFiles[indexPath.row - DocumentFile.documents.count]
        }
        
        // Configuration de la cellule
        cell.textLabel?.text = document.title                         // Titre
        cell.detailTextLabel?.text = document.size.formattedSize()    // Taille formatée
        cell.imageView?.image = UIImage(systemName: "doc.fill")       // Icône
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Identifier le fichier correspondant
        let document: DocumentFile
        if indexPath.row < DocumentFile.documents.count {
            // Fichiers dans le bundle
            document = DocumentFile.documents[indexPath.row]
        } else {
            // Fichiers importés
            document = userImportedFiles[indexPath.row - DocumentFile.documents.count]
        }
        
        // Ouvrir le fichier dans QLPreviewController
        instantiateQLPreviewController(withUrl: document.url)
    }
    
    // MARK: - Méthodes pour QLPreviewController
    func instantiateQLPreviewController(withUrl url: URL) {
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewItem = url as QLPreviewItem
        navigationController?.pushViewController(previewController, animated: true)
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1 // Toujours un seul fichier à prévisualiser
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return previewItem!
    }
    
    // MARK: - Ajouter un document avec UIDocumentPicker
    @objc func addDocument() {
        // Créer un UIDocumentPicker pour choisir un fichier
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        documentPicker.delegate = self
        present(documentPicker, animated: true)
    }
    
    // Fonction pour copier un fichier dans le répertoire Documents de l'application
    func copyFileToDocumentsDirectory(fromUrl url: URL) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentsDirectory.appendingPathComponent(url.lastPathComponent)
        
        do {
            // Copier le fichier à l'URL de destination
            try FileManager.default.copyItem(at: url, to: destinationUrl)
            print("Fichier copié : \(destinationUrl)")
        } catch {
            print("Erreur lors de la copie : \(error)")
        }
    }
    
    // Rafraîchir la liste des documents
    func refreshDocumentList() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURLs = try! FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
        
        // Ajouter chaque fichier importé à la liste
        userImportedFiles = fileURLs.map { url in
            let fileName = url.lastPathComponent
            let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let fileType = (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType?.description) ?? "Inconnu"
            
            return DocumentFile(title: fileName, size: fileSize, url: url, type: fileType)
        }
        
        // Recharger la table
        tableView.reloadData()
    }

    // MARK: - Choisir une image depuis la galerie photos
    @objc func pickImageFromPhotos() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
}

// Extension pour UIDocumentPickerDelegate
extension DocumentTableViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileUrl = urls.first else { return }
        copyFileToDocumentsDirectory(fromUrl: selectedFileUrl) // Copier le fichier
        refreshDocumentList() // Rafraîchir la liste des fichiers
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Le sélectionneur de document a été annulé.")
    }
}

// Extension pour UIImagePickerControllerDelegate
extension DocumentTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let imageUrl = info[.imageURL] as? URL {
            copyFileToDocumentsDirectory(fromUrl: imageUrl)
            userImportedFiles.append(DocumentFile(
                title: imageUrl.lastPathComponent,
                size: (try? imageUrl.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) ?? 0,
                url: imageUrl,
                type: imageUrl.pathExtension
            ))
        }
        dismiss(animated: true)
        tableView.reloadData()
    }
}
