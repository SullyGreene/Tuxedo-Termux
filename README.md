# Tuxedo-Termux

Your command-line gateway to a curated marketplace of powerful tools for **rooted** Android devices, all managed within Termux.

## 📖 Overview

Tuxedo-Termux is a lightweight, command-line package manager designed to simplify the discovery and installation of scripts and applications that require root access. It operates independently of the official Termux repositories, sourcing its package information from the community-driven [Tuxedo-Repo](https://github.com/SullyGreene/Tuxedo-Repo).

This tool is for power users, developers, and security enthusiasts who want to unlock the full potential of their rooted devices directly from the Termux terminal.

## ✨ Features

  - **Discover:** Search for new tools and scripts specifically designed for rooted environments.
  - **One-Command Install:** Install complex tools with a single, simple command (`tux install <package>`).
  - **Community-Driven:** All package definitions are stored in a public GitHub repository, making it easy for anyone to contribute.
  - **Secure by Design:** Installers are verified using SHA256 checksums to ensure the script you download is the one intended by the package maintainer.
  - **Lightweight:** A simple set of shell scripts that are fast and have minimal dependencies.

## ⚠️ Prerequisites

1.  **Termux:** A working installation of the Termux app.
2.  **Root Access:** Your Android device **must be rooted**, and the `su` binary must be accessible from your Termux session.
3.  **Dependencies:** `git` and `jq` are required. The installer will attempt to install them for you.

## 🚀 Installation

To install Tuxedo-Termux, paste the following command into your Termux terminal:

```bash
pkg install -y curl && curl -sL https://raw.githubusercontent.com/SullyGreene/Tuxedo-Termux/main/install.sh | bash
```

After the installation is complete, you **must restart Termux** or run `source ~/.bashrc` for the `tux` command and its aliases to become available.

## 💻 Usage

The main command is `tux`. You can also use the aliases `tuxedo` or `tux-market`.

#### 1\. Update the Package List

Before first use, and periodically after, you should sync your local package list with the remote repository.

```bash
tux update
```

#### 2\. Search for a Package

Find packages by name or keyword.

```bash
tux search <keyword>
```

*Example:* `tux search wifi`

#### 3\. List All Available Packages

To see a full list of all packages available in the marketplace:

```bash
tux list
```

#### 4\. Install a Package

This command will download the package's installation script, verify its integrity, and execute it with root permissions.

```bash
tux install <package-name>
```

*Example:* `tux install SuperSU-Manager`

## 🤝 How to Contribute

The power of Tuxedo comes from its community\!

To add a new application to the marketplace, please **submit a pull request** to the `Tuxedo-Repo` repository, not this one. Contributions should follow the JSON schema and contribution guidelines outlined there.

➡️ **[Contribute a Package to Tuxedo-Repo](https://github.com/SullyGreene/Tuxedo-Repo)**

## ❗ Disclaimer

**Use this software at your own risk.** The packages installed by Tuxedo-Termux are granted root access and can modify critical system files. While we aim for a secure and reliable experience by using checksums, the responsibility for vetting and running software on your device is ultimately yours. The maintainers of Tuxedo-Termux are not responsible for any damage, data loss, or "bricked" devices.

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.
