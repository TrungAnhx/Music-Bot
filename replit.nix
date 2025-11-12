{ pkgs }: {
  deps = [
    pkgs.openjdk17
    pkgs.python310
    pkgs.python310Packages.pip
  ];
}
