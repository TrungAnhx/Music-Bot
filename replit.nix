{ pkgs }: {
  deps = [
    pkgs.openjdk17
    pkgs.python310
    pkgs.python310Full
    pkgs.python310Packages.pip
    pkgs.unzip
    pkgs.file
    pkgs.curl
  ];
}
