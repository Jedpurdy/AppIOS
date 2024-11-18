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
