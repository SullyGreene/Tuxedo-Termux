# Tuxedo-Termux TODO List

This document outlines potential improvements, new features, and bug fixes for the Tuxedo-Termux project.

## High Priority

- [ ] **Implement `tux remove <package-name>` command:** Allow users to uninstall packages previously installed via `tux`. This would require a mechanism to track installed packages and their uninstallation scripts.
- [x] **Improve `pkg` command error handling:** Currently, `pkg update` and `pkg install` output is redirected to `/dev/null`. Enhance error detection and reporting for these commands.
- [x] **Add `tux self-update` command:** Provide a way for users to update the `tux` client script itself to the latest version without re-running `install.sh`.
- [ ] **More robust network error handling:** Improve how `git clone`, `git pull`, and `curl` handle network connectivity issues or timeouts.

## Medium Priority

- [ ] **`tux show <package-name>` command:** Display detailed information about a specific package (description, dependencies, URL, checksum, etc.).
- [ ] **Centralize and improve logging:** Consider a more structured logging approach, perhaps with different verbosity levels.
- [ ] **Refactor `jq` queries:** Some `jq` commands are repeated or could be made more efficient/readable.
- [ ] **Add `set -euo pipefail`:** Apply `set -euo pipefail` to both `install.sh` and the generated `tux` script for stricter error handling.

## Low Priority / Future Enhancements

- [ ] **GPG signature verification:** Explore adding GPG signature verification for installer scripts and the package database for enhanced security.
- [ ] **Interactive dependency installation:** Offer an interactive prompt before installing Termux dependencies, especially if there are many.
- [ ] **Caching for `tux update`:** Implement a simple caching mechanism to speed up `tux update` if the repository hasn't changed.
- [ ] **Support for multiple repositories:** Allow users to add and manage multiple package repositories.