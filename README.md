# CarEdu
3D Car themed education game, made in [Godot](https://godotengine.org/)

## Running
If you are on linux and have the [nix package manager](https://nixos.org/) with [flake support](https://nixos.wiki/wiki/Flakes), just:
```console
$ nix run github:12Boti/CarEdu
```
On windows, download the latest [release](https://github.com/12Boti/CarEdu/releases).

To start the game, you'll need a level file.

## Level files
A level file is just json data. You can see an example [here](levels/1.json). The format is:
- `type`: a string, only `collect` is supported, more level types could be added in the future
- `text`: a string, the text that appears at the start of the game, explaining the task
- `right`: a list of strings, these are what the player should collect
- `wrong`: a list of strings, these are what the player should avoid

## Controls
You can use either AD or the arrow keys to switch lanes.
