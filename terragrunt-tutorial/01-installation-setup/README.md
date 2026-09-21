# Lesson 01 — Installation & Setup

## 🎯 Goal

Install Terraform + Terragrunt, verify they work together, and set up a
comfortable working environment for the rest of the course.

---

## 1. What you need (and why both tools)

| Tool | Role | Analogy |
|---|---|---|
| **Terraform** | Does the real work (creates cloud resources) | The engine 🚂 |
| **Terragrunt** | Prepares config, then calls Terraform | The driver 🧑‍✈️ |

Terragrunt shells out to a `terraform` binary on your `PATH`. Version
compatibility matters — check the
[compatibility matrix](https://terragrunt.gruntwork.io/docs/getting-started/supported-terraform-versions/)
if you hit weird errors. For this course:

- **Terraform >= 1.5**
- **Terragrunt >= 0.55** (the `run-all` command syntax used here)

> OpenTofu users: Terragrunt also supports `tofu` as the binary
> (`--tf-path tofu` or `terraform_binary = "tofu"`). The concepts are identical.

## 2. Install on Linux / macOS / Windows

**macOS (Homebrew):**

```bash
brew install terraform terragrunt
```

**Linux (manual — works everywhere):**

```bash
# Terraform
wget https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip
unzip terraform_1.9.8_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Terragrunt
wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.67.0/terragrunt_linux_amd64
chmod +x terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
```

> 💡 Always pick versions from the official releases pages
> (hashicorp.com + gruntwork-io/terragrunt on GitHub) — the numbers above are
> examples, not pinned requirements.

**Windows (Chocolatey / Scoop):**

```powershell
choco install terraform terragrunt
# or: scoop install terraform terragrunt
```

## 3. Verify the installation

```bash
terraform version
# Terraform v1.9.x ...

terragrunt --version
# terragrunt version v0.67.x
```

Both must print a version. If `terragrunt` can't find `terraform`, you'll get
`terraform: command not found` on the first `terragrunt plan` — fix your `PATH`.

## 4. Editor setup (recommended)

- **VS Code** + the **HashiCorp Terraform** extension → syntax highlighting for
  both `.tf` and `.hcl` files.
- Format on save is your friend:
  - `terraform fmt` for `.tf` files
  - `terragrunt hclfmt` for `terragrunt.hcl` files

```bash
# Format everything in the course (safe to run anytime)
terragrunt hclfmt
terraform fmt -recursive
```

## 5. Conventions used in this course

```
live/                  # Terragrunt wrappers (one folder = one state file = one unit)
modules/               # Pure reusable Terraform modules
terragrunt.hcl         # Wrapper config (lowercase, exact name)
```

- One folder with a `terragrunt.hcl` = **one unit** (one `terraform apply`).
- Never put a `backend "s3"` block inside `modules/*.tf` — the backend always
  comes from Terragrunt's `remote_state` (Lesson 03).
- Never commit `.terragrunt-cache/`, `*.tfstate`, or `*.tfvars` with secrets.
  Each lesson ships runnable examples; a sample `.gitignore` lives below.

Sample `.gitignore` for Terragrunt projects:

```gitignore
# Terragrunt / Terraform — never commit these
.terragrunt-cache/
*.tfstate
*.tfstate.backup
.terraform/
.terraform.lock.hcl
crash.log
override.tf
*_generated.tf
greeting-*.txt
```

## 6. Sanity check (30 seconds)

```bash
cd terragrunt-tutorial/02-first-terragrunt-config/live/dev/greeting
terragrunt init   # should download the local provider, no AWS needed
terragrunt plan   # should show "1 to add" for a local_file
```

If that works, your toolchain is ready. (Don't worry about what these files
do yet — that's the very next lesson.)

---

## ✏️ Exercises

1. Run `terraform version` and `terragrunt --version`. Write both down.
2. Run `terragrunt --help` and find the `run-all` subcommand. Skim its flags.
3. Install the VS Code Terraform extension and open any `terragrunt.hcl` in
   this repo — confirm you get HCL highlighting.

## ✅ Key takeaways

- You need **both** binaries: Terraform (engine) + Terragrunt (driver).
- One `terragrunt.hcl` folder = **one unit** = one state file.
- Format with `terragrunt hclfmt`; never commit cache/state files.

Next 👉 [Lesson 02 — Your First terragrunt.hcl](../02-first-terragrunt-config/README.md)
