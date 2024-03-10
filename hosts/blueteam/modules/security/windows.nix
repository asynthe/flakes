# Microsoft infrastructure and Windows-related tools, incl. SMB

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    adreaper
    bloodhound-py
    chainsaw
    certipy
    certsync
    coercer
    enum4linux
    enum4linux-ng
    erosmb
    evil-winrm
    go365
    gomapenum
    kerbrute
    knowsmore
    lil-pwny
    nbtscan
    nbtscanner
    offensive-azure
    python3Packages.lsassy
    python3Packages.pypykatz
    samba
    smbmap
    smbscan
  ];
}
