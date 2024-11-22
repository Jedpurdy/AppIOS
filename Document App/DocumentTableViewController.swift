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
    
    // Define an array of valid file extensions you want to include
    let validExtensions = ["jpg", "jpeg", "png", "pdf", "gif","mp4"]
    
    for item in items {
        // Ignorer les fichiers système "DS_Store" et récupérer tous les fichiers
        if !item.hasSuffix("DS_Store") {
            // Vérifier l'extension du fichier (en minuscules pour rendre la vérification insensible à la casse)
            let fileExtension = (item as NSString).pathExtension.lowercased()
            if validExtensions.contains(fileExtension) {
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

class DocumentTableViewController: UITableViewController, QLPreviewControllerDataSource, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISearchResultsUpdating {
    
    var previewItem: QLPreviewItem?
    var allDocuments: [[DocumentFile]] = [[], []]
    var filteredDocuments: [[DocumentFile]] = [[], []]
    var searchController: UISearchController!
    var isDarkMode: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
                    title: "Dark Mode",
                    style: .plain,
                    target: self,
                    action: #selector(toggleTheme)
                )
        // Initialize the search controller
        

        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Documents"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addDocument)),
            UIBarButtonItem(title: "Photos", style: .plain, target: self, action: #selector(pickImageFromPhotos))
        ]
        
        loadAllDocuments()
    }
    @objc func toggleTheme() {
        isDarkMode.toggle()
        
        // Apply the theme
        overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        
        // Update the button title to reflect the current mode
        navigationItem.leftBarButtonItem?.title = isDarkMode ? "Light Mode" : "Dark Mode"
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        
        if searchText.isEmpty {
            // If search text is empty, don't filter, use the original document lists
            filteredDocuments[0] = allDocuments[0]
            filteredDocuments[1] = allDocuments[1]
        } else {
            // Filter documents based on the search text
            filteredDocuments[0] = allDocuments[0].filter { document in
                document.title.lowercased().contains(searchText.lowercased())
            }
            
            filteredDocuments[1] = allDocuments[1].filter { document in
                document.title.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Reload the table view with filtered or unfiltered results
        tableView.reloadData()
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
            // Extract the file extension from the source URL
            let fileExtension = url.pathExtension // Get the original file's extension
            
            // Create the destination URL with the new name and the original extension
            destinationUrl = documentsDirectory.appendingPathComponent(newName).appendingPathExtension(fileExtension)
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

        // Update filtered documents based on search results
        updateSearchResults(for: searchController)
        
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
        return filteredDocuments[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DocumentCell", for: indexPath)
        
        let document = filteredDocuments[indexPath.section][indexPath.row]
        
        cell.textLabel?.text = document.title
        cell.detailTextLabel?.text = "Size: \(document.size.formattedSize())"
        
        let arrowIcon = UIImage(systemName: "chevron.right")
        cell.accessoryView = UIImageView(image: arrowIcon)
        
        cell.imageView?.image = UIImage(systemName: "doc.text")
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let document = filteredDocuments[indexPath.section][indexPath.row]
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
        
        // Add a toolbar with actions for renaming or deleting
        let renameAction = UIBarButtonItem(title: "Rename", style: .plain, target: self, action: #selector(renameFile))
        let deleteAction = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteFile))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        previewController.toolbarItems = [flexibleSpace, renameAction, flexibleSpace, deleteAction, flexibleSpace]
        previewController.navigationController?.isToolbarHidden = false // Ensure toolbar is visible
        
        navigationController?.pushViewController(previewController, animated: true)
    }

    @objc func renameFile() {
        guard let fileUrl = previewItem as? URL else { return }
        
        let alertController = UIAlertController(
            title: "Rename File",
            message: "Enter a new name for the file.",
            preferredStyle: .alert
        )
        alertController.addTextField { textField in
            textField.placeholder = fileUrl.lastPathComponent
        }
        let renameAction = UIAlertAction(title: "Rename", style: .default) { _ in
            guard let newName = alertController.textFields?.first?.text, !newName.isEmpty else { return }
            
            let fileManager = FileManager.default
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let newFileUrl = documentsDirectory.appendingPathComponent(newName).appendingPathExtension(fileUrl.pathExtension)
            
            do {
                try fileManager.moveItem(at: fileUrl, to: newFileUrl)
                self.loadAllDocuments() // Refresh the document list
            } catch {
                print("Error renaming file: \(error.localizedDescription)")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(renameAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    @objc func deleteFile() {
        guard let fileUrl = previewItem as? URL else { return }
        
        let alertController = UIAlertController(
            title: "Delete File",
            message: "Are you sure you want to delete this file?",
            preferredStyle: .alert
        )
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(at: fileUrl)
                self.loadAllDocuments() // Refresh the document list
                self.navigationController?.popViewController(animated: true) // Exit QLPreviewController
            } catch {
                print("Error deleting file: \(error.localizedDescription)")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1 // Nous ne présentons qu'un seul fichier à la fois
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return previewItem!
    }
}
