<div align="center">

# 🤝 CONTRIBUTING

### Contributing to Sentinel Hook

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=for-the-badge&logo=github)](https://github.com/Kadiraricii/Sentinel_Hook/pulls)
[![Contributions](https://img.shields.io/badge/Contributions-Open-00C9FF?style=for-the-badge&logo=opensourceinitiative&logoColor=white)](https://github.com/Kadiraricii/Sentinel_Hook/issues)

</div>

---

## 📋 Before You Start

> [!IMPORTANT]
> Read `DISCLAIMER.md` before contributing and confirm you agree to the ethical guidelines.

1. Check if your contribution is related to an existing Issue.
2. If not, open a new Issue first and wait for approval before starting development.

---

## 🔀 Branch Strategy

```
main              →  Stable, production-ready branch
dev               →  Active development (open PRs here)
feature/<name>    →  New feature development
fix/<name>        →  Bug fix branches
```

```bash
# 1. Fork and clone the repo
git clone https://github.com/<you>/Sentinel_Hook.git
cd Sentinel_Hook

# 2. Create a new branch
git checkout -b feature/new-bypass-module

# 3. Develop and commit
git add .
git commit -m "feat(hooks): android SafetyNet bypass added"

# 4. Push and open a PR
git push origin feature/new-bypass-module
```

---

## 📝 Commit Message Format

This project follows [Conventional Commits](https://www.conventionalcommits.org/):

| Type | Usage |
|:-----|:------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation change |
| `refactor` | Code restructuring |
| `test` | Adding / updating tests |
| `chore` | Dependency / build updates |

**Examples:**
```
feat(ios): fake VNFaceObservation injection added
fix(android): TrustManager null pointer crash resolved
docs(readme): installation steps updated
```

---

## 🧪 Code Quality Standards

> [!TIP]
> Make sure any new bypass module meets all of the following criteria.

- **JS Hooks:** Every script must announce itself via `console.log` and wrap logic in `try/catch`.
- **Swift/Java:** Methods targeted for hooking must be `@objc dynamic` or `public`.
- **Testing:** Any new bypass must be tested on `DummyBank` and terminal output must be included in the PR description.

---

## 🚫 Rejected Contributions

> [!CAUTION]
> The following PR types will be closed immediately:

- Specific exploit code targeting real banking / fintech applications
- Any module that collects or exfiltrates user data
- Changes that remove or weaken the license and disclaimer notices
