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
            checkAuth()
        }
    }
    var isAuthorized = false {
        didSet {
            folderList.isEnabled = isAuthorized
            tagList.isEnabled = isAuthorized
            setButtonsEnabledStatus(to: isAuthorized)
            guard isAuthorized else {
                pageTitleLabel.stringValue = "Please check Joplin to authorize Clipper."
                serverStatusIcon.image = NSImage(named: "led_orange")
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Clear the folderlist in case we aren't connecting to the server
        NSLog("BLEH - Entered viewDidLoad")
        folderList.removeAllItems()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        NSLog("BLEH - Entered viewWillAppear")
        clearSendStatus()
        loadPageInfo()
        checkServerStatus()
        //if(isServerRunning) {
        //    NSLog("BLEH - Confirmed server running - now check auth")
        //    checkAuth()
        //}
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
        clipSelectionButton.isEnabled = status
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
                    NSLog("BLEH - BLEH - Count not parse server status from response.")
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
        NSLog("BLEH - In clipCompletePage")
        responseStatus.stringValue = "Processing..."
        sendCommandToActiveTab(command: ["name": "completePageHtml", "preProcessFor": "markdown"])
    }
    
    @IBAction func clipSimplifiedPage(_ sender: Any) {
        NSLog("BLEH - In clipSimplifiedPage")
        responseStatus.stringValue = "Processing..."
        sendCommandToActiveTab(command: ["name": "simplifiedPageHtml"])
    }
    
    @IBAction func clipSelection(_ sender: Any) {
        NSLog("BLEH - In clipSelection")
        responseStatus.stringValue = "Processing..."
        sendCommandToActiveTab(command: ["name": "selectedHtml"])
        tempSelection = ""
    }
    
    @IBAction func selectFolder(_ sender: Any) {
        selectedFolderIndex = folderList.indexOfSelectedItem
    }
    
    func sendCommandToActiveTab(command: Dictionary<String, String>) {
        NSLog("BLEH - In sendCommandToActiveTab")
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
        NSLog("BLEH - In checkServerStatus()")
        // We need to also start checking for and capturing the AUTH_TOKEN here.
        // See https://github.com/laurent22/joplin/blob/dev/readme/spec/clipper_auth.md
        let joplinEndpoint: String = "http://localhost:41184/ping"
        
        Network.get(url: joplinEndpoint) { (data, error) in
            if error != nil {
                NSLog("BLEH - FUCK: " + (error?.localizedDescription ?? "No error"))
                // Assume there is a problem, set isServerRunning to false
                self.isServerRunning = false
                return
            }
            
              if let _data = data {
                  guard let receivedStatus = String(data: _data, encoding: .utf8) else {
                      NSLog("BLEH - FUCK: Count not parse server status from response.")
                      return
                  }
                  self.isServerRunning = (receivedStatus == "JoplinClipperServer")
              }
          }
    }

    func checkAuth() {
        NSLog("BLEH - In checkAuth()")
        
        // Get auth_token from UserDefaults
        let defaults = UserDefaults.standard
        let authToken = defaults.string(forKey: "authToken")
       
        // Check if we get a valid response
        // - If so, store API token in UserDefaults
        // - If not, request auth_token and update
        let params = ["auth_token": authToken]
        NSLog("BLEH - Auth Token = \(authToken)")
        
        if (authToken != nil) {
            Network.get(url: "http://localhost:41184/auth/check", params: params) { (data, error) in
                do {
                    if let _data = data {

                        let result = try JSONDecoder().decode(AuthResponse.self, from: _data)
                        NSLog("BLEH - inished JSON decoding")
                        
                        switch result {
                        case .success(let authData):
                            self.isAuthorized = true
                            defaults.set(authData.token, forKey: "apiToken")
                            NSLog("BLEH - Auth Success: \(authData.token)")
                        case .failure(let errorData):
                            // handle
                            self.isAuthorized = false
                            NSLog("BLEH - \(errorData.error)")
                        }
                    }
                } catch {
                    NSLog("BLEH - Unable to authenticate")
                }
                
            }
        } else {
            Network.post(url: "http://localhost:41184/auth") { (data, error) in
                do {
                    if let _data = data {
                        NSLog("BLEH - Getting auth_token")
                        let result = try JSONDecoder().decode(AuthToken.self, from: _data)
                        NSLog("BLEH - Finished AuthTokenJSON decoding - \(result.auth_token)")
                        
                        defaults.set(result.auth_token, forKey: "authToken")
                        
                        self.pageTitleLabel.stringValue = "Please check Joplin to authorize Clipper."
                        self.serverStatusIcon.image = NSImage(named: "led_orange")
                    }
                } catch {
                    NSLog("BLEH - Unable to get auth token.")
                }
                
            }
        }
        
        
    }
    
    private func loadFoldersIntoPopup(folders: [Folder], indent: Int = 0) {
        NSLog("BLEH - In loadFoldersIntoPopup")
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
        
        let defaults = UserDefaults.standard
        let apiToken = defaults.string(forKey: "apiToken")
        
        let params = ["as_tree": "1",
                      "token": apiToken]
        
        Network.get(url: foldersResource.url.absoluteString, params: params) { (data, error) in
            if let _data = data {
                
                let jsonData = NSString(data: _data, encoding: String.Encoding.utf8.rawValue)
                NSLog("BLEH - Data from loadFolders = \(String(describing: jsonData))")
                
                if let folders = try? JSONDecoder().decode([Folder].self, from: _data) {
                    NSLog("BLEH - Parse of Folders starting")
                    self.loadFoldersIntoPopup(folders: folders, indent: 0)
                    NSLog("BLEH - Parse of Folders complete")
                    
                    let defaults = UserDefaults.standard
                    self.folderList.selectItem(at: defaults.integer(forKey: "selectedFolderIndex"))
                } else {
                    NSLog("BLEH - Decode of Folders failed")
                }
            }
            
            self.loadTags()
        }
    }
    
    func loadTags() {
        // Run code to generate list of tags
        builtInTagKeywords.removeAll()

        let defaults = UserDefaults.standard
        let apiToken = defaults.string(forKey: "apiToken")
        
        let params = ["token": apiToken]
        
        Network.get(url: tagsResource.url.absoluteString, params: params as [String : Any]) { (data, error) in
            if let _data = data {
                let jsonData = NSString(data: _data, encoding: String.Encoding.utf8.rawValue)
                NSLog("BLEH - Data from loadTags = \(String(describing: jsonData))")
                
                if let response = try? JSONDecoder().decode(Response.self, from: _data) {
                    for tag in response.items! {
                        self.builtInTagKeywords.append(tag.title ?? "")
                    }
                    
                    //has_more = response.has_more == "false" ? false : true
                } else { NSLog("BLEH - Error parsing Tag feed") }
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
