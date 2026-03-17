# 🔒 Security Policy

## Supported Versions

| Version | Support Status |
|:--------|:--------------|
| 1.0.x   | ✅ Actively supported |
| < 1.0   | ❌ No support |

---

## 🐛 Reporting a Vulnerability

If you discover a security vulnerability **within Sentinel Hook's own infrastructure** (e.g., a script that unintentionally accesses systems beyond its intended scope, a Python-layer RCE risk, etc.), please **do not** open a public Issue.

Instead:
1. Document the vulnerability in detail (include a PoC if available).
2. Report it via **GitHub Private Vulnerability Reporting** on this repository.
3. You will receive a response within **72 hours**.

Thank you for practicing responsible disclosure.

---

## ⚠️ Out of Scope

The following are **not** covered by this security policy:
- Reporting the bypass mechanisms themselves as "vulnerabilities" — they are the intended functionality of this research tool.
- Vulnerabilities in third-party dependencies (Frida, mitmproxy, etc.) — report those to the respective upstream projects.
