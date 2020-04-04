//
//  SafariExtensionHandler.swift
//  Joplin Clipper Extension
//
//  Created by Christopher Weirup on 2020-02-06.
//  Copyright © 2020 Christopher Weirup. All rights reserved.
//

import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
        if messageName == "commandResponse" {
            page.getPropertiesWithCompletionHandler { properties in
                        //NSLog("The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))")
                        
                let parentId = SafariExtensionViewController.shared.allFolders[SafariExtensionViewController.shared.folderList.indexOfSelectedItem].id ?? ""
                //let newNote = Note(id: "", base_url: userInfo?["base_url"] as? String, parent_id: parentId, title: userInfo?["title"] as? String, url: (userInfo?["url"] as! String), body: "", body_html: userInfo?["html"] as? String)
                
                let title = SafariExtensionViewController.shared.pageTitle.stringValue
                let url = SafariExtensionViewController.shared.pageUrl.stringValue
                
                let newNote = Note(id: "", base_url: userInfo?["base_url"] as? String, parent_id: parentId, title: title, url: url, body: "", body_html: userInfo?["html"] as? String)
                
                //let newNote = Note(title: userInfo?["title"] as! String, url: userInfo?["url"] as! String)
                //NSLog(newNote.title!)
                var message = ""
    
                let noteToSend = Resource<Note>(url: URL(string: "http://localhost:41184/notes")!, method: .post(newNote))
                //NSLog(String(data: noteToSend.urlRequest.httpBody!, encoding: .utf8)!)
                URLSession.shared.load(noteToSend) { data in
                    if (data?.id) != nil {
                        message = "Note created!"
                    } else {
                        message = "Message was not created. Please try again."
                    }
    
                    DispatchQueue.main.async {
                        SafariExtensionViewController.shared.responseStatus.stringValue = message
                    }
                }
            }
        }
//        page.getPropertiesWithCompletionHandler { properties in
//            NSLog("The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))")
            
//            let parentId = SafariExtensionViewController.shared.allFolders[SafariExtensionViewController.shared.folderList.indexOfSelectedItem].id ?? ""
//            let newNote = Note(id: "", base_url: userInfo?["base_url"] as? String, parent_id: parentId, title: userInfo?["title"] as? String, url: (userInfo?["url"] as! String), body: "", body_html: userInfo?["html"] as? String)
//
//            //let newNote = Note(title: userInfo?["title"] as! String, url: userInfo?["url"] as! String)
//            //NSLog(newNote.title!)
//            var message = ""
//
//            let noteToSend = Resource<Note>(url: URL(string: "http://localhost:41184/notes")!, method: .post(newNote))
//            //NSLog(String(data: noteToSend.urlRequest.httpBody!, encoding: .utf8)!)
//            URLSession.shared.load(noteToSend) { data in
//                if (data?.id) != nil {
//                    message = "Note created!"
//                } else {
//                    message = "Message was not created. Please try again."
//                }
//
//                DispatchQueue.main.async {
//                    SafariExtensionViewController.shared.responseStatus.stringValue = message
//                }
//            }
//        }
    }
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        // This method will be called when your toolbar item is clicked.
        NSLog("The extension's toolbar item was clicked")
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        // This is called when Safari's state changed in some way that would require the extension's toolbar item to be validated again.
        validationHandler(true, "")
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }

}
