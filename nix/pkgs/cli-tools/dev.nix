#
# Tools to develop "vault.box".
#
{ pkgs }:
with pkgs;
{
    all = [
        awscli2
        nixos-rebuild
        openssl
        python3
        qemu
    ];
}