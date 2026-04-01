/**
 * Sentinel Phase 8 — Central Orchestrator
 * sentinel_loader.js
 * 
 * Enforcing strict loading order: Cloak → Keychain → Camera.
 * Exposing RPC surface for tactical dashboard control.
 */

"use strict";

const { attachCloakHook, CloakConfig } = require("./hooks/ios/cloak_hook");
const { attachKeychainHook, KeychainHookConfig } = require("./hooks/ios/keychain_hook");
const { attachCameraHook, CameraHookConfig } = require("./hooks/ios/camera_hook");

function _boot() {
  console.log("[Sentinel] ── Phase 8 Universal Loader ──");

  // Phase 8.5 — Environment Cloaking (Must be first)
  attachCloakHook();

  // Phase 8.4 — Keychain & Biometrics
  attachKeychainHook();

  // Phase 8.3 — Universal Camera Injection
  attachCameraHook();

  console.log("[Sentinel] ── Tüm Taktiksel Modüller Aktif ──");
}

// Global Security Check
if (typeof ObjC !== 'undefined' && ObjC.available) {
  _boot();
} else if (typeof ObjC !== 'undefined') {
  ObjC.schedule(ObjC.mainQueue, _boot);
} else {
  console.log("[Sentinel] Fatal: Objective-C runtime not found.");
}

// Tactical RPC Exports
rpc.exports = {
  ping() { return "pong"; },
  getConfig() {
    return {
      cloak:    CloakConfig,
      keychain: KeychainHookConfig,
      camera:   CameraHookConfig,
    };
  }
};
