{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  TF_VAR_cluster_name = "namnd-homelab-2026";
  TF_VAR_talos_version = "v1.13.4";
}
