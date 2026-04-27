{
    pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
    buildInputs = with pkgs; [
        verilator
        python313
        gcc
    ];

    shellHook = ''
    '';
}

