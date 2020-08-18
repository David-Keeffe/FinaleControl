//
//  ViewController.swift
//  protoui
//
//  Created by David Keeffe on 08/08/2020.
//  Copyright © 2020 Music3149. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func getIndex() {
        let dialog = NSOpenPanel();

        dialog.title                   = "Choose a file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.allowsMultipleSelection = false;
        dialog.canChooseDirectories = true;
        dialog.allowedFileTypes        = ["html", "htm"];

        dialog.begin() {
            (returnCode: NSApplication.ModalResponse) -> Void in
            /*
            let result = dialog.url // Pathname of the file

            if (result != nil) {
                let path: String = result!.path
                
                // path contains the file path e.g
                // /Users/ourcodeworld/Desktop/file.txt
            }*/
            
            
        }
    }

    @IBAction func getFiles(_ sender: Any) {
        getIndex()
    }
    @IBAction func savePrefs(_ sender: Any) {
        NSUserDefaultsController.shared.save(sender)
        if let myindex = appDelegate.defaults.string(forKey: "FCIndexPage") {
            appDelegate.httpserver.addRootIndex(path: myindex)
        } else {
            appDelegate.httpserver.resetRoot()
        }
        if let myassets = appDelegate.defaults.string(forKey: "FCAssetDir") {
            appDelegate.httpserver.addAssetPath(path: myassets)
        } else {
            appDelegate.httpserver.resetAssets()
        }
        appDelegate.togglePopover(sender)
    }

    @IBAction func cancelPrefs(_ sender: Any) {
        appDelegate.togglePopover(sender)
    }
}

extension ViewController {
    // MARK: Storyboard instantiation

    static func freshController() -> ViewController {
        // 1.
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        // 2.
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "ViewController")
        // 3.
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? ViewController else {
            fatalError("Why cant i find QuotesViewController? - Check Main.storyboard")
        }
        return viewcontroller
    }

    var appDelegate: AppDelegate {
        return NSApplication.shared.delegate as! AppDelegate
    }
}
