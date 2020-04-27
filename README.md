# Joplin Web Clipper for Safari
This is an Safari App Extension for a Joplin Web Clipper.

[Joplin](https://joplinapp.org "Joplin Homepage") is an open-source note taking and to-do application. It includes browser extensions for Chrome and Firefox that allows you to clip the current page/tab into Joplin. This extension is built with Javascript and React.

However, Safari now requires extensions that are at least partially based on native code (Swift or Objective-C) and must be initally run from a Mac app. This means the Web Clipper included with Joplin will not work. There is currently no Safari App Extension that I am aware of. This is my attempt at making one.

Please note that this is very much **ALPHA** quality code at this point. The core functionality works for normal day-to-day usages, but you will find bugs and issues.

## Working
* Clip URL
* Clip Complete Page (to Markdown)
* Clip Simplified Page
* Folder Selector (now remembers last folder used and supports subfolders)
* Server Status Check
* Tags
* Clip Selection
  * If you are using Stop the Madness, you will need to allow "Text selection" for "Clip Selection" to work. 

## Not Working/Missing
* Clip Complete Page (to HTML)
* Clip Image Capture

I'm new at Safari App Extension development, so bear with me as we learn along together!

## License
Joplin Web Clipper is available under the MIT license. See the LICENSE.md file for more info.
