# Runbook: Responding to Infrastructure Drift 🕵️

**Symptom:** Nightly drift job ([L15](../../15-cicd-pipelines/README.md)) opened an issue,
or `run-all plan` shows changes nobody made in code.

## Steps

### 1. Triage the diff (10 min)
Open the drifted plan and classify EVERY change into one bucket:
- **A. Approved-but-unmerged:** a PR is open that explains it → link the PR, no action.
- **B. Emergency fix:** someone changed prod in the console during an incident → go to step 2.
- **C. Unknown/unauthorized:** nobody claims it → go to step 3, treat as security-relevant.

### 2. Emergency fix → codify it (same day)
The console change might be correct — but it must live in code:
1. Write the equivalent change in the module/wrapper (new PR).
2. `run-all plan` → confirm the plan now shows **no diff** for that resource
   (code matches reality).
3. Merge via the normal pipeline. Close the drift issue with the PR link.

### 3. Unknown change → revert it (same day)
1. Check CloudTrail: `who` made the change, `when`, from `where`.
2. If unauthorized: revert via `terragrunt apply` (code is the source of truth —
   apply will undo the manual edit), rotate any exposed credentials, notify security.
3. If it was an approved process outside Terraform (rare): document it and add an
   ADR explaining why, or automate it into the pipeline.

### 4. Close the loop
- Comment the drift issue with: classification (A/B/C), PR or revert commit, owner.
- If bucket B or C: 5-minute team retro — why did someone bypass the pipeline?
  (Too slow? Permissions missing? Didn't know the rule?) Fix the friction, not just
  the symptom.

## Prevention checklist
- [ ] Console write access removed for humans on managed accounts (read-only + break-glass)
- [ ] Drift job runs nightly on every env with issues auto-filed
- [ ] Pipeline is fast enough that bypassing it feels pointless (<10 min plan)
- [ ] "Console is read-only" written in onboarding docs, not just folklore
