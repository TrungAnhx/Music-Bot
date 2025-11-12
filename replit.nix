{ pkgs }: {
  deps = [
    pkgs.openjdk11
    pkgs.jdk11
    pkgs.python310
    pkgs.python310Full
    pkgs.python310Packages.pip
    pkgs.unzip
  ];
}
