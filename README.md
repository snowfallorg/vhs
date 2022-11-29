# VHS ❤ Nix

<a href="https://nixos.wiki/wiki/Flakes" target="_blank">
	<img alt="Nix Flakes Ready" src="https://img.shields.io/static/v1?logo=nixos&logoColor=d8dee9&label=Nix%20Flakes&labelColor=5e81ac&message=Ready&color=d8dee9&style=for-the-badge">
</a>
<a href="https://github.com/snowfallorg/lib" target="_blank">
	<img alt="Built With Snowfall" src="https://img.shields.io/static/v1?logoColor=d8dee9&label=Built%20With&labelColor=5e81ac&message=Snowfall&color=d8dee9&style=for-the-badge">
</a>
<a href="https://github.com/charmbracelet/vhs" target="_blank">
	<img alt="Powered By VHS" src="https://img.shields.io/static/v1?logoColor=d8dee9&label=Powered%20By&labelColor=5e81ac&message=VHS&color=d8dee9&style=for-the-badge">
</a>

<p>
<!--
	This paragraph is not empty, it contains an em space (UTF-8 8195) on the next line in order
	to create a gap in the page.
-->
  
</p>

This flake provides a helper utility to render [VHS](https://github.com/charmbracelet/vhs)
tapes with Nix.

> **Warning**
>
> Rendering VHS tapes in Nix requires a relaxed or disabled sandbox. Either run `nix build`
> with the flag `--no-sandbox` or set `sandbox = relaxed` in your `nix.conf` file.

## Usage

First, include this flake as an input in your flake.

```nix
{
	description = "My awesome flake";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";

		# Snowfall Lib is not required, but will make configuration easier for you.
		snowfall-lib = {
			url = "github:snowfallorg/lib";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		vhs = {
			url = "github:snowfallorg/vhs";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};
}
```

Next, write a VHS tape.

```tape
Output sample.mp4
Output sample.gif

Type "# Hello World" Enter Enter

Sleep 1

Type "# This is built in Nix!"

Sleep 2
```

Then, use this flake's library to render your VHS tape.

```nix
{
	description = "My awesome flake";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";

		# Snowfall Lib is not required, but will make configuration easier for you.
		snowfall-lib = {
			url = "github:snowfallorg/lib";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		vhs = {
			url = "github:snowfallorg/vhs";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = inputs:
		inputs.snowfall-lib.mkFlake {
			inherit inputs;
			src = ./.;

			outputs-builder = channels:
				let
					recorder = inputs.vhs.lib.mkRecorder channels.nixpkgs;
				in {
					packages.recording = recorder.record {
						tape = ./example.tape;
					};
				};
		};
}
```

Finally, run the build!

```bash
# If you have a relaxed sandbox set in your nix.conf file.
nix build .#

# Otherwise you can build this package without a sandbox.
nix build .# --no-sandbox
```

## Library

### `vhs.lib.mkRecorder`

Create a VHS recorder.

Type: `Attrs -> Attrs`

Usage:

```nix
mkRecorder pkgs
```

Result:

```
{ record = attrs: {/* ... */}; }
```

#### `Recorder.record`

Create a recording from a tape.

Type: `{ tape, buildInputs, files } -> Derivation`

Usage:

```nix
recorder.record {
	# You can use a tape file
	# tape = ./example.tape;
	#
	# Or you can supply its contents as a string!
	tape = ''
		Output sample.mp4
		Output sample.gif

		Type "hello" Enter

		Sleep 2

		Type "cat ./example.txt" Enter

		Sleep 2
	'';

	# Add packages to use in your recording.
	buildInputs = [ pkgs.hello ];

	# Recordings are done in a temporary directory, so any files
	# you want to use in your recording must be specified here.
	files = [
		./example.txt
	];

	# Configuration for the Bash shell.
	bashrc = ''
		export GUM_INPUT_PROMPT="What's up?"
	'';
}
```

Result:

```
Derivation
```
