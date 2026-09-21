# Lab 4 — Lock contention: collide two applies, then recover 🔒

**Simulates:** Challenge 1 — concurrent applies fighting over one state lock.
**Time:** ~10 min · **Cost:** free (local provider; local backend locks too!).
**Needs:** two terminals in the same folder.

## Steps

### 1. Start a SLOW apply in terminal 1
```bash
cd live/dev/job
terragrunt apply   # takes ~30s (the module sleeps on purpose) — LEAVE IT RUNNING
```

### 2. While it's running, apply again in terminal 2
```bash
cd live/dev/job   # same folder!
terragrunt apply
# ❌ Error: Error acquiring the state lock [...] — the state is locked by terminal 1.
```
**You just reproduced the #1 on-call IaC alert.** Terminal 2 failed SAFE (nothing
changed) — locking did its job. ✅

### 3. Recover the easy way: wait + retry
Wait for terminal 1 to finish, then re-run terminal 2's command → succeeds.
Map this to the [state lock runbook](../../runbooks/state-lock-runbook.md):
verify-idle → proceed. (If terminal 1 had CRASHED instead of finishing, a remote
backend could hold an orphaned lock — that's when `force-unlock` earns its place.
Local backend locks auto-release with the process, so there's nothing to force here.)

### 4. Prevent it: graceful waiting with `-lock-timeout`
Uncomment the `extra_arguments` block in `live/dev/job/terragrunt.hcl`, then repeat
steps 1–2. This time terminal 2 **waits up to 60s and acquires the lock** instead
of failing instantly. In CI this turns flakes into patience ([L08](../../../08-hooks/README.md)).

### 5. The nuclear option (know it, respect it)
```bash
terragrunt force-unlock <LOCK-ID>   # ONLY when the runbook's checks pass!
```
Never run this while another apply is alive — that's how state gets corrupted.

## What you just proved
- State locking fails CLOSED (safe error, no changes) — by design.
- Recovery = verify idle → retry; orphaned remote locks → runbook → `force-unlock`.
- `-lock-timeout` converts contention from "error" into "queue".

## Cleanup
```bash
terragrunt destroy  # type "yes"
```
