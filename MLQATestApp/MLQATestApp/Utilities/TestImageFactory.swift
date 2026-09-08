import UIKit
import CoreImage

enum TestImageFactory {
    static func syntheticScene(size: CGSize = CGSize(width: 400, height: 400)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let context = ctx.cgContext

            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor] as CFArray,
                locations: [0, 1]
            )!
            context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])

            context.setFillColor(UIColor.red.cgColor)
            context.fill(CGRect(x: 50, y: 50, width: 120, height: 80))

            context.setFillColor(UIColor.green.cgColor)
            context.fillEllipse(in: CGRect(x: 220, y: 60, width: 100, height: 100))

            context.setFillColor(UIColor.yellow.cgColor)
            let trianglePath = CGMutablePath()
            trianglePath.move(to: CGPoint(x: 200, y: 300))
            trianglePath.addLine(to: CGPoint(x: 150, y: 380))
            trianglePath.addLine(to: CGPoint(x: 250, y: 380))
            trianglePath.closeSubpath()
            context.addPath(trianglePath)
            context.fillPath()

            let text = "MLQATestApp" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: UIColor.white
            ]
            text.draw(at: CGPoint(x: 80, y: 200), withAttributes: attributes)

            let smallText = "Vision Test Image" as NSString
            let smallAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.white
            ]
            smallText.draw(at: CGPoint(x: 100, y: 240), withAttributes: smallAttrs)
        }
    }

    static func textImage(_ text: String, size: CGSize = CGSize(width: 400, height: 200)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let nsText = text as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            nsText.draw(at: CGPoint(x: 20, y: 20), withAttributes: attributes)
        }
    }

    static func blankImage(size: CGSize = CGSize(width: 400, height: 400)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    static func rectangleImage(size: CGSize = CGSize(width: 400, height: 400)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let context = ctx.cgContext
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(3)
            context.stroke(CGRect(x: 50, y: 50, width: 150, height: 100))
            context.stroke(CGRect(x: 220, y: 200, width: 130, height: 150))
            context.stroke(CGRect(x: 100, y: 250, width: 80, height: 80))
        }
    }

    static func noisyVersion(of image: UIImage, intensity: Double = 0.3) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()

        guard let noiseGenerator = CIFilter(name: "CIRandomGenerator"),
              let blendFilter = CIFilter(name: "CISourceOverCompositing") else { return image }

        noiseGenerator.setValue(nil, forKey: kCIInputImageKey)
        guard let noiseImage = noiseGenerator.outputImage?.cropped(to: ciImage.extent) else { return image }

        let colorMatrix = CIFilter(name: "CIColorMatrix")!
        let vector = CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity))
        colorMatrix.setValue(noiseImage, forKey: kCIInputImageKey)
        colorMatrix.setValue(vector, forKey: "inputAVector")
        colorMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        colorMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")

        guard let tintedNoise = colorMatrix.outputImage else { return image }

        blendFilter.setValue(tintedNoise, forKey: kCIInputImageKey)
        blendFilter.setValue(ciImage, forKey: kCIInputBackgroundImageKey)

        guard let output = blendFilter.outputImage,
              let cgResult = context.createCGImage(output, from: ciImage.extent) else { return image }

        return UIImage(cgImage: cgResult)
    }

    static func blurredVersion(of image: UIImage, radius: Double = 10) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()

        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)

        guard let output = filter.outputImage,
              let cgResult = context.createCGImage(output, from: ciImage.extent) else { return image }

        return UIImage(cgImage: cgResult)
    }
}
