# Lesson 11 — run-all Orchestration (one command, everything)

## 🎯 Goal

Apply/destroy **entire stacks in dependency order** with `terragrunt run-all`,
control parallelism, and visualize the dependency graph.

---

## 1. The superpower command

```bash
# From ANY parent folder (live/, live/dev/, ...), Terragrunt finds all
# units below it and runs the command on each — in dependency order:
terragrunt run-all plan
terragrunt run-all apply
terragrunt run-all destroy   # ⚠️ reverse order, prompts per unit (unless -auto-approve)
terragrunt run-all output
```

Given this tree:

```
live/dev/
├── vpc/terragrunt.hcl        # no dependencies
├── db/terragrunt.hcl         # dependency → ../vpc
└── app/terragrunt.hcl        # dependency → ../vpc, ../db
```

`run-all apply` produces this execution plan automatically:

```
1. vpc            (level 0 — no deps, runs first, in parallel with other level-0)
2. db             (level 1 — after vpc)
3. app            (level 2 — after vpc + db)
```

`run-all destroy` reverses it: app → db → vpc. You never hand-sequence again.

## 2. How ordering is derived

- `dependency` blocks (Lesson 06) = edges in the graph (also `dependencies` paths).
- Units with no deps run first, in parallel; dependents wait for their upstreams.
- If unit A depends on B which depends on A → Terragrunt errors with a clear
  **cycle detected** message. Fix by removing one edge.

Visualize before you run:

```bash
terragrunt graph-dependencies | dot -Tpng > graph.png
# No graphviz? `terragrunt graph-dependencies` still prints the digraph text.
```

## 3. Parallelism & safety flags

```bash
# Limit concurrent Terraform runs (default = #CPU cores... be kind to APIs)
terragrunt run-all apply --terragrunt-parallelism 4

# Fail fast vs keep going
terragrunt run-all apply --terragrunt-fail-on-state-bucket-creation-error ...
# most used: stop everything on first failure (default) vs continue:
terragrunt run-all apply --terragrunt-non-interactive --terragrunt-ignore-dependency-errors
```

Key flags to memorize:

| Flag | Effect |
|---|---|
| `--terragrunt-parallelism N` | Max concurrent units |
| `--terragrunt-non-interactive` / `-auto-approve` | No `yes` prompts (CI mode; use carefully!) |
| `--terragrunt-include-dir` / `--terragrunt-exclude-dir` | Run only a subset (supports `*` globs) |
| `--terragrunt-strict-include` | With include-dir: also include the *dependencies* of matches (safe partial applies ✅) |
| `--terragrunt-ignore-dependency-errors` | Continue with other units if one fails (report at end) |

Partial-apply example — "deploy app and whatever it needs, nothing else":

```bash
terragrunt run-all apply \
  --terragrunt-include-dir "*/app" \
  --terragrunt-strict-include
```

## 4. run-all + mocks: plan the world on day one

Combine with Lesson 06: with `mock_outputs` on every dependency, a single
`run-all plan` from `live/dev` renders a plan for **every unit** even when
nothing is applied yet. Perfect for CI plan-on-PR pipelines.

## 5. This lesson's example (runnable, no cloud)

A 3-unit chain — `base` → `middle` → `top` — using the local provider:

```
11-run-all/live/dev/{base,middle,top}/terragrunt.hcl
11-run-all/modules/{base,middle,top}/
```

```bash
cd live/dev

terragrunt run-all plan     # plans all 3 (mocks fill gaps on first run)
terragrunt run-all apply    # applies base → middle → top, in order, one command 🎉
cat ../../modules/*/*.txt   # each file references its upstream's id — verify the chain!

terragrunt run-all destroy  # destroys top → middle → base (reverse ✅)
```

Watch the log prefixes (`[base]`, `[middle]`, `[top]`… actually folder paths) —
Terragrunt interleaves parallel output but keeps it labeled.

## 6. CI pattern (preview of professional usage)

```bash
# Pull request: plan everything, comment the diff
terragrunt run-all plan --terragrunt-non-interactive

# Merge to main: apply the env folder
cd live/prod && terragrunt run-all apply --terragrunt-non-interactive
```

Scope applies per env/region folder so a `dev` change can never touch `prod`
(matching the Lesson 09 layout).

---

## ✏️ Exercises

1. Run `graph-dependencies` in `live/dev` and sketch the 3-node graph.
2. `run-all apply` from `live/dev`, then verify each output file chains the
   correct upstream id.
3. Try `--terragrunt-include-dir "*/top" --terragrunt-strict-include plan` and
   observe which units get planned (top + its deps) vs without strict mode.
4. Intentionally create a dependency cycle in a scratch copy and read the error.

## ✅ Key takeaways

- `run-all <cmd>` runs all units below cwd in dependency order (destroy reverses).
- Order comes from `dependency`/`dependencies`; cycles fail fast with a clear error.
- Control with parallelism, include/exclude-dir (+strict), non-interactive flags.

Next 👉 [Lesson 12 — Built-in Functions](../12-functions/README.md)
