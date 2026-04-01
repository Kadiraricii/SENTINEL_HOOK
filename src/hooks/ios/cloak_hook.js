/**
 * Sentinel Phase 8 — Task 8.5.x
 * Advanced Environment Cloaking & Stealth Shield
 * 
 * Ensures any target app sees a clean, un-jailbroken iPhone 15 Pro on iOS 17.5.
 */

"use strict";

const CloakConfig = {
  spoofedModel:         "iPhone 15 Pro",
  spoofedSystemVersion: "17.5",
  spoofedName:          "iPhone",
  spoofedSystemName:    "iOS",
  spoofedIdentifierForVendor: "00000000-0000-0000-0000-000000000000",
  logBlockedPaths: true,
  jailbreakPaths: [
    "/Applications/Cydia.app", "/Applications/Sileo.app", "/Applications/Zebra.app",
    "/Library/MobileSubstrate/MobileSubstrate.dylib", "/usr/lib/libsubstitute.dylib",
    "/var/jb", "/usr/bin/sshd", "/etc/apt", "/var/lib/apt", "/private/var/lib/apt",
    "/usr/share/frida", "/usr/lib/frida", "/private/jailbreak.txt"
  ],
};

const _jbPathSet = new Set();
for (const p of CloakConfig.jailbreakPaths) {
  _jbPathSet.add(p);
  _jbPathSet.add(p + "/");
}

function _isJailbreakPath(path) {
  if (!path) return false;
  if (_jbPathSet.has(path)) return true;
  for (const jb of CloakConfig.jailbreakPaths) {
    if (path.startsWith(jb + "/")) return true;
  }
  return false;
}

function _hookUIDevice() {
  const UIDevice = ObjC.classes.UIDevice;
  if (!UIDevice) return;

  function patchGetter(sel, val) {
    const impl = UIDevice["- " + sel].implementation;
    Interceptor.attach(impl, {
      onLeave(retval) {
        retval.replace(ObjC.classes.NSString.stringWithUTF8String_(val));
      }
    });
  }

  patchGetter("model", CloakConfig.spoofedModel);
  patchGetter("systemVersion", CloakConfig.spoofedSystemVersion);
  patchGetter("name", CloakConfig.spoofedName);
  
  // identifierForVendor spoofing
  Interceptor.attach(UIDevice["- identifierForVendor"].implementation, {
    onLeave(retval) {
      const NSUUID = ObjC.classes.NSUUID;
      retval.replace(NSUUID.alloc().initWithUUIDString_(CloakConfig.spoofedIdentifierForVendor));
    }
  });
}

function _hookPosixDetection() {
  const stat64Addr = Module.findExportByName(null, "stat64") || Module.findExportByName(null, "stat");
  if (stat64Addr) {
    Interceptor.attach(stat64Addr, {
      onEnter(args) { this.path = args[0].readUtf8String(); },
      onLeave(retval) {
        if (this.path && _isJailbreakPath(this.path)) {
          if (CloakConfig.logBlockedPaths) console.log(`[Sentinel][Cloak] Blocked stat: ${this.path}`);
          retval.replace(ptr(-1));
        }
      }
    });
  }

  const sysctlAddr = Module.findExportByName(null, "sysctl");
  if (sysctlAddr) {
    const P_TRACED = 0x00000800; // Debugger flag
    Interceptor.attach(sysctlAddr, {
      onEnter(args) {
        this.oldp = args[2];
        this.isKernProc = (args[0].readS32() === 1 && args[1].readU32() === 4); 
      },
      onLeave(retval) {
        if (this.isKernProc && !this.oldp.isNull() && retval.toInt32() === 0) {
          const p_flag = this.oldp.add(32).readU32();
          if (p_flag & P_TRACED) {
            this.oldp.add(32).writeU32(p_flag & ~P_TRACED);
            console.log("[Sentinel][Cloak] Cleaned P_TRACED flag.");
          }
        }
      }
    });
  }
}

function attachCloakHook() {
  _hookUIDevice();
  _hookPosixDetection();
  console.log("[Sentinel][Cloak] Environment stealth fully armed.");
}

module.exports = { attachCloakHook, CloakConfig };
