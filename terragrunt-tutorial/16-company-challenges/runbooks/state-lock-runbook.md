# Runbook: Stuck Terraform State Lock 🔒

**Symptom:** `terragrunt plan/apply` fails with:
`Error acquiring the state lock ... ConditionalCheckFailedException` (DynamoDB).

**DANGER:** Never force-unlock while someone (or CI) is actually applying —
you can corrupt state. This runbook makes unlocks safe.

## Steps

### 1. Identify the lock (2 min)
- Copy the `Lock Info` block from the error: `ID`, `Operation`, `Who`, `Created`.
- Note which unit (folder) and env it belongs to.

### 2. Verify NOBODY is actively applying (5 min — do not skip!)
- [ ] Check CI: is any `apply` workflow running for this env? (Actions tab)
- [ ] Ask in the team channel: "Is anyone applying `<env>/<unit>`? Lock ID `<ID>`."
- [ ] Check lock age: if `Created` is >30 min old AND no CI run is active, it's
      almost certainly orphaned (crashed laptop, killed CI job, network drop).

### 3. Force-unlock (1 min)
```bash
cd live/<env>/<region>/<unit>
terragrunt force-unlock <LOCK-ID>   # paste the ID from step 1, type "yes"
```

### 4. Verify health (3 min)
```bash
terragrunt plan   # must succeed with NO unexpected changes
```
- If the plan shows unexpected creates/deletes → STOP, escalate: the crashed
  apply may have partially completed. Do not apply blindly.

### 5. Re-run the original operation
- Re-run the failed `plan`/`apply`, or re-run the CI job.

### 6. Postmortem (async, 10 min)
- What orphaned the lock? (killed process, CI timeout, two concurrent applies?)
- Fix the cause: add CI `concurrency` queueing ([L15](../../15-cicd-pipelines/README.md)),
  raise CI timeouts, add `retryable_errors` for transient lock contention ([L08](../../08-hooks/README.md)).

## Prevention checklist
- [ ] CI applies queued per env (never overlapping)
- [ ] Engineers don't apply from laptops to shared envs (CI only for stage/prod)
- [ ] Lock table uses pay-per-request billing (no throttling surprises)
- [ ] Team knows this runbook exists (link it in the CI failure message!)
