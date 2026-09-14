# HomePod Adapter

This Home Assistant add-on receives temperature and humidity data at
`POST /HomePod/<guid>` and forwards it to the Home Assistant webhook with the
same GUID.

## Configuration

In the add-on's **Configuration** tab, add one item under **HomePods** for each
device:

- **name**: a label used in add-on logs, such as `Kitchen HomePod`.
- **guid**: the Home Assistant webhook GUID for that HomePod.

Only GUIDs in this list are accepted. Configure the sender to call
`http://<home-assistant-host>:8080/HomePod/<guid>` with a JSON body such as
`{"temperature": 21.5, "humidity": 43}`.
