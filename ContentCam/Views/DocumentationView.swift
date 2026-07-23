import Foundation
import SwiftUI

struct DocumentationView: View {
    private let markdown: String

    init() {
        if let url = Bundle.main.url(forResource: "DOCUMENTATION", withExtension: "md"),
           let contents = try? String(contentsOf: url, encoding: .utf8) {
            markdown = contents
        } else {
            markdown = """
            # Documentation Unavailable

            ContentCam couldn’t load its bundled documentation.
            """
        }
    }

    var body: some View {
        ScrollView {
            MarkdownDocumentView(markdown: markdown)
                .padding(28)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .textSelection(.enabled)
        .frame(minWidth: 600, minHeight: 480)
    }
}
