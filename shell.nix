{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    pkgs.terraform
    pkgs.cf-terraforming
  ];
  shellHook = ''
    echo "Cloudflare IaC environment loaded!"
  '';
}
