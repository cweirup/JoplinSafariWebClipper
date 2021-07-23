//
//  SafariExtensionHandler.swift
//  Joplin Clipper Extension
//
//  Created by Christopher Weirup on 2020-02-06.
//  Copyright © 2020 Christopher Weirup. All rights reserved.
//

import SafariServices
import os

class SafariExtensionHandler: SFSafariExtensionHandler {
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
        
        if messageName == "selectedText" {
            os_log("JSC - In selectedText messageReceived")
            if let selectedText = userInfo?["text"] {
                DispatchQueue.main.async {
                    SafariExtensionViewController.shared.tempSelection = selectedText as! String
                    //SafariExtensionViewController.shared.tagList.stringValue = ""
                }
            }
        } else if messageName == "commandResponse" {
            page.getPropertiesWithCompletionHandler { properties in
                // Folder to store the note
                let parentId = SafariExtensionViewController.shared.allFolders[SafariExtensionViewController.shared.folderList.indexOfSelectedItem].id ?? ""
                
                let title = SafariExtensionViewController.shared.pageTitle.stringValue
                let url = SafariExtensionViewController.shared.pageUrl.stringValue
                let tags = SafariExtensionViewController.shared.tagList.stringValue
                
                let newNote = Note(id: "", base_url: userInfo?["base_url"] as? String, parent_id: parentId, title: title, url: url, body: "", body_html: userInfo?["html"] as? String, tags: tags)
                
                //let newNote = Note(title: userInfo?["title"] as! String, url: userInfo?["url"] as! String)
                //NSLog(newNote.title!)
                var message = ""
    
                let notesUrl = URL(string: "http://localhost:41184/notes")
                
                let defaults = UserDefaults.standard
                let apiToken = defaults.string(forKey: "apiToken")
                
                //let tokenQuery = URLQueryItem(name: "token", value: apiToken)
                let tokenQuery = ["token": apiToken]
                
                //components?.queryItems = [tokenQuery]
                
                //let notesUrl = components?.url
                //NSLog("BLEH - messageReceived URL - \(notesUrl!.absoluteString)")
                
                //let noteToSend = Resource<Note>(url: URL(string: "http://localhost:41184/notes")!, method: .post(newNote))
                let noteToSend = Resource<Note>(url: notesUrl!, params: tokenQuery, method: .post(newNote))
//                NSLog(String(data: noteToSend.urlRequest.httpBody!, encoding: .utf8)!)
//                NSLog(noteToSend.urlRequest.url?.absoluteString ?? "Error parsing URL for POST")
                URLSession.shared.load(noteToSend) { data in
                    if (data?.id) != nil {
                        message = "Note created!"
                    } else {
                        message = "Message was not created. Please try again."
                    }
    
                    DispatchQueue.main.async {
                        SafariExtensionViewController.shared.responseStatus.stringValue = message
                        //SafariExtensionViewController.shared.tagList.stringValue = ""
                    }
                }
            }
            
        }
    }
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        // This method will be called when your toolbar item is clicked.
        NSLog("BLEH - The extension's toolbar item was clicked")
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        // This is called when Safari's state changed in some way that would require the extension's toolbar item to be validated again.
        validationHandler(true, "")
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
    
    override func popoverWillShow(in window: SFSafariWindow) {
        NSLog("BLEH - In popoverWillShow")
        window.getActiveTab { activeTab in
            activeTab?.getActivePage { activePage in
                activePage?.dispatchMessageToScript(withName: "getSelectedText", userInfo: nil)
            }
        }
    }

}
