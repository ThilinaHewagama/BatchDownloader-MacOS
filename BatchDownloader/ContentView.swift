import SwiftUI

struct ContentView: View {
    @State private var linksText: String = ""
    @State private var linksCount: Int = 0
    @State private var currentStatus: String = ""
    @State private var isDownloading: Bool = false
    
    var body: some View {
        VStack {
            if !linksText.isEmpty {
                Text("Links Found: \(linksCount)").font(.largeTitle)
            } else {
                Text("")
            }
            
            TextEditor(text: $linksText)
                .frame(height: 250)
                .border(Color.gray, width: 1)
                .padding()
                .onChange(of: linksText) {
                    linksCount = linksText.split(separator: "\n").filter { !$0.isEmpty }.count
                }
            
            if !currentStatus.isEmpty {
                Text("\(currentStatus)").font(.caption)
            }
            
            Button("Download Links") {
                downloadImages(from: linksText)
            }
            .padding()
            .disabled(isDownloading)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func downloadImages(from links: String) {
        let urls = links.split(separator: "\n").compactMap { URL(string: String($0)) }
        
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.prompt = "Select Download Folder"
            panel.canChooseDirectories = true
            panel.canCreateDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false
            panel.message = "Select a folder to save the downloaded images"
            
            if panel.runModal() == .OK, let selectedFolder = panel.url {
                isDownloading = true
                downloadNextImage(urls: urls, to: selectedFolder)
            }
        }
    }
    
    private func downloadNextImage(urls: [URL], to folderURL: URL, index: Int = 0) {
        guard index < urls.count else {
            currentStatus = "Download completed"
            isDownloading = false
            return
        }
        
        let url = urls[index]
        currentStatus = "Downloading: \(url.lastPathComponent)"
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("Error downloading file: \(error?.localizedDescription ?? "Unknown error")")
                    downloadNextImage(urls: urls, to: folderURL, index: index + 1) // Continue with next even if error
                    return
                }
                
                var fileURL = folderURL.appendingPathComponent(url.lastPathComponent)
                ensureUniqueFilename(&fileURL)
                
                do {
                    try data.write(to: fileURL)
                    print("Downloaded: \(fileURL.lastPathComponent)")
                } catch {
                    print("Error saving file: \(error)")
                }
                
                downloadNextImage(urls: urls, to: folderURL, index: index + 1) // Download next image
            }
        }.resume()
    }
    
    private func ensureUniqueFilename(_ fileURL: inout URL) {
        let fileManager = FileManager.default
        var newURL = fileURL
        var nameCount = 1
        
        while fileManager.fileExists(atPath: newURL.path) {
            let fileName = newURL.deletingPathExtension().lastPathComponent
            let fileExtension = newURL.pathExtension
            let newName = "\(fileName)_\(nameCount).\(fileExtension)"
            newURL = newURL.deletingLastPathComponent().appendingPathComponent(newName)
            nameCount += 1
        }
        
        fileURL = newURL
    }
}
