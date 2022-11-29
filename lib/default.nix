{ inputs
, snowfall-inputs
, lib
}:

let
  inherit (inputs.nixpkgs.lib) hasInfix concatMapStringsSep concatStringsSep makeBinPath traceSeq optionalString;
in
{
  # Create a VHS recorder.
  # Type: Attrs -> Attrs
  # Usage: mkRecorder pkgs
  #   result: { record = attrs: {/* ... */}; }
  mkRecorder = pkgs: {
    # Create a recording from a tape.
    # Type: { tape, buildInputs, files } -> Derivation
    # Usage: recorder.record { tape = ./my.tape; buildInputs = [ pkgs.curl ]; files = [ ./my.txt ]; bashrc = ""; }
    #   result: Derivation
    record = { tape, buildInputs ? [ ], files ? [ ], bashrc ? "" }:
      let
        default-build-inputs = with pkgs; [
          chromium
          bashInteractive
        ];

        tape-file =
          if builtins.isPath tape then
            tape
          else
            pkgs.writeTextFile {
              name = "tape";
              text = tape;
            };

        raw-tape-outputs = pkgs.runCommandNoCC "tape-outputs" { } ''
          ${pkgs.gnused}/bin/sed -E -n 's/Output (.*\.(mp4|gif|webm))/\1/p' ${tape-file} > $out
        '';

        tape-outputs =
          builtins.filter
            (value: builtins.isString value && value != "")
            (builtins.split "\n" (builtins.readFile raw-tape-outputs));

        file-mappings = builtins.map
          (file: {
            source = file;
            target =
              lib.last
                (builtins.split "^/nix/store/[[:alnum:]]{32}-[^\/]+/" (builtins.toString file));
          })
          files;

        bash-profile =
          let
            config = optionalString (builtins.length buildInputs > 0) ''
              export PATH=${makeBinPath buildInputs}:$PATH
            '';
          in
          pkgs.writeShellScript ".bashrc" (concatStringsSep "\n" [ config bashrc ]);
      in
      pkgs.runCommandNoCC "recording"
        {
          buildInputs = buildInputs ++ default-build-inputs;
          __noChroot = true;
        } ''
        mkdir .fake-home
        export HOME=$(pwd)/.fake-home

        cp ${bash-profile} $HOME/.bash_profile

        mkdir $out

        ${concatMapStringsSep "\n" (mapping:
          if hasInfix "/" mapping.target then
          ''
            mkdir -p ./$(dirname ${mapping.target})
            cp -r ${mapping.source} ./${mapping.target}
          ''
          else
          ''
            cp -r ${mapping.source} ./${mapping.target}
          ''
        ) file-mappings}

        ${concatMapStringsSep "\n" (output:
          if hasInfix "/" output then
          ''
            mkdir -p $(dirname $out/${output}) $(dirname ./${output})
          ''
          else
          ""
        ) tape-outputs}

        ${pkgs.vhs}/bin/vhs < ${tape-file}

        ${concatMapStringsSep "\n" (output:
          ''
            mv ./${output} $out/${output}
          ''
        ) tape-outputs}
      '';
  };
}
