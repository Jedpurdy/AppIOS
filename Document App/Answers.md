1) Environnement
    Exercice 1)

    Les targets:

        Les targets sont des configurations de construction d’app. Permettent de faire différentes versions 

    Les fichiers de base: 

        AppDelegate.swift : Gère le cycle de vie de l’app.

        SceneDelegate.swift : Gère les scènes .

        ViewController.swift : Contrôleur de la vue principale.

        Main.storyboard : Interface visuelle de l’app.

        Dossier Assets.xcassets

        Stocke les images, icônes, couleurs, adaptés à différents écrans.

    Storyboard :

        Outil visuel pour créer l’UI et les transitions entre vues sans coder chaque écran.

    Simulateur :

        Permet de tester l’app sur des versions simulées d’iPhone/iPad sans appareil physique.

    Exercice 2)

    Cmd + R:

        Lance l’app sur simulateur ou appareil.

    Cmd + Shift + o:

        Recherche de fichiers/classes/méthodes.

    Indenter le code:

        Ctrl + I : Indente le code sélectionné.

    Commenter la sélection:

        Cmd + / : Commente ou décommente la sélection.

    Exercice 3)
    J'ai lancé sur IPhone 15 pro et jai changé sur Ipad pro


3) Delegation
    Exercice 1)

        Une propriété statique appartient à la classe, pas à un objet. Elle est partagée par toutes les instances de la classe. Ça permet d'éviter de répéter des infos dans chaque objet et d'y accéder directement via la classe sans créer d'instance. Par exemple, pour un taux d’intérêt global dans une classe CompteBancaire.
    Exercice 2)
        La méthode dequeueReusableCell est importante pour les performances car elle permet de réutiliser les cellules qui ne sont plus visibles à l'écran, plutôt que de créer de nouvelles cellules à chaque fois.
    Exercice 3)
        extension Int {
            func formattedSize() -> String {
                let byteCountFormatter = ByteCountFormatter()
                byteCountFormatter.countStyle = .file
                return byteCountFormatter.string(fromByteCount: Int64(self))
            }
        }

4)Navigation
    Exercice1)
        1)
            Nous avons ajouté un NavigationController à notre TableViewController pour permettre la navigation entre les vues, ajouter un titre à la page et une barre de navigation
        2)
            Le NavigationController gère la pile de vues, permet de naviguer entre elles, et ajoute une NavigationBar avec un titre et des boutons de navigation.
            Non, la NavigationBar est la barre en haut de l'écran, tandis que le NavigationController gère la navigation entre les vues.
 5) bundle
    Exercice 1)
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

6) Ecran détail
    Exercice 1)
        Un segue est une transition entre deux écrans dans une app, permettant de passer des données et de naviguer.   
    Exercice 2)
        Une constraint est une règle de positionnement d'éléments d'interface, utilisée par AutoLayout pour adapter la mise en page à différents écrans.

7) Binding
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // 1. Récupérer l'index de la ligne sélectionnée
        if let indexPath = tableView.indexPathForSelectedRow {
            // 2. Récupérer le document correspondant à l'index
            let selectedDocument = DocumentFile.documents[indexPath.row]
            
            // 3. Cibler l'instance de DocumentViewController via segue.destination
            // 4. Caster le segue.destination en DocumentViewController
            if let documentViewController = segue.destination as? DocumentViewController {
                // 5. Remplir la variable imageName de l'instance de DocumentViewController avec le nom de l'image du document
                documentViewController.imageName = selectedDocument.imageName
            }
        }
    }
    

9) QLPreview
    
Changer pour un disclosureIndicator rend l'interface plus claire et intuitive, car c’est le standard pour indiquer qu'on peut naviguer vers une nouvelle vue. C’est simple à mettre en place et ça fait gagner du temps.


10)Importation
    

    - Un #selector en Swift permet de lier une méthode à un événement, comme un clic de bouton.
    - .add fait référence à l’ajout de cette action à un élément, comme un bouton.
    - Xcode demande @objc car les sélecteurs viennent d'Objective-C, et @objc rend la méthode compatible avec ce système.
    - Oui, on peut ajouter plusieurs boutons dans la barre de navigation en les assignant à leftBarButtonItem et rightBarButtonItem.
    
    
    La fonction defer en Swift permet de spécifier un bloc de code qui sera exécuté juste avant que le contrôle ne sorte de la portée actuelle, peu importe comment on en sort. on l'utilise aussi en html pour éxécuter un script a la fin du chargment de notre page pour ne pas qu'on manipule des tags qui n'éxiste pas.
    
11)Sections 

