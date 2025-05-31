//
//  AboutView.swift
//  Scaffold
//
//  Created by Bryan Veloso on 5/31/25.
//

import SwiftUI

struct AboutView: View {
    private let githubURL = URL(string: "https://github.com/omnypro/scaffold")

    private var build: String? {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }
    private var commit: String? {
        Bundle.main.infoDictionary?["ScaffoldCommit"] as? String
    }
    private var version: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    private var copyright: String? {
        Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String
    }

    private struct VisualEffectBackground: NSViewRepresentable {
        let material: NSVisualEffectView.Material
        let blendingMode: NSVisualEffectView.BlendingMode
        let isEmphasized: Bool

        init(
            material: NSVisualEffectView.Material,
            blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
            isEmphasized: Bool = false
        ) {
            self.material = material
            self.blendingMode = blendingMode
            self.isEmphasized = isEmphasized
        }

        func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
            nsView.material = material
            nsView.blendingMode = blendingMode
            nsView.isEmphasized = isEmphasized
        }

        func makeNSView(context: Context) -> NSVisualEffectView {
            let visualEffect = NSVisualEffectView()
            visualEffect.autoresizingMask = [.width, .height]
            return visualEffect
        }
    }

    var body: some View {
        VStack(alignment: .center) {
            Image(nsImage: NSApp.applicationIconImage).resizable().aspectRatio(
                contentMode: .fit
            ).frame(height: 128)

            VStack(alignment: .center, spacing: 32) {
                VStack(alignment: .center, spacing: 8) {
                    Text("Scaffold").bold().font(.title)
                    Text("A rigid canvas for your ideas.").font(.caption).tint(
                        .secondary
                    ).opacity(0.8)
                }

                VStack(spacing: 2) {
                    if let version {
                        PropertyRow(label: "Version", text: version)
                    }
                    if let build {
                        PropertyRow(label: "Build", text: build)
                    }
                    if let commit, commit != "",
                        let url = githubURL?.appendingPathComponent(
                            "/commits/\(commit)"
                        )
                    {
                        PropertyRow(label: "Commit", text: commit, url: url)
                    }
                }
                .frame(maxWidth: .infinity)

                if let copy = self.copyright {
                    Text(copy)
                        .font(.caption)
                        .textSelection(.enabled)
                        .tint(.secondary)
                        .opacity(0.8)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
        .padding(32)
        .frame(width: 256)
        .background(
            VisualEffectBackground(material: .underWindowBackground)
                .ignoresSafeArea()
        )
    }

    private struct PropertyRow: View {
        private let label: String
        private let text: String
        private let url: URL?

        init(label: String, text: String, url: URL? = nil) {
            self.label = label
            self.text = text
            self.url = url
        }

        @ViewBuilder private var textView: some View {
            Text(text).frame(width: 125, alignment: .leading).padding(
                .leading,
                2
            ).tint(.secondary).opacity(0.8).monospaced()
        }

        var body: some View {
            HStack(spacing: 4) {
                Text(label)
                    .frame(width: 126, alignment: .trailing)
                    .padding(.trailing, 2)
                if let url {
                    Link(destination: url) {
                        textView
                    }
                } else {
                    textView
                }
            }
            .font(.callout)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity)
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
