# toggl-extractor

Simple CLI to regularly extract data from Toggl. 

## Usage

Run with nix:

```shell
TOGGL_API_TOKEN=1234 nix run github:dtgoitia/toggl-extractor
```

or to compile locally and run:

```shell
git clone git@github.com:dtgoitia/toggl-extractor.git
cd togg-extractor
nix run .#compile
TOGGL_API_TOKEN=1234 dist/toggl-extractor -h
```

To explore all available options:

```
nix run .#<TAB>
```

### Configuration

The configuration file must be at:

```
$HOME/.config/toggl-extractor/config.json
```

with the following schema:

```jsonc
{
  "data_dir": "~/some/dir/"  // required
}
```

### Credentials

The Toggl API token must be passed as the `TOGGL_API_TOKEN` environment variable.

## Contribute

Enable development environment:

```shell
nix develop
dart run bin/main.dart -h
```

To update flake dependencies

```shell
nix flake update
git add flake.lock
git commit -m 'update flakes'
```
