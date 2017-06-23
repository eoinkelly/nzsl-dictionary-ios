//
//  ImageUtil.swift
//  NZSLDict
//
//  Created by Eoin Kelly on 10/06/17.
//
//

import UIKit

class ImageHelper {

    /**
     This helper takes an image and builds a copy of it where the white pixels are 
     replaced with transparent pixels.an
     
     - parameter src: The UIImage you wish to convert
     - returns: A new instance of a UIImage
    */
    static func cloneWithWhiteAsTransparent(_ src: UIImage) -> UIImage {
        let srcWidthInt = Int(src.size.width)
        let srcHeightInt = Int(src.size.height)
        let numPixelsInSrcImage = srcWidthInt * srcHeightInt
        let numBytesToAllocate = numPixelsInSrcImage * 4 // 4 bytes per pixel: R,G,B,Alpha

        // Allocate memory for the new image data
        let rawBytesPtr = allocateMemory(numBytes: numBytesToAllocate)

        // Create a bitmap-based graphics context and makes it the current context
        UIGraphicsBeginImageContext(src.size)

        // Create a CGContext which will use the block of bytes we allocated earlier
        // as memory. This will give us two ways of working with that memory:
        //
        // 1. As a CGContext via `bitcontext`
        // 2. As a collection of raw bytes via `rawBytesPtr`
        //
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let bitcontext = CGContext(data: rawBytesPtr, width: srcWidthInt, height: srcHeightInt, bitsPerComponent: 8,
                                         bytesPerRow: srcWidthInt * 4, space: colorSpace, bitmapInfo: bitmapInfo) else {
            cleanupMemory(ptr: rawBytesPtr, numBytes: numBytesToAllocate)
            return src // TODO: clone the image
        }

        // Draw the original image data into our memory area using our "CGContext interface"
        bitcontext.draw(src.cgImage!,
                        in: CGRect(x: CGFloat(0), y: CGFloat(0), width: src.size.width, height: src.size.height))

        // Manipulate the bytes in our memory area using our "raw interface"
        for i in 0..<numPixelsInSrcImage {
            let c: UInt8 = rawBytesPtr[4 * i]
            rawBytesPtr[4 * i] = 0
            rawBytesPtr[4 * i + 1] = 0
            rawBytesPtr[4 * i + 2] = 0
            rawBytesPtr[4 * i + 3] = 0xff - c
        }

        // makeImage() creates and returns a CGImage from the pixel data in a 
        // bitmap graphics context which we then wrap in an UIImage
        let resultImg = UIImage(cgImage: bitcontext.makeImage()!)

        cleanupMemory(ptr: rawBytesPtr, numBytes: numBytesToAllocate)

        // Removes the current bitmap-based graphics context from the top of the stack
        UIGraphicsEndImageContext()

        return resultImg
    }

    // MARK: Private helper methods

    static private func allocateMemory(numBytes: Int) -> UnsafeMutablePointer<UInt8> {
        // Allocate the memory
        let bytesPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: numBytes)

        // Initialize it memory to 0x00
        let buffer = UnsafeMutableBufferPointer(start: bytesPtr, count: numBytes)
        for (i, _) in buffer.enumerated() {
            buffer[i] = 0
        }

        return bytesPtr
    }

    static private func cleanupMemory(ptr: UnsafeMutablePointer<UInt8>, numBytes: Int) {
        ptr.deinitialize()
        ptr.deallocate(capacity: numBytes)
    }
}
