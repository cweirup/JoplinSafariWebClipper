//
//  SafariExtensionViewController.swift
//  Joplin Clipper Extension
//
//  Created by Christopher Weirup on 2020-02-06.
//  Copyright © 2020 Christopher Weirup. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    @IBOutlet weak var pageTitle: NSTextField!
    @IBOutlet weak var pageUrl: NSTextField!
    @IBOutlet weak var pageTitleLabel: NSTextField!
    @IBOutlet weak var serverStatusIcon: NSImageView!
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:320, height:240)
        return shared
    }()
    
    override func viewWillAppear() {
        print("Entered viewWillAppear()")
        super.viewWillAppear()
        checkServerStatus()
        loadNotebooks()
        loadTags()
        loadPageInfo()
    }
    
    @IBAction func clipUrl(_ sender: Any) {
      let joplinEndpoint: String = "http://localhost:41184/notes"
        NSLog("Entered clipUrl method")
        
      guard let joplinURL = URL(string: joplinEndpoint) else {
        NSLog("Error: cannot create URL")
        return
      }
      var joplinUrlRequest = URLRequest(url: joplinURL)
      joplinUrlRequest.httpMethod = "POST"
        
      let newNote: [String: Any] = ["title": pageTitle.stringValue, "body": pageUrl.stringValue]
      let jsonNote: Data
      do {
        jsonNote = try JSONSerialization.data(withJSONObject: newNote, options: [])
        joplinUrlRequest.httpBody = jsonNote
      } catch {
        NSLog("Error: cannot create JSON from note")
        return
      }

      let session = URLSession.shared

      let task = session.dataTask(with: joplinUrlRequest) {
        (data, response, error) in
        guard error == nil else {
          NSLog("error calling POST on /notes")
          //NSLog(error!)
          return
        }
        guard let responseData = data else {
          NSLog("Error: did not receive data")
          return
        }

        // parse the result as JSON, since that's what the API provides
        do {
          guard let receivedNote = try JSONSerialization.jsonObject(with: responseData,
            options: []) as? [String: Any] else {
              NSLog("Could not get JSON from responseData as dictionary")
              return
          }
          NSLog("The note is: " + receivedNote.description)

          guard let noteID = receivedNote["id"] as? String else {
            NSLog("Could not get todoID as int from JSON")
            return
          }
          NSLog("The ID is: \(noteID)")
        } catch  {
          NSLog("error parsing response from POST on /notes")
          return
        }
      }
      task.resume()

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
            self.pageTitleLabel.stringValue = "Server is not running!"
            self.serverStatusIcon.image = NSImage(named: "led_red")
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
                self.pageTitleLabel.stringValue = "Server is running!"
                self.serverStatusIcon.image = NSImage(named: "led_green")
            } else {
                self.pageTitleLabel.stringValue = "Server is not running!"
                self.serverStatusIcon.image = NSImage(named: "led_red")
            }
            
        }
        task.resume()

        
        //self.pageTitleLabel.stringValue = pageProperties?.title ?? ""
    }

    func loadNotebooks() {
        // Run code to generate list of notebooks
    }
    
    func loadTags() {
        // Run code to generate list of tags
    }
}
