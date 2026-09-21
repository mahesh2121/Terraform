# Terragrunt Tutorial — From Zero to Advanced

Learn **Terragrunt** step-by-step: what it is, why it exists, how it wraps
Terraform, and how to use every major concept with hands-on examples.

> **One-line definition:** Terragrunt is a **thin wrapper for Terraform** that
> keeps your Terraform code **DRY** (Don't Repeat Yourself), manages **remote
> state** automatically, wires **dependencies between modules**, and lets you
> **orchestrate hundreds of modules** with one command.

---

## 📚 Course Map (learn in order)

| # | Lesson | What you will learn |
|---|--------|---------------------|
| 00 | [Why Terragrunt?](00-why-terragrunt/README.md) | Problems with plain Terraform, what "Terraform wrapper" means, before/after comparison |
| 01 | [Installation & Setup](01-installation-setup/README.md) | Install Terraform + Terragrunt, verify versions, editor setup, project conventions |
| 02 | [Your First terragrunt.hcl](02-first-terragrunt-config/README.md) | `terraform { source }` block, `terragrunt init/plan/apply`, how wrapping works |
| 03 | [Remote State Management](03-remote-state/README.md) | `remote_state` block, S3 backend, dynamic `key`, no more copy-pasted `backend.tf` |
| 04 | [Inputs & Locals](04-inputs-locals/README.md) | `inputs = {}`, `locals {}`, passing variables into Terraform without `.tfvars` files |
| 05 | [Include & DRY Hierarchy](05-include-dry/README.md) | `include`, `find_in_parent_folders()`, root/parent configs, `expose`, `merge` |
| 06 | [Dependencies](06-dependencies/README.md) | `dependency` & `dependencies` blocks, `mock_outputs`, reading outputs across modules |
| 07 | [Generate Blocks](07-generate/README.md) | `generate` provider/backend/variables files dynamically (`provider.tf`, `backend.tf`) |
| 08 | [Hooks](08-hooks/README.md) | `before_hook`, `after_hook`, `error_hook`, `extra_arguments`, `retryable_errors` |
| 09 | [Multi-Environment Layout](09-environments/README.md) | `dev/stage/prod` × multi-region folder design, per-env values, promotion flow |
| 10 | [Reusable Module Catalog](10-modules-catalog/README.md) | Designing `modules/` (generic) vs `live/` (environment-specific) like a pro |
| 11 | [run-all Orchestration](11-run-all/README.md) | `terragrunt run-all plan/apply/destroy`, parallelism, ordering via dependencies |
| 12 | [Built-in Functions](12-functions/README.md) | `read_terragrunt_config`, `get_env`, `get_aws_account_id`, path functions, conditionals |
| 13 | [Capstone Project](13-capstone-project/README.md) | Full real-world AWS project: VPC + EC2 + S3 wired together, multi-env |
| 14 | [Cheatsheet & FAQ](14-cheatsheet-faq/README.md) | Command cheatsheet, Terraform vs Terragrunt, migration guide, troubleshooting |
| 15 | [CI/CD Pipelines ⭐ L3](15-cicd-pipelines/README.md) | GitHub Actions: plan on PR, gated prod applies, OIDC auth, drift detection |

---

## 🧠 How to use this tutorial

1. **Read the lesson README** (concept + diagrams + explanation).
2. **Look at the example files** inside that lesson folder.
3. **Run it yourself** — early lessons use the free `local`/`null` providers so
   they cost nothing; AWS lessons clearly say what they create.
4. **Do the exercises** at the bottom of each lesson.
5. Move to the next lesson.

Typical commands you will run in every lesson:

```bash
cd terragrunt-tutorial/02-first-terragrunt-config/live/dev/greeting
terragrunt init
terragrunt plan
terragrunt apply
terragrunt destroy
```

## ✅ Prerequisites

- Basic Terraform knowledge (providers, resources, variables, state).
  If you are new, skim the existing folders in this repo first:
  [`instance/`](../instance), [`variables/`](../variables), [`Nginx/`](../Nginx).
- Terraform >= 1.5 and Terragrunt >= 0.55 installed
  (see [Lesson 01](01-installation-setup/README.md)).
- For AWS lessons: an AWS account + credentials. For all other lessons: nothing.

## 🗂️ Repository layout convention used in this course

```
terragrunt-tutorial/
├── README.md                  # ← you are here (course index)
├── 00-why-terragrunt/         # concept + before/after examples
├── 01-installation-setup/
├── 02-first-terragrunt-config/
│   ├── README.md
│   ├── live/                  # environment-specific configs (thin wrappers)
│   │   └── dev/greeting/terragrunt.hcl
│   └── modules/               # reusable pure-Terraform modules
│       └── greeting/
├── ... (each lesson follows the same idea)
└── 13-capstone-project/       # full multi-env AWS example
```

**Golden rule you will see repeated:** `modules/` = *how* to build something
(reusable Terraform). `live/` = *what/where* to build
(Terragrunt wrappers per environment).

Let's start 👉 [Lesson 00 — Why Terragrunt?](00-why-terragrunt/README.md)
