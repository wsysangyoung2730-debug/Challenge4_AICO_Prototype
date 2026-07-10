import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "AICO 기록을 준비하고 있어요..."
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        processFirstSharedImage()
    }

    private func configureView() {
        view.backgroundColor = .systemBackground
        view.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func processFirstSharedImage() {
        guard let provider = firstImageProvider() else {
            finish()
            return
        }

        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let self else { return }
                guard let image = object as? UIImage,
                      let data = image.jpegData(compressionQuality: 0.82)
                else {
                    self.finish()
                    return
                }

                self.saveAndOpenApp(data)
            }
            return
        }

        provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
            guard let self else { return }
            guard let data else {
                self.finish()
                return
            }

            self.saveAndOpenApp(data)
        }
    }

    private func firstImageProvider() -> NSItemProvider? {
        let inputItems = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
        let providers = inputItems.flatMap { $0.attachments ?? [] }

        return providers.first {
            $0.canLoadObject(ofClass: UIImage.self) || $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
        }
    }

    private func saveAndOpenApp(_ data: Data) {
        guard let attachment = try? SharedPhotoAttachmentStore.saveImageData(data),
              let url = URL(string: "\(ShareExtensionConstants.appURLScheme)://\(ShareExtensionConstants.recordFromPhotoHost)?attachmentId=\(attachment.id)")
        else {
            finish()
            return
        }

        DispatchQueue.main.async {
            self.statusLabel.text = "AICO 앱으로 이동하고 있어요..."
            self.openContainingApp(with: url)
        }
    }

    private func openContainingApp(with url: URL) {
        extensionContext?.open(url) { [weak self] didOpen in
            guard let self else { return }

            if !didOpen {
                self.openURLThroughResponderChain(url)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.finish()
            }
        }
    }

    private func openURLThroughResponderChain(_ url: URL) {
        let selector = sel_registerName("openURL:")
        var responder: UIResponder? = self

        while let currentResponder = responder {
            if currentResponder.responds(to: selector) {
                _ = currentResponder.perform(selector, with: url)
                return
            }
            responder = currentResponder.next
        }
    }

    private func finish() {
        DispatchQueue.main.async {
            self.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
