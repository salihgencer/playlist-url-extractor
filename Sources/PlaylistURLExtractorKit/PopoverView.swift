import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Menü çubuğu popover'ının ana görünümü.
public struct PopoverView: View {
    @ObservedObject var viewModel: ExtractorViewModel
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    public static let size = NSSize(width: 400, height: 540)

    public init(viewModel: ExtractorViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            inputRow
            extractButton
            statusRow
            results
            footer
        }
        .padding(16)
        .frame(width: Self.size.width, height: Self.size.height, alignment: .top)
        .tint(Brand.accent)
    }

    // MARK: - Bölümler

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: Brand.menuBarSymbol)
                .font(.title3)
                .foregroundStyle(Brand.accent)
            Text(verbatim: "Playlist URL Extractor")
                .font(.headline)
            Spacer()
            settingsMenu
        }
    }

    private var settingsMenu: some View {
        Menu {
            Toggle(isOn: Binding(
                get: { launchAtLogin },
                set: { newValue in
                    LaunchAtLogin.setEnabled(newValue)
                    launchAtLogin = LaunchAtLogin.isEnabled
                }
            )) {
                Text("Launch at Login", bundle: .module)
            }
            Divider()
            Button { NSWorkspace.shared.open(ExternalLinks.privacyPolicy) } label: {
                Text("Privacy Policy", bundle: .module)
            }
            Button { NSWorkspace.shared.open(ExternalLinks.support) } label: {
                Text("Support", bundle: .module)
            }
            Button { NSWorkspace.shared.open(ExternalLinks.youTubeTerms) } label: {
                Text("YouTube Terms of Service", bundle: .module)
            }
            Button { NSWorkspace.shared.open(ExternalLinks.googlePrivacy) } label: {
                Text("Google Privacy Policy", bundle: .module)
            }
            Divider()
            Button { NSApp.terminate(nil) } label: {
                Text("Quit Playlist URL Extractor", bundle: .module)
            }
        } label: {
            Image(systemName: "gearshape")
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help(Text("Settings", bundle: .module))
    }

    private var inputRow: some View {
        HStack(spacing: 6) {
            TextField(text: $viewModel.inputText) {
                Text("Playlist link or ID", bundle: .module)
            }
            .textFieldStyle(.roundedBorder)
            .onSubmit { viewModel.extract() }

            Button(action: viewModel.pasteFromClipboard) {
                Image(systemName: "doc.on.clipboard")
            }
            .help(Text("Paste from Clipboard", bundle: .module))
        }
    }

    private var extractButton: some View {
        Button {
            viewModel.isLoading ? viewModel.cancel() : viewModel.extract()
        } label: {
            HStack(spacing: 6) {
                if viewModel.isLoading {
                    ProgressView().controlSize(.small)
                    Text("Cancel", bundle: .module)
                } else {
                    Image(systemName: "link")
                    Text("Extract Links", bundle: .module)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .keyboardShortcut(.defaultAction)
    }

    @ViewBuilder
    private var statusRow: some View {
        if !viewModel.statusMessage.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: viewModel.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(viewModel.isError ? Color.orange : Color.green)
                    .opacity(viewModel.isLoading ? 0 : 1)
                Text(viewModel.statusMessage)
                    .font(.callout)
                    .foregroundStyle(viewModel.isError ? Color.primary : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var results: some View {
        if viewModel.videos.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 8) {
                if let title = viewModel.playlist?.title {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                List(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(verbatim: "\(index + 1).")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(minWidth: 22, alignment: .trailing)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(video.title).lineLimit(1)
                            Text(video.watchURL)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.bordered(alternatesRowBackgrounds: true))

                HStack {
                    Button(action: viewModel.copyAll) {
                        Label { Text("Copy All", bundle: .module) } icon: { Image(systemName: "doc.on.doc") }
                    }
                    Button(action: saveToFile) {
                        Label { Text("Save as Text File…", bundle: .module) } icon: { Image(systemName: "square.and.arrow.down") }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.tertiary)
            Text("Paste a public playlist link to list every video link in it.", bundle: .module)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        Text("Uses YouTube API Services. Not affiliated with YouTube or Google.", bundle: .module)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func saveToFile() {
        guard !viewModel.videos.isEmpty else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = viewModel.suggestedFileName
        guard panel.runModal() == .OK, let url = panel.url else { return }
        viewModel.save(to: url)
    }
}

/// Ana eylem düğmesi: pencere etkin olmasa da marka renginde kalır.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(colors: [Brand.accent, Brand.accentSecondary],
                                         startPoint: .leading, endPoint: .trailing))
            )
            .opacity(configuration.isPressed ? 0.8 : (isEnabled ? 1 : 0.5))
            .contentShape(Rectangle())
    }
}
