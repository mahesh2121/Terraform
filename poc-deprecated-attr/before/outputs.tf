# BEFORE (broken) — same outputs as after/; proves behavior is unchanged.

output "region" {
  description = "Current region (via deprecated .name — warns on v6)"
  value       = local.region
}
