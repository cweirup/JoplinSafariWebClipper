//
//  SafariExtensionViewController.swift
//  Joplin Clipper Extension
//
//  Created by Christopher Weirup on 2020-02-06.
//  Copyright © 2020 Christopher Weirup. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    var allFolders = [Folder]()
    var isServerRunning = false {
        didSet {
            if (isServerRunning == true) {
                pageTitleLabel.stringValue = "Server is running!"
                serverStatusIcon.image = NSImage(named: "led_green")
            } else {
                pageTitleLabel.stringValue = "Server is not running!"
                serverStatusIcon.image = NSImage(named: "led_red")
            }
        }
    }
    
    @IBOutlet weak var pageTitle: NSTextField!
    @IBOutlet weak var pageUrl: NSTextField!
    @IBOutlet weak var pageTitleLabel: NSTextField!
    @IBOutlet weak var serverStatusIcon: NSImageView!
    @IBOutlet weak var folderList: NSPopUpButton!
    @IBOutlet weak var responseStatus: NSTextField!
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:320, height:273)
        return shared
    }()
    
    override func viewWillAppear() {
        print("Entered viewWillAppear()")
        super.viewWillAppear()
        checkServerStatus()
        
        if (isServerRunning) {
            loadFolders()
            loadTags()
        }
        
        clearSendStatus()
        loadPageInfo()
    }
    
    func clearSendStatus() {
        responseStatus.stringValue = ""
    }
    
    @IBAction func clipUrl(_ sender: Any) {
        let newNote = Note(title: pageTitle.stringValue, url: pageUrl.stringValue, parent: allFolders[folderList.indexOfSelectedItem].id ?? "")
        var message = ""
        NSLog("Selected Folder: \(allFolders[folderList.indexOfSelectedItem].id!)")
        
        let noteToSend = Resource<Note>(url: URL(string: "http://localhost:41184/notes")!, method: .post(newNote))
        
        URLSession.shared.load(noteToSend) { data in
            if let noteId = data?.id {
                message = "Note created!"
            } else {
                message = "Message was not created. Please try again."
            }
            
            DispatchQueue.main.async {
                self.responseStatus.stringValue = message
            }
        }

    }
    
    @IBAction func clipCompletePage(_ sender: Any) {
        NSLog("In clipCompletePage")
        sendCommandToActiveTab(command: ["name": "completePageHtml", "preProcessFor": "markdown"])
    }
    
    @IBAction func clipSimplifiedPage(_ sender: Any) {
        NSLog("In clipSimplifiedPage")
        sendCommandToActiveTab(command: ["name": "simplifiedPageHtml"])
    }
    
    func sendCommandToActiveTab(command: Dictionary<String, String>) {
        NSLog("In sendCommandToActiveTab")
        // Send 'command' to current page
        SFSafariApplication.getActiveWindow{ (activeWindow) in
            activeWindow?.getActiveTab{ (activeTab) in
                activeTab?.getActivePage{ (activePage) in
                    activePage?.dispatchMessageToScript(withName: "command", userInfo: command)
                }
            }
        }
    }
    
    func loadPageInfo() {
        SFSafariApplication.getActiveWindow{ (activeWindow) in
            activeWindow?.getActiveTab{ (activeTab) in
                activeTab?.getActivePage{ (activePage) in
                    activePage?.getPropertiesWithCompletionHandler{ (pageProperties) in
                        DispatchQueue.main.async {
                            self.pageTitle.stringValue = pageProperties?.title ?? ""
                            self.pageUrl.stringValue = pageProperties?.url?.absoluteString ?? ""
                        }
                        
                    }
                }
            }
        }
    }
    
    func checkServerStatus() {
        // THIS NEEDS CLEAN UP TO BETTER HANDLE ERRORS
        let joplinEndpoint: String = "http://localhost:41184/ping"
          NSLog("Entered checkServerStatus method")
          
        guard let joplinURL = URL(string: joplinEndpoint) else {
          NSLog("Error: cannot create URL")
          return
        }
        var joplinUrlRequest = URLRequest(url: joplinURL)
        joplinUrlRequest.httpMethod = "GET"

        let session = URLSession.shared

        let task = session.dataTask(with: joplinUrlRequest) {
          (data, response, error) in
          guard error == nil else {
            NSLog("error calling GET on /ping. Assume service is not running")
            //NSLog(error!)
//            self.pageTitleLabel.stringValue = "Server is not running!"
//            self.serverStatusIcon.image = NSImage(named: "led_red")
            self.isServerRunning = false
            return
          }
          guard let responseData = data else {
            NSLog("Error: did not receive data")
            return
          }
        
          // parse the result as String, since that's what the API provides
            guard let receivedStatus = String(data: responseData, encoding: .utf8) else {
                NSLog("Count not parse server status from response.")
                return
            }
            NSLog("The response is: " + receivedStatus)

            if receivedStatus == "JoplinClipperServer" {
//                self.pageTitleLabel.stringValue = "Server is running!"
//                self.serverStatusIcon.image = NSImage(named: "led_green")
                self.isServerRunning = true
            } else {
//                self.pageTitleLabel.stringValue = "Server is not running!"
//                self.serverStatusIcon.image = NSImage(named: "led_red")
                self.isServerRunning = false
            }
            
        }
        task.resume()

        
        //self.pageTitleLabel.stringValue = pageProperties?.title ?? ""
    }

    func loadFolders() {
        // Run code to generate list of notebooks
        folderList.removeAllItems()
        
        let folders = Resource<[Folder]>(get: URL(string: "http://localhost:41184/folders")!)
        var popupTitles = [String]()
        URLSession.shared.load(folders) { data in
            print(data ?? "No Folders")
            
            for folder in data! {
                popupTitles.append(folder.title ?? "")
            }
            
            DispatchQueue.main.async {
                self.folderList.addItems(withTitles: popupTitles)
                self.allFolders = data ?? []
                NSLog("Folders: \(self.allFolders)")
            }
        }
    }
    
    func loadTags() {
        // Run code to generate list of tags
    }
}
