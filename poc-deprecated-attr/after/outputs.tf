# AFTER (fixed) — identical outputs; behavior unchanged, warning gone.

output "region" {
  description = "Current region (via .region — clean on v6)"
  value       = local.region
}
