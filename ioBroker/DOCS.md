# Home Assistant Add-on: ioBroker

## Installation

After installation, and successful startup, the ioBroker instance should be available at port `8081`.
If your HA instance is running with SSL support, the `OPEN WEB UI` button might not work correctly.

**Note:** As this image is not based on the official home assistant add-on images the Supervisor has some delay on the add-on state (i guess this is the reason).
It might be up and running while the `Info` tab is not aware of this right now. Page reload might help.

## Updating `js-controller`

The bundled `js-controller` is not (always) the most recent version. (Thanks to _tintim_ [#21](1)).

Updating can be archived manually via `portainer` or by using the [`eval` setting](<#eval-(string)>).

Manually:
Jump into the container via `portainer` and run line by line:

```bash
maintenance on
iobroker update
iobroker upgrade self
curl -sL https://iobroker.net/fix.sh | bash
```

## Configuration

### `eval` (string)

Allows to pass some bash commands to run every time before the start of ioBroker.

This can be used e.g. to upgrade the `js-controller`.

Example:

```yaml
eval: "iobroker update && iobroker upgrade self"
```

You might want to disable this after a run.

_Only use when you know what you are doing!_

## TODO

- Get the panel integration working (if this is possible)
- Use some official base image (maybe running the buanet dockerfile onto office image work)

## Technical notes

The `buanet` docker image contains some pretty useful startup script.

To ensure data stays persistent across restarts, the add-on redirects ioBroker's working directory
from `/opt/iobroker` to `/data`.

Home Assistant automatically persists `/data` inside the container. The `"map": ["addon_config:rw"]` 
directive in config.json makes this accessible on the host at `/addon_configs/<addon-slug>/`.

This means ioBroker data ends up at `/addon_configs/iobroker/` on the host and survives upgrades/restarts.

Backups are stored under `/data/backups` (host: `/addon_configs/iobroker/backups`).

[1]: https://github.com/MaxWinterstein/homeassistant-addons/issues/21
