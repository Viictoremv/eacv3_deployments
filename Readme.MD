# Early Access System v3 - Deployments

This repository contains all deployment-related configuration and tooling for the Early Access System (EAS) v3 project.

Ben updated this file

It includes:

- **Docker Compose** configuration for local development
- **NGINX reverse proxy** setup for routing Parent and Child apps
- **Helm charts** for AKS and production deployments (coming soon)
- **Setup scripts** (PowerShell/Bash) to automate environment prep

---

## 🔧 Local Developer Setup (Docker Desktop)

This section helps developers set up both **Parent** and **Child** apps with separate MySQL containers and a shared NGINX reverse proxy — all running locally via Docker Compose.

---

### 🧱 Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop) (macOS, Windows WSL2)
- [Git](https://git-scm.com/) and [GitHub Desktop](https://desktop.github.com/download/)
- Clone the following three repositories:

```sh
git clone https://github.com/Early-Access-Care-LLC/easv3.git
git clone https://github.com/Early-Access-Care-LLC/easv3_parent.git
git clone https://github.com/Early-Access-Care-LLC/easv3-deployments.git
```

### 🗂️ Folder Structure

Ensure the folders are organized like this:

```sh
your-dev-folder/
├── easv3/              # Child app
├── easv3_parent/       # Parent app
└── easv3-deployments/  # This repo
```

### 🔌 DNS Routing for Local Access

Update your system's hosts file:

Windows
Edit C:\Windows\System32\drivers\etc\hosts as Administrator

macOS / Linux
Edit /etc/hosts using sudo

Add:

```sh
127.0.0.1 parent.earlyaccesscare.local
127.0.0.1 child.earlyaccesscare.local
127.0.0.1 phpmyadmin.earlyaccesscare.local
```

### 🚀 Run the Full Stack Locally

#### First Time Setup for ENV and Database Files

Run these commands from the root of the easv3_deployments directory.

```sh
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

```sh
.\setup\init-windows.ps1
```

## Instantiate development volumes

- In order to avoid you accidently losing your code changes between container rebuilds we are building long lived volumes where your Git History will live.
- Before running Docker Compose Up the first time you need to run the following command:

```sh
docker volume create easv3_code
docker volume create easv3parent_code
```

Once created, you do not need to recreate them unless you intentiionally remove them using:

```sh
docker volume rm easv3_code easv3parent_code
```

From the easv3-deployments folder:

```sh
docker compose up --build -d
```

### Docker will launch:

- parent-web: Symfony Parent app
- child-web: Symfony Child app
- parent-db: MySQL for Parent
- child-db: MySQL for Child
- nginx: Routes requests to the right app
- dev_coder: Local Coder Container to speed up Local Development

## 🖥️ Connecting to the Dev Container via VS Code (Remote SSH)

This guide will walk you through configuring your local system to connect to the easv3_dev_coder container using VS Code's Remote - SSH extension.

### ✅ Purpose

You’ll connect to your local development container running inside Docker (dev_coder) using SSH and open the /workspace directory in VS Code as if it were a local project. This enables code editing, debugging, and extension usage directly inside the container.

### 🔧 Prerequisites

| Requirement         | Windows                              | macOS / Linux                          |
|---------------------|---------------------------------------|----------------------------------------|
| VS Code             | Installed from [here](https://code.visualstudio.com) | Installed from [here](https://code.visualstudio.com) |
| Remote - SSH Extension | Install via VS Code Marketplace     | Install via VS Code Marketplace         |
| OpenSSH Client      | Comes with Windows 10+                | Built-in on macOS                      |
| Docker Desktop      | Installed + running container         | Installed + running container          |
| Port Forwarding     | Handled in docker-compose (port 2222) | Handled in docker-compose (port 2222)  |

### 💻 Open VS Code via SSH

With the Remote - SSH extension installed, run: (When you run this it will prompt you for the password which is "dev")

```sh
code --remote ssh-remote+dev@localhost:2222 /workspace
```

#### Or manually:

1. Open VS Code
2. Press F1 or Ctrl+Shift+P (Cmd+Shift+P on Mac)
3. Type: Remote-SSH: Connect to Host...
4. Choose easv3-dev
5. Then select the /workspace folder when prompted

---

## ▶️ Run first-time-setup.sh (Required After Connecting via SSH)

Once you are connected to the dev container through VS Code Remote SSH, you must run the initial setup script to populate the development volumes with the application code and install dependencies (explanation below).

Inside the container terminal in VS Code, run:

```sh
./first-time-setup.sh
```

This step is required the first time you set up the environment or whenever the easv3_code or easv3parent_code volumes have been reset.
If you skip this step, the volumes will remain empty and the applications will not function.

---

### first-time-setup.sh – Clean Clone and Dependency Installer

This script is intended to be run once per container initialization to prepare a fresh developer environment. It performs a clean clone of both the Child and Parent application repositories into their respective persistent Docker volumes, installs all required dependencies, and ensures proper environment configuration.

#### What This Script Does

1. Prompts for confirmation before erasing existing contents inside the /workspace/child and /workspace/parent directories. This is a destructive operation and should only be run during initial setup or when explicitly resetting the codebase.
2. Safely deletes all existing files, including hidden files, without affecting mounted volumes outside the workspace directories.
3. Resets file ownership to the dev user so subsequent operations (including npm, composer, and Git) can be performed without permission issues.
4. Clones repositories:

- eacv3 is cloned into /workspace/child
- easv3parent is cloned into /workspace/parent

5. Copies pre-configured environment files from /workspace/env/ into each application folder as .env.local.override, allowing the applications to initialize with the proper database and runtime settings.
6. Creates a .cloned lockfile in both app directories as a marker that the initial clone and setup have occurred. This can be used by other scripts to prevent re-running this setup unnecessarily.
7. Installs application dependencies:

- Runs composer install in both apps with production-optimized flags.
- Runs npm install and builds frontend assets.

#### When to Use This Script

- After provisioning a brand-new development container.
- If the persistent volumes have been reset or cleared manually.
- When switching GitHub branches or restoring production backups.

#### Important Notes

- This script assumes that valid SSH keys have already been added to the container for GitHub access.
- It must be run from within the container (dev_coder) as the dev user.
- If the environment files or GitHub credentials are missing or misconfigured, the script will fail safely and display appropriate error messages.

```sh
./first-time-setup.sh 
```

### 🧪 run-all-migrations.sh – Safe Doctrine Migrations Runner

This script automatically checks and applies any pending Doctrine migrations for both the Child and Parent Symfony applications inside the containerized dev environment.

#### ✅ What It Does

Checks each app for a valid Symfony bin/console path.

Loads the environment variables from .env.local.override using a safe source-based method that supports special characters (like @).

Queries Doctrine for any pending migrations:

Uses: php bin/console doctrine:migrations:status

Looks for: number of "New" migrations

If migrations exist, it runs them using:

```sh
php bin/console doctrine:migrations:migrate --no-interaction
```

Prints progress and success messages for both Child and Parent apps.

#### 🧪 Why This Is Safe and Reliable

✅ No broken environment variables: Uses set -o allexport && source .env.local.override instead of export $(...), avoiding crashes on @ or quotes in .env values.

✅ Early exit on errors: set -e ensures the script fails fast on any issues.

✅ Dual app support: Handles both apps in one pass and gives readable logs.

✅ No migration? No problem: Skips cleanly if there’s nothing to apply.

#### Run the Migrations Script whenever you have to run Doctrine Migrations

```sh
./run-all-migrations.sh
```

## 🧩 Helper Tools for Local Dev Container

### `coder-exec.sh`

A universal helper script to run bash commands in any container without switching context manually.

```sh
./coder-exec.sh <container_name> "<your bash command>"
```

You can also run:

```sh
./coder-exec.sh --list
```

to see all available containers.

Includes support for:

- easv3_coder
- easv3_child_web
- easv3_child_db
- easv3_nginx
- easv3_migrator
- easv3_parent_web
- easv3_parent_db

This is especially useful for running Symfony or Doctrine commands across different containers without manually attaching.

## VS Code Extensions

These extensions are now auto-installed inside the container when used via VS Code Remote - Containers:

```json
[
  "mblode.twig-language",
  "mblode.twig-language-2",
  "ms-playwright.playwright",
  "ms-vscode.test-adapter-converter",
  "hbenl.vscode-test-explorer",
  "vitest.explorer"
]
```

To ensure they are loaded, open the container via "Remote - Containers".

## 🌐 Access Your Apps

- Parent App: http://parent.earlyaccesscare.local
- Child App: http://child.earlyaccesscare.local
- PHPMYADMIN: http://phpmyadmin.earlyaccesscare.local

### 🆘 Support

If you encounter issues or need help setting up, please open a ticket by emailing:

📩 support@intheworksandco.com

Include your operating system, Docker version, and any error output in your message.

### 📦 Coming Soon

- Helm charts for AKS deployments
- Developer helper scripts (init.sh, makefile, etc.)
- GitHub Actions templates for production and staging

© 2025 Early Access Care LLC. All rights reserved.
