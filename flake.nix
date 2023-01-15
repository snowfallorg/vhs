{
  description = "Snowfall VHS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;

        src = ./.;
      };
    in
    lib.mkFlake {
      outputs-builder = channels:
        let
          pkgs = channels.nixpkgs;
          recorder = lib.mkRecorder pkgs;
        in
        {
          packages = rec {
            default = example;

            example = recorder.record {
              tape = ./tapes/hello.tape;
              buildInputs = with pkgs; [
                gum
              ];
            };
          };
        };
    };
}
