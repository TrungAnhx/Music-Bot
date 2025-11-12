{ pkgs }: {
  deps = [
    pkgs.openjdk17
    pkgs.jdk17
    pkgs.python310
    pkgs.python310Full
    pkgs.python310Packages.pip
  ];
}
