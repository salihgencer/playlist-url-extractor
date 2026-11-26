// Uygulama ikonunu (1024x1024, macOS ikon şablonu) çizer ve AppIcon setini üretir.
//   swift scripts/make_icon.swift
// Tasarım: lacivert → camgöbeği zemin, üzerinde liste satırlı beyaz kâğıt ve zincir (bağlantı) rozeti.
// SF Symbols kullanılmaz (lisans ikon kullanımına izin vermez); tüm şekiller elle çizilir.
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

// 1) Gövde: 824x824, 100 px kenar boşluğu, köşe yarıçapı ~185 (Apple macOS şablonu).
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let bodyPath = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: rgb(0, 0, 0, 0.30))
ctx.addPath(bodyPath); ctx.setFillColor(rgb(0.1, 0.2, 0.5)); ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(bodyPath); ctx.clip()
let bg = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [
    rgb(0.10, 0.17, 0.45), rgb(0.13, 0.38, 0.78), rgb(0.11, 0.66, 0.72),
] as CFArray, locations: [0, 0.55, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 160, y: 924), end: CGPoint(x: 864, y: 100), options: [])
// Üstten yumuşak parlaklık
let gloss = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                       colors: [rgb(1, 1, 1, 0.18), rgb(1, 1, 1, 0)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gloss, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 560), options: [])
ctx.restoreGState()

// 2) Liste kâğıdı
let sheet = CGRect(x: 238, y: 250, width: 470, height: 560)
let sheetPath = CGPath(roundedRect: sheet, cornerWidth: 56, cornerHeight: 56, transform: nil)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 36, color: rgb(0.02, 0.08, 0.25, 0.45))
ctx.addPath(sheetPath); ctx.setFillColor(rgb(0.98, 0.99, 1.0)); ctx.fillPath()
ctx.restoreGState()

let rowColor = rgb(0.13, 0.36, 0.78)
let barColor = rgb(0.72, 0.80, 0.92)
for (i, length) in [CGFloat(250), 210, 230, 160].enumerated() {
    let y = sheet.maxY - 110 - CGFloat(i) * 118
    ctx.setFillColor(rowColor)
    ctx.fillEllipse(in: CGRect(x: sheet.minX + 60, y: y - 22, width: 44, height: 44))
    let bar = CGRect(x: sheet.minX + 136, y: y - 17, width: length, height: 34)
    ctx.addPath(CGPath(roundedRect: bar, cornerWidth: 17, cornerHeight: 17, transform: nil))
    ctx.setFillColor(barColor); ctx.fillPath()
}

// 3) Bağlantı rozeti (sağ alt)
let badgeCenter = CGPoint(x: 712, y: 318)
let badgeRadius: CGFloat = 150
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 30, color: rgb(0.02, 0.08, 0.25, 0.45))
ctx.setFillColor(rgb(0.07, 0.56, 0.64))
ctx.fillEllipse(in: CGRect(x: badgeCenter.x - badgeRadius, y: badgeCenter.y - badgeRadius,
                           width: badgeRadius * 2, height: badgeRadius * 2))
ctx.restoreGState()
ctx.setStrokeColor(rgb(1, 1, 1, 0.9)); ctx.setLineWidth(10)
ctx.strokeEllipse(in: CGRect(x: badgeCenter.x - badgeRadius + 5, y: badgeCenter.y - badgeRadius + 5,
                             width: badgeRadius * 2 - 10, height: badgeRadius * 2 - 10))

// Zincir: -45° döndürülmüş iki iç içe geçmiş yuvarlak dikdörtgen halka.
ctx.saveGState()
ctx.translateBy(x: badgeCenter.x, y: badgeCenter.y)
ctx.rotate(by: .pi / 4)
ctx.setStrokeColor(rgb(1, 1, 1)); ctx.setLineWidth(30); ctx.setLineCap(.round)
let link = CGSize(width: 150, height: 84)
for dx in [CGFloat(-50), 50] {
    let r = CGRect(x: dx - link.width / 2, y: -link.height / 2, width: link.width, height: link.height)
    ctx.addPath(CGPath(roundedRect: r, cornerWidth: 42, cornerHeight: 42, transform: nil))
    ctx.strokePath()
}
ctx.restoreGState()

let image = ctx.makeImage()!

func write(_ image: CGImage, _ url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    precondition(CGImageDestinationFinalize(dest))
}

func resized(_ image: CGImage, _ px: Int) -> CGImage {
    let c = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.interpolationQuality = .high
    c.draw(image, in: CGRect(x: 0, y: 0, width: px, height: px))
    return c.makeImage()!
}

let source = root.appendingPathComponent("docs/appstore/icon-1024.png")
try FileManager.default.createDirectory(at: source.deletingLastPathComponent(), withIntermediateDirectories: true)
write(image, source)

let set = root.appendingPathComponent("App/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: set, withIntermediateDirectories: true)
var images: [[String: String]] = []
for pt in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(pt)x\(pt)\(scale == 2 ? "@2x" : "").png"
        write(resized(image, pt * scale), set.appendingPathComponent(name))
        images.append(["idiom": "mac", "size": "\(pt)x\(pt)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: set.appendingPathComponent("Contents.json"))
try Data(#"{"info":{"author":"xcode","version":1}}"#.utf8)
    .write(to: root.appendingPathComponent("App/Assets.xcassets/Contents.json"))
print("ikon yazıldı: \(source.path)")
