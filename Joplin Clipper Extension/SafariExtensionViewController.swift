//
//  SafariExtensionViewController.swift
//  Joplin Clipper Extension
//
//  Created by Christopher Weirup on 2020-02-06.
//  Copyright © 2020 Christopher Weirup. All rights reserved.
//

import SafariServices
import os

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
            // I think this is causing the dialog to disappear when granting authorization
            // As well as loading folders twice
            //loadFolders()
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
    // NEED SOMETHING TO TRACK AUTH STATUS
    
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
        folderList.removeAllItems()
        tagList.completionDelay = 0.25
    }
    
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
        clipSelectionButton.isEnabled = status
    }
    
    @IBAction func clipUrl(_ sender: Any) {
        responseStatus.stringValue = "Processing..."
        
        var newNote = Note(title: pageTitle.stringValue,
                           url: pageUrl.stringValue,
                           parent: allFolders[folderList.indexOfSelectedItem].id ?? "")
        newNote.body_html = pageUrl.stringValue
        newNote.tags = tagList.stringValue
        
        var message = ""
        
        let apiToken = getAPIToken()
        let params = ["token": apiToken]
        
        Network.post(url: URL(string: "http://localhost:41184/notes")!, params: params, object: newNote) { (data, error) in
            if let _data = data {
                guard let confirmedNote = try? JSONDecoder().decode(Note.self, from: _data) else {
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
        responseStatus.stringValue = "Processing..."
        sendCommandToActiveTab(command: ["name": "completePageHtml", "preProcessFor": "markdown"])
    }
    
    @IBAction func clipSimplifiedPage(_ sender: Any) {
        responseStatus.stringValue = "Processing..."
        os_log("JSC - in clipSimplifiedPage function")
        sendCommandToActiveTab(command: ["name": "simplifiedPageHtml"])
    }
    
    @IBAction func clipSelection(_ sender: Any) {
        responseStatus.stringValue = "Processing..."
        sendCommandToActiveTab(command: ["name": "selectedHtml"])
        tempSelection = ""
    }
    
    @IBAction func selectFolder(_ sender: Any) {
        selectedFolderIndex = folderList.indexOfSelectedItem
    }
    
    func sendCommandToActiveTab(command: Dictionary<String, String>) {
        os_log("JSC - in sendCommandToActiveTab function")
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
        os_log("JSC - In checkServerStatus()")
        // We need to also start checking for and capturing the AUTH_TOKEN here.
        // See https://github.com/laurent22/joplin/blob/dev/readme/spec/clipper_auth.md
        let joplinEndpoint: String = "http://localhost:41184/ping"
        
        Network.get(url: joplinEndpoint) { (data, error) in
            if error != nil {
                //os_log("JSC - \(error?.localizedDescription ?? "No error")")
                // Assume there is a problem, set isServerRunning to false
                self.isServerRunning = false
                return
            }
            
              if let _data = data {
                  guard let receivedStatus = String(data: _data, encoding: .utf8) else {
                      os_log("JSC - Count not parse server status from response.")
                      return
                  }
                  
                  self.isServerRunning = (receivedStatus == "JoplinClipperServer")
              }
          }
    }

    func checkAuth() {
        os_log("JSC - In checkAuth()")
        
        // How Joplin handles programmatically retrieving tokens:
        // 2 Token Types:
        //  1. API Token ("token") - Used for all API calls
        //  2. Auth Token ("auth_token") - Used to grant permission to get API Token
        
        // First, check if we have an AuthToken and an APIToken
        //  Then test using APIToken
        //  If good, we keep going
        //  Otherwise, need to reauth the clipper
        
        // OR Check other API calls - if we get an token error on the response, start the Auth process
        
        // Retrieve both tokens
        let defaults = UserDefaults.standard
        let apiToken = defaults.string(forKey: "apiToken")
        let authToken = defaults.string(forKey: "authToken")
        
        //let log = OSLog(subsystem: "Joplin Clipper", category: "auth")
        //os_log("JSC - AUTH - apiToken from initial check = %{public}@", log: log, type: .info, (apiToken ?? "Got nothing"))
        //os_log("JSC - AUTH - authToken from initial check = %{public}@", log: log, type: .info, (authToken ?? "Got nothing"))

        // Check the API Token
        if (apiToken != nil) {
            os_log("JSC - AUTH - Inside API Token check.")
            let params = ["token": apiToken]
            Network.get(url:"http://localhost:41184/auth/check", params: params as [String : Any]) { (data, error) in
                // Check if we get true back
                // If so, we are good to continue
                // If not, we need to reauthorize by
                // PROBLEM: We aren't getting "nil", we get FALSE back. Need to check for that.
                
                os_log("JSC - AUTH - Is Error Here? %{public}@", error.debugDescription)
                if (error != nil) {
                    
                    //print("Error: \(error!)")
                    os_log("JSC - AUTH - Error: %{public}@", error.debugDescription)
                } else {
                    do {
                        let api_token_check = try JSONDecoder().decode(ApiCheck.self, from: data!)
                        if (api_token_check.valid == true) {
                            os_log("JSC - AUTH - Confirmed API Token is valid.")
                            // All good, let's get out of here
                            self.isAuthorized = true
                        } else {
                            os_log("JSC - AUTH - API Token is invalid!")
                            // Need a new API Token
                            // Clear out the tokens and re-request
                            defaults.removeObject(forKey: "apiToken")
                            defaults.removeObject(forKey: "authToken")
                            self.requestAuth()
                        }
                    } catch {
                        os_log("JSC - AUTH _ Error checking if API Token is valid.")
                    }
                }
            }
        } else if (authToken != nil) {
            let params = ["auth_token": authToken]
            os_log("JSC - AUTH - Inside Auth Token Check.")
            // Now check the Auth Token if we don't have a valid API token
            Network.get(url: "http://localhost:41184/auth/check", params: params) { (data, error) in
                do {
                    if let _data = data {

                        let result = try JSONDecoder().decode(AuthResponse.self, from: _data)
                        
                        switch result {
                        case .accepted(let successAuth):
                            defaults.set(successAuth.token, forKey: "apiToken")
                            self.isAuthorized = true
                            os_log("JSC - AUTH - Got successful authorization")
                        case .waiting( _):
                            self.isAuthorized = false
                            self.pageTitleLabel.stringValue = "Please check Joplin to authorize Clipper."
                            self.serverStatusIcon.image = NSImage(named: "led_orange")
                        case .rejected( _):
                            self.isAuthorized = false
                            // What do we do if it's rejected? I guess clear out the API
                            // and request a new token.
                            self.requestAuth()
                            self.pageTitleLabel.stringValue = "Authorization Failed. Check Joplin for new request."
                            self.serverStatusIcon.image = NSImage(named: "led_red")
                        case .failure(let errorData):
                            // handle
                            self.isAuthorized = false
                            //os_log("JSC - \(errorData.error)")
                        }
                    }
                } catch {
                    os_log("JSC - Unable to authenticate")
                }
                
            }
        } else {
            requestAuth()
        }
        
        
    }
    
    private func requestAuth() {
        let defaults = UserDefaults.standard
        
        Network.post(url: "http://localhost:41184/auth") { (data, error) in
            do {
                if let _data = data {
                    os_log("JSC - Getting auth_token")
                    let result = try JSONDecoder().decode(AuthToken.self, from: _data)
                   // os_log("JSC - Finished AuthTokenJSON decoding - \(result.auth_token)")
                    
                    defaults.set(result.auth_token, forKey: "authToken")
                    
                    self.pageTitleLabel.stringValue = "Please check Joplin to authorize Clipper."
                    self.serverStatusIcon.image = NSImage(named: "led_orange")
                }
            } catch {
                os_log("JSC - Unable to get auth token.")
            }
            
        }
    }
    
    private func loadFoldersIntoPopup(folders: [Folder], indent: Int = 0) {
        //os_log("JSC - In loadFoldersIntoPopup")
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

        let apiToken = getAPIToken()
        
        let params = ["as_tree": "1",
                      "token": apiToken]
        
        Network.get(url: foldersResource.url.absoluteString, params: params) { (data, error) in
            if let _data = data {
                
                //let jsonData = NSString(data: _data, encoding: String.Encoding.utf8.rawValue)
                let jsonData = String(data: _data, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue) )
//                guard let json = _data as? [String:AnyObject] else {
//                    return
//                }
                
                // Check if we got Folders or Error in the response
                do {
                    //if let folders =  jsonData!.contains("id"){
                    if jsonData!.contains("id") {
                        os_log("JSC - Received valid Folders in loadFolders")
                        // We received folders information
                        if let folders = try? JSONDecoder().decode([Folder].self, from: _data) {
                            self.loadFoldersIntoPopup(folders: folders, indent: 0)
                            
                            let defaults = UserDefaults.standard
                            self.folderList.selectItem(at: defaults.integer(forKey: "selectedFolderIndex"))
                        } else {
                            os_log("JSC - Decode of Folders failed")
                        }
                    } else {
                        // Mostly likely Error, will need to reauthorize
                        //let res = try JSONDecoder().decode(Valid.self, from: data)
                        os_log("JSC - Did not get valid folders in loadFolders")
                        self.checkAuth()
                        return
                    }
                } catch let error {
                    print(error)
                }
                
                
//                if let folders = try? JSONDecoder().decode([Folder].self, from: _data) {
//                    self.loadFoldersIntoPopup(folders: folders, indent: 0)
//
//                    let defaults = UserDefaults.standard
//                    self.folderList.selectItem(at: defaults.integer(forKey: "selectedFolderIndex"))
//                } else {
//
//                    os_log("JSC - Decode of Folders failed")
//
//                }
            }
            
            self.loadTags()
        }
    }
    
    func loadTags() {
        os_log("JSC - loadTags - Entered function")
        
        // Run code to generate list of tags
        builtInTagKeywords.removeAll()

        //let defaults = UserDefaults.standard
        // let apiToken = defaults.string(forKey: "apiToken")
        
        let apiToken = getAPIToken()
        
        let params = ["token": apiToken]
        
        os_log("JSC - loadTags - Start network requeest.")
        Network.get(url: tagsResource.url.absoluteString, params: params as [String : Any]) { (data, error) in
            if let _data = data {
                //let jsonData = NSString(data: _data, encoding: String.Encoding.utf8.rawValue)
                //os_log("JSC - Data from loadTags = \(String(describing: _data))")
                //os_log("JSC - loadTags - Tag Retrieval Response = %{public}@", log: log, type: .info, (_data as CVarArg ?? "Got nothing"))
                
                if let response = try? JSONDecoder().decode(Response.self, from: _data) {
                    for tag in response.items! {
                        self.builtInTagKeywords.append(tag.title ?? "")
                        //os_log("JSC - loadTags - Tag Retrieval Response = %{public}@", log: log, type: .info, (tag.title ?? "Got nothing"))
                    }
                    
                    //has_more = response.has_more == "false" ? false : true
                } else { os_log("JSC - Error parsing Tag feed") }
            }
        }

        
    }
    
    private func getAPIToken() -> String {
        let defaults = UserDefaults.standard
        let apiToken = defaults.string(forKey: "apiToken")
        return apiToken!
    }
    
    // MARK: - NSTokenFieldDelegate methods
    func tokenField(_ tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [Any]? {
        
        tagMatches = builtInTagKeywords.filter { keyword in
            return keyword.lowercased().hasPrefix(substring.lowercased())
        }

        return tagMatches;
    }
}

