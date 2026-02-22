import SwiftUI
import UniformTypeIdentifiers

/// Menu bar popover'ının ana SwiftUI görünümü.
public struct PopoverView: View {
    @ObservedObject var viewModel: ExtractorViewModel
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    public init(viewModel: ExtractorViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Başlık satırı
            headerSection

            Divider()

            // URL giriş alanı
            inputSection

            // Çıkar butonu
            extractButton

            // Durum mesajı
            statusSection

            // Sonuç listesi
            if !viewModel.videoURLs.isEmpty {
                resultSection
            }

            Spacer(minLength: 0)
        }
        .padding()
        .frame(width: 380, height: 480)
    }

    // MARK: - Alt bileşenler

    private var headerSection: some View {
        HStack {
            Image(systemName: "play.rectangle.fill")
                .foregroundStyle(.red)
            Text("YouTube URL Extractor")
                .font(.headline)
            Spacer()
            Menu {
                Toggle("Giriş'te Başlat", isOn: Binding(
                    get: { launchAtLogin },
                    set: { newValue in
                        launchAtLogin = newValue
                        LaunchAtLogin.setEnabled(newValue)
                    }
                ))
                Divider()
                Button("Çıkış") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    private var inputSection: some View {
        HStack {
            TextField("YouTube Playlist URL'si...", text: $viewModel.urlText)
                .textFieldStyle(.roundedBorder)
                .onSubmit { viewModel.extract() }

            Button(action: viewModel.pasteFromClipboard) {
                Image(systemName: "doc.on.clipboard")
            }
            .help("Panodan Al")
        }
    }

    private var extractButton: some View {
        Button(action: viewModel.extract) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(viewModel.isLoading ? "Çıkarılıyor..." : "Çıkar")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isLoading)
        .tint(.red)
    }

    @ViewBuilder
    private var statusSection: some View {
        if !viewModel.statusMessage.isEmpty {
            Text(viewModel.statusMessage)
                .font(.caption)
                .foregroundStyle(viewModel.isError ? .red : .green)
        }
    }

    private var resultSection: some View {
        VStack(spacing: 8) {
            List(viewModel.videoURLs.indices, id: \.self) { index in
                HStack {
                    Text("\(index + 1).")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Text(viewModel.videoURLs[index])
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                }
            }
            .listStyle(.plain)

            // Alt butonlar
            HStack {
                Button(action: viewModel.copyAll) {
                    Label("Tümünü Kopyala", systemImage: "doc.on.doc")
                }

                Button(action: saveToFile) {
                    Label("Dosyaya Kaydet", systemImage: "square.and.arrow.down")
                }
            }
        }
    }

    private func saveToFile() {
        guard !viewModel.videoURLs.isEmpty else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "youtube-urls.txt"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let content = viewModel.videoURLs.joined(separator: "\n") + "\n"
            try content.write(to: url, atomically: true, encoding: .utf8)
            viewModel.statusMessage = "Dosya başarıyla kaydedildi"
            viewModel.isError = false
        } catch {
            viewModel.statusMessage = "Dosya kaydedilemedi"
            viewModel.isError = true
        }
    }
}
