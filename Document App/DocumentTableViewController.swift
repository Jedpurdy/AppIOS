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
        if !item.hasSuffix("DS_Store") && item.hasSuffix(".jpg") {
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

class DocumentTableViewController: UITableViewController, QLPreviewControllerDataSource, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var previewItem: QLPreviewItem?
    var allDocuments: [[DocumentFile]] = [[], []]

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addDocument)),
            UIBarButtonItem(title: "Photos", style: .plain, target: self, action: #selector(pickImageFromPhotos))
        ]
        loadAllDocuments()
    }
    
    @objc func addDocument() {
        // Lancer le UIDocumentPicker
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item]) // Permet de sélectionner tous types de fichiers
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false // Pas de sélection multiple
        present(documentPicker, animated: true, completion: nil)
    }
    
    @objc func pickImageFromPhotos() {
        // Utilisation d'un UIImagePickerController pour choisir une image depuis la bibliothèque de photos
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = false
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func copyFileToDocumentsDirectory(fromUrl url: URL, newName: String?) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var destinationUrl = documentsDirectory.appendingPathComponent(url.lastPathComponent)
        
        // If the user has provided a new name, use it and append ".jpg" for images
        if let newName = newName, !newName.isEmpty {
            // Ensure the file ends with .jpg
            destinationUrl = documentsDirectory.appendingPathComponent(newName + ".jpg")
        }
        
        do {
            // Copy file from the selected URL to the Documents directory
            try FileManager.default.copyItem(at: url, to: destinationUrl)
            
            let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey, .nameKey, .fileSizeKey])
                    
            if let resources = resourceValues,
               let name = resources.name, // Nom du fichier
               let contentType = resources.contentType {
                // Créer un DocumentFile et l'ajouter à la liste des fichiers importés
                let documentFile = DocumentFile(
                    title: newName ?? name, // Use the new name if provided
                    size: Int(resources.fileSize ?? 0),
                    imageName: nil,
                    url: destinationUrl,
                    type: contentType.description
                )
                allDocuments[1].append(documentFile) // Ajouter le fichier importé à la liste des documents importés
            } else {
                print("Erreur: Les propriétés du fichier ne sont pas accessibles.")
            }
        } catch {
            print("Error copying file: \(error)")
        }
    }
    
    // Handle the image selected from the photos library
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Check if an image was picked
        if let selectedImage = info[.imageURL] as? URL {
            // Present an alert to allow the user to rename the image
            let alertController = UIAlertController(title: "Rename Image", message: "Enter a new name for the image.", preferredStyle: .alert)
            alertController.addTextField { textField in
                textField.placeholder = selectedImage.lastPathComponent
            }
            
            // Action when "Rename" is clicked
            let renameAction = UIAlertAction(title: "Rename", style: .default) { _ in
                if let newName = alertController.textFields?.first?.text {
                    self.copyFileToDocumentsDirectory(fromUrl: selectedImage, newName: newName)
                    self.loadAllDocuments()  // Reload the table to show the new image in the imported documents section
                }
            }
            
            // Action when "Cancel" is clicked
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(renameAction)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func listFileInDocumentsDirectory() -> [DocumentFile] {
        // Obtenir le chemin du répertoire Documents
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileManager = FileManager.default
        var documentList = [DocumentFile]()

        do {
            // Obtenir tous les fichiers du répertoire
            let fileUrls = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: [.contentTypeKey, .nameKey, .fileSizeKey])
            
            for fileUrl in fileUrls {
                // Récupérer les propriétés des fichiers
                let resourceValues = try fileUrl.resourceValues(forKeys: [.contentTypeKey, .nameKey, .fileSizeKey])
                
                documentList.append(DocumentFile(
                    title: resourceValues.name ?? "Fichier inconnu",
                    size: resourceValues.fileSize ?? 0,
                    imageName: nil, // Pas d'image par défaut
                    url: fileUrl,
                    type: resourceValues.contentType?.description ?? "Type inconnu"
                ))
            }
        } catch {
            print("Erreur lors de la lecture des fichiers dans Documents : \(error.localizedDescription)")
        }

        return documentList
    }
    
    func loadAllDocuments() {
        // Charger les fichiers du bundle
        let bundleDocuments = listFileInBundle()

        // Charger les fichiers du répertoire Documents
        let documentDirectoryFiles = listFileInDocumentsDirectory()

        // Remplir les sous-listes dans allDocuments : [Bundle, Importés]
        allDocuments[0] = bundleDocuments
        allDocuments[1] = documentDirectoryFiles

        // Recharger la TableView
        tableView.reloadData()
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileUrl = urls.first else { return }

        // Present an alert to allow the user to rename the file
        let alertController = UIAlertController(title: "Rename File", message: "Enter a new name for the file.", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = selectedFileUrl.lastPathComponent
        }
        
        // Action when "Rename" is clicked
        let renameAction = UIAlertAction(title: "Rename", style: .default) { _ in
            if let newName = alertController.textFields?.first?.text {
                self.copyFileToDocumentsDirectory(fromUrl: selectedFileUrl, newName: newName)
                self.loadAllDocuments()  // Reload the table to show the new document in the imported documents section
            }
        }
        
        // Action when "Cancel" is clicked
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(renameAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allDocuments[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DocumentCell", for: indexPath)
        
        let document = allDocuments[indexPath.section][indexPath.row]
        
        cell.textLabel?.text = document.title
        cell.detailTextLabel?.text = "Size: \(document.size.formattedSize())"
        
        let arrowIcon = UIImage(systemName: "chevron.right")
        cell.accessoryView = UIImageView(image: arrowIcon)
        
        cell.imageView?.image = UIImage(systemName: "doc.text")
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let document = allDocuments[indexPath.section][indexPath.row]
        instantiateQLPreviewController(withUrl: document.url)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Bundle"  // Titre de la section des fichiers du bundle
        case 1:
            return "Importés"  // Titre de la section des fichiers importés
        default:
            return nil
        }
    }

    // Présenter le QLPreviewController
    func instantiateQLPreviewController(withUrl url: URL) {
        let previewController = QLPreviewController()
        previewController.dataSource = self  // Assigner le datasource à self
        previewItem = url as QLPreviewItem
        navigationController?.pushViewController(previewController, animated: true)
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1 // Nous ne présentons qu'un seul fichier à la fois
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return previewItem!
    }
}
