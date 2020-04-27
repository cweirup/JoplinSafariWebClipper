//
//  SafariExtensionViewController.swift
//  Joplin Clipper Extension
//
//  Created by Christopher Weirup on 2020-02-06.
//  Copyright © 2020 Christopher Weirup. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController, NSTokenFieldDelegate {
    
    var allFolders = [Folder]()
    var isServerRunning = false {
        didSet {
            folderList.isEnabled = isServerRunning
            tagList.isEnabled = isServerRunning
            setButtonsEnabledStatus(to: isServerRunning)
            guard isServerRunning else {
                pageTitleLabel.stringValue = "Server is not running!"
                serverStatusIcon.image = NSImage(named: "led_red")
                return
            }
            pageTitleLabel.stringValue = "Server is running!"
            serverStatusIcon.image = NSImage(named: "led_green")
            loadFolders()
        }
    }
    
    var selectedFolderIndex = 0
    
    var builtInTagKeywords = [String]()
    var tagMatches = [String]()
    
    let foldersResource = FoldersResource()
    let tagsResource = TagsResource()
    
    // Used for temporary storage of selection from web page for later saving
    var tempSelection: String = ""
    
    @IBOutlet weak var pageTitle: NSTextField!
    @IBOutlet weak var pageUrl: NSTextField!
    @IBOutlet weak var pageTitleLabel: NSTextField!
    @IBOutlet weak var serverStatusIcon: NSImageView!
    @IBOutlet weak var folderList: NSPopUpButton!
    @IBOutlet weak var responseStatus: NSTextField!
    @IBOutlet weak var tagList: NSTokenField!
    
    @IBOutlet weak var clipUrlButton: NSButton!
    @IBOutlet weak var clipCompletePageButton: NSButton!
    @IBOutlet weak var clipSimplifiedPageButton: NSButton!
    @IBOutlet weak var clipSelectionButton: NSButton!
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:330, height:366)
        return shared
    }()
    
    override func viewWillAppear() {
        super.viewWillAppear()
        clearSendStatus()
        loadPageInfo()
        checkServerStatus()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        // Save the currently selected folder
        let defaults = UserDefaults.standard
        defaults.set(folderList.indexOfSelectedItem, forKey: "selectedFolderIndex")
        
        // Clear out the Tags - This will mimic the behavior of the Chrome/Firefox extension
        tagList.stringValue = ""
    }
    
    func clearSendStatus() {
        responseStatus.stringValue = ""
    }
    
    private func setButtonsEnabledStatus(to status: Bool) {
        clipUrlButton.isEnabled = status
        clipCompletePageButton.isEnabled = status
        clipSimplifiedPageButton.isEnabled = status
    }
    
    @IBAction func clipUrl(_ sender: Any) {
        responseStatus.stringValue = "Processing..."
        
        var newNote = Note(title: pageTitle.stringValue, url: pageUrl.stringValue, parent: allFolders[folderList.indexOfSelectedItem].id ?? "")
        newNote.body_html = pageUrl.stringValue
        newNote.tags = tagList.stringValue
        
        var message = ""
        
        Network.post(url: URL(string: "http://localhost:41184/notes")!, object: newNote) { (data, error) in
            if let _data = data {
                guard let confirmedNote = try? JSONDecoder().decode(Note.self, from: _data) else {
                    NSLog("Count not parse server status from response.")
                    return
                }
                if (confirmedNote.id) != nil {
                    message = "Note created!"
                } else {
                    message = "Message was not created. Please try again."
                }
                
                self.responseStatus.stringValue = message
            }
            
        }

    }
    
    @IBAction func clipCompletePage(_ sender: Any) {
        NSLog("In clipCompletePage")
        responseStatus.stringValue = "Processing..."
        sendCommandToActiveTab(command: ["name": "completePageHtml", "preProcessFor": "markdown"])
    }
    
    @IBAction func clipSimplifiedPage(_ sender: Any) {
        NSLog("In clipSimplifiedPage")
        responseStatus.stringValue = "Processing..."
        sendCommandToActiveTab(command: ["name": "simplifiedPageHtml"])
    }
    
    @IBAction func clipSelection(_ sender: Any) {
        NSLog("In clipSelection")
        responseStatus.stringValue = "Processing..."
        sendCommandToActiveTab(command: ["name": "selectedHtml"])
        tempSelection = ""
    }
    
    @IBAction func selectFolder(_ sender: Any) {
        selectedFolderIndex = folderList.indexOfSelectedItem
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
        let joplinEndpoint: String = "http://localhost:41184/ping"
        
        Network.get(url: joplinEndpoint) { (data, error) in
              if let _data = data {
                  guard let receivedStatus = String(data: _data, encoding: .utf8) else {
                      NSLog("Count not parse server status from response.")
                      return
                  }
                  self.isServerRunning = (receivedStatus == "JoplinClipperServer")
              }
          }
    }

    private func loadFoldersIntoPopup(folders: [Folder], indent: Int = 0) {
        for folder in folders {
            // Initially setting the popup item to 'BLANK' then setting the title
            // This allows us to have duplicate notebook/folder titles in the dropdown list
            // Just using .addItem removes any duplicates
            self.folderList.addItem(withTitle: "BLANK")
            self.folderList.lastItem?.title = (folder.title ?? "")
            self.folderList.lastItem?.indentationLevel = indent
            self.allFolders.append(folder)
            if folder.children != nil {
                loadFoldersIntoPopup(folders: folder.children!, indent: (indent+1))
            }
        }
    }
    
    func loadFolders() {
        // Run code to generate list of notebooks
        folderList.removeAllItems()

        Network.get(url: foldersResource.url.absoluteString) { (data, error) in
            if let _data = data {
                
                let jsonData = NSString(data: _data, encoding: String.Encoding.utf8.rawValue)
                NSLog("Data from loadFolders = \(String(describing: jsonData))")
                
                if let folders = try? JSONDecoder().decode([Folder].self, from: _data) {
                    self.loadFoldersIntoPopup(folders: folders, indent: 0)

                    let defaults = UserDefaults.standard
                    self.folderList.selectItem(at: defaults.integer(forKey: "selectedFolderIndex"))
                }
            }
            
            self.loadTags()
        }
    }
    
    func loadTags() {
        // Run code to generate list of tags
        builtInTagKeywords.removeAll()

        Network.get(url: tagsResource.url.absoluteString) { (data, error) in
            if let _data = data {
                if let tags = try? JSONDecoder().decode([Tag].self, from: _data) {
                    for tag in tags {
                        self.builtInTagKeywords.append(tag.title ?? "")
                    }
                }
            }
        }
        
    }
    
    // MARK: - NSTokenFieldDelegate methods
    func tokenField(_ tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [Any]? {
        
        tagMatches = builtInTagKeywords.filter { keyword in
            return keyword.lowercased().hasPrefix(substring.lowercased())
        }

        return tagMatches;
    }
}
