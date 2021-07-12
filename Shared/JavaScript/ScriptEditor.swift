//
//  ScriptEditor.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import Foundation

#if !os(tvOS)

import SwiftUI
import WebKit
import Combine

/// Possible compile errors returned by component verification
struct CarthageJSError
{
    var component       : CarthageObject? = nil
    var line            : Int32? = nil
    var column          : Int32? = 0
    var error           : String? = nil
    var type            : String = "error"
}

class ScriptEditor
{
    var webView         : WKWebView
    var model           : CarthageModel
    var sessions        : Int = 0
    var colorScheme     : ColorScheme
    
    var helpText        : String = ""
        
    init(_ view: WKWebView, _ model: CarthageModel,_ colorScheme: ColorScheme)
    {
        self.webView = view
        self.model = model
        self.colorScheme = colorScheme
        
        if let object = model.selected {
            setSession(object)
        }
        setTheme(colorScheme)

        /*
        if let asset = core.assetFolder.getAsset("main", .Source) {
            core.assetFolder.select(asset.id)
            createSession(asset)
            setTheme(colorScheme)
        }*/
    }
    
    func setTheme(_ colorScheme: ColorScheme)
    {
        let theme: String
        if colorScheme == .light {
            theme = "tomorrow"
        } else {
            theme = "tomorrow_night_bright"
            //theme = "tomorrow_night"
        }
        webView.evaluateJavaScript(
            """
            editor.setTheme("ace/theme/\(theme)");
            """, completionHandler: { (value, error ) in
         })
    }
    
    func createSession(_ object: CarthageObject,_ cb: (()->())? = nil)
    {
        if object.scriptContext.isEmpty {
            object.scriptContext = "session" + String(sessions)
            sessions += 1
        }

        webView.evaluateJavaScript(
            """
            var \(object.scriptContext) = ace.createEditSession(`\(object.code)`)
            editor.setSession(\(object.scriptContext))
            editor.session.setMode("ace/mode/javascript");
            """, completionHandler: { (value, error ) in
                if let cb = cb {
                    cb()
                }
         })
    }
    
    func setReadOnly(_ readOnly: Bool = false)
    {
        webView.evaluateJavaScript(
            """
            editor.setReadOnly(\(readOnly));
            """, completionHandler: { (value, error) in
         })
    }
    
    func setSilentMode(_ silent: Bool = false)
    {
        webView.evaluateJavaScript(
            """
            editor.setOptions({
                cursorStyle: \(silent ? "'wide'" : "'ace'") // "ace"|"slim"|"smooth"|"wide"
            });
            """, completionHandler: { (value, error) in
         })
    }
    
    func getValue(_ object: CarthageObject,_ cb: @escaping (String)->() )
    {
        webView.evaluateJavaScript(
            """
            \(object.scriptContext).getValue()
            """, completionHandler: { (value, error) in
                print(error)
                if let value = value as? String {
                    cb(value)
                }
         })
    }
    /*
    func setAssetValue(_ asset: Asset, value: String)
    {
        let cmd = """
        \(asset.scriptName).setValue(`\(value)`)
        """
        webView.evaluateJavaScript(cmd, completionHandler: { (value, error ) in
        })
    }
    
    func setAssetLine(_ asset: Asset, line: String)
    {
        let cmd = """
        {var Range = require("ace/range").Range
        var currentPosition = editor.selection.getCursor();
        editor.session.replace(new Range(editor.selection.lead.row, 0, editor.selection.lead.row, Number.MAX_VALUE), `\(line)`);
        editor.gotoLine(currentPosition.row+1, currentPosition.column);}
        """
        webView.evaluateJavaScript(cmd, completionHandler: { (value, error ) in
        })
    }*/
    
    func setSession(_ object: CarthageObject)
    {
        func setSession()
        {
            let cmd = """
            editor.setSession(\(object.scriptContext))
            """
            webView.evaluateJavaScript(cmd, completionHandler: { (value, error ) in
            })
        }
                
        if object.scriptContext.isEmpty == true {
            createSession(object, { () in
                setSession()
            })
        } else {
            setSession()
        }

        //parser = nil
        //parser = ComponentParser(component)
    }
    
    func setError(_ error: CarthageJSError, scrollToError: Bool = false)
    {
        webView.evaluateJavaScript(
            """
            editor.getSession().setAnnotations([{
            row: \(error.line!-1),
            column: \(error.column!),
            text: "\(error.error!)",
            type: "error" // also warning and information
            }]);

            \(scrollToError == true ? "editor.scrollToLine(\(error.line!-1), true, true, function () {});" : "")

            """, completionHandler: { (value, error ) in
         })
    }
    
    func setErrors(_ errors: [CarthageJSError])
    {
        var str = "["
        for error in errors {
            str +=
            """
            {
                row: \(error.line!),
                column: \(error.column!),
                text: \"\(error.error!)\",
                type: \"\(error.type)\"
            },
            """
        }
        str += "]"
        
        webView.evaluateJavaScript(
            """
            editor.getSession().setAnnotations(\(str));
            """, completionHandler: { (value, error ) in
         })
    }
    
    func setFailures(_ lines: [Int32])
    {
        var str = "["
        for line in lines {
            str +=
            """
            {
                row: \(line),
                column: 0,
                text: "Failed",
                type: "error"
            },
            """
        }
        str += "]"
        
        webView.evaluateJavaScript(
            """
            editor.getSession().setAnnotations(\(str));
            """, completionHandler: { (value, error ) in
         })
    }
    
    func gotoLine(_ line: Int32,_ column: Int32 = 0)
    {
        webView.evaluateJavaScript(
            """
            editor.getCursorPosition().row
            editor.scrollToLine(\(line), true, true, function () {});
            editor.gotoLine(\(line), \(column), true);
            """, completionHandler: { (value, error ) in
         })
    }
    
    func getSessionCursor(_ cb: @escaping (Int32, Int32)->() )
    {
        webView.evaluateJavaScript(
            """
            editor.getCursorPosition()
            """, completionHandler: { (value, error ) in
                //if let v = value as? Int32 {
                //    cb(v)
                //}
                
                //print(value)
                if let map = value as? [String:Any] {
                    var row      : Int32 = -1
                    var column   : Int32 = -1
                    if let r = map["row"] as? Int32 {
                        row = r
                    }
                    if let c = map["column"] as? Int32 {
                        column = c
                    }

                    cb(row, column)
                }
         })
    }
    
    func getChangeDelta(_ cb: @escaping (Int32, Int32)->() )
    {
        webView.evaluateJavaScript(
            """
            delta
            """, completionHandler: { (value, error ) in
                //print(value)
                if let map = value as? [String:Any] {
                    var from : Int32 = -1
                    var to   : Int32 = -1
                    if let f = map["start"] as? [String:Any] {
                        if let ff = f["row"] as? Int32 {
                            from = ff
                        }
                    }
                    if let t = map["end"] as? [String:Any] {
                        if let tt = t["row"] as? Int32 {
                            to = tt
                        }
                    }
                    cb(from, to)
                }
         })
    }
    
    func clearAnnotations()
    {
        webView.evaluateJavaScript(
            """
            editor.getSession().clearAnnotations()
            """, completionHandler: { (value, error ) in
         })
    }
    
    /// The code was updated in the editor, set the value to the current object code
    func updated()
    {
        if let object = model.selected {
            getValue(object, { (value) in
                object.code = value
                print(value)
                /*
                if let device = self.model.renderer?.device {
                    self.parser?.verify(device, { errors in

                        DispatchQueue.main.async {
                            if errors.isEmpty {
                                self.clearAnnotations()
                                //self.model.componentPreviewNeedsUpdate.send()
                            } else {
                                self.setErrors(errors)
                            }
                        }
                    })
                }*/
            })
        }
        /*
        if let asset = core.assetFolder.current {
            getAssetValue(asset, { (value) in
                self.core.assetFolder.assetUpdated(id: asset.id, value: value)
                //self.getChangeDelta({ (from, to) in
                //    self.game.assetFolder.assetUpdated(id: asset.id, value: value, deltaStart: from, deltaEnd: to)
                //})
            })
        }*/
    }
}

class WebViewModel: ObservableObject {
    @Published var didFinishLoading: Bool = false
    
    init () {
    }
}

#if os(OSX)
struct SwiftUIWebView: NSViewRepresentable {
    public typealias NSViewType     = WKWebView
    var model                       : CarthageModel!
    var colorScheme                 : ColorScheme

    private let webView: WKWebView = WKWebView()
    public func makeNSView(context: NSViewRepresentableContext<SwiftUIWebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator as? WKUIDelegate
        webView.configuration.userContentController.add(context.coordinator, name: "jsHandler")
        
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Files") {
            webView.isHidden = true
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: NSViewRepresentableContext<SwiftUIWebView>) { }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(model, colorScheme)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        
        private var model        : CarthageModel
        private var colorScheme : ColorScheme

        init(_ model: CarthageModel,_ colorScheme: ColorScheme) {
            self.model = model
            self.colorScheme = colorScheme
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "jsHandler" {
                if let scriptEditor = model.scriptEditor {
                    scriptEditor.updated()
                }
            }
        }
        
        public func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) { }

        public func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) { }

        //After the webpage is loaded, assign the data in WebViewModel class
        public func webView(_ web: WKWebView, didFinish: WKNavigation!) {
            model.scriptEditor = ScriptEditor(web, model, colorScheme)
            web.isHidden = false
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}
#else
struct SwiftUIWebView: UIViewRepresentable {
    public typealias UIViewType = WKWebView
    var model       : Model!
    var colorScheme : ColorScheme
    
    private let webView: WKWebView = WKWebView()
    public func makeUIView(context: UIViewRepresentableContext<SwiftUIWebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator as? WKUIDelegate
        webView.configuration.userContentController.add(context.coordinator, name: "jsHandler")
        
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Files") {
            
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<SwiftUIWebView>) { }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(model, colorScheme)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        
        private var model        : Model
        private var colorScheme : ColorScheme
        
        init(_ model: Model,_ colorScheme: ColorScheme) {
            self.model = model
            self.colorScheme = colorScheme
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "jsHandler" {
                if let scriptEditor = model.scriptEditor {
                    scriptEditor.updated()
                }
            }
        }
        
        public func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) { }

        public func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) { }

        //After the webpage is loaded, assign the data in WebViewModel class
        public func webView(_ web: WKWebView, didFinish: WKNavigation!) {
            model.scriptEditor = ScriptEditor(web, model, colorScheme)
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

    }
}

#endif

struct WebView  : View {
    var model       : CarthageModel
    var colorScheme : ColorScheme

    init(_ model: CarthageModel,_ colorScheme: ColorScheme) {
        self.model = model
        self.colorScheme = colorScheme
    }
    
    var body: some View {
        SwiftUIWebView(model: model, colorScheme: colorScheme)
    }
}

#else

class ScriptEditor
{
    var mapHelpText     : String = "## Available:\n\n"
    var behaviorHelpText: String = "## Available:\n\n"
    
    func createSession(_ asset: Asset,_ cb: (()->())? = nil) {}
    
    func setAssetValue(_ asset: Asset, value: String) {}
    func setAssetSession(_ asset: Asset) {}
    
    func setError(_ error: CompileError, scrollToError: Bool = false) {}
    func setErrors(_ errors: [CompileError]) {}
    func clearAnnotations() {}
    
    func getSessionCursor(_ cb: @escaping (Int32)->() ) {}
    
    func setReadOnly(_ readOnly: Bool = false) {}
    func setDebugText(text: String) {}
    
    func setFailures(_ lines: [Int32]) {}
    
    func getBehaviorHelpForKey(_ key: String) -> String? { return nil }
    func getMapHelpForKey(_ key: String) -> String? { return nil }
}

#endif
