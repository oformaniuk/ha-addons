# HomePod Adapter

This Home Assistant add-on receives temperature and humidity data at
`POST /HomePod/<guid>` and creates a Home Assistant MQTT-discovered HomePod
device with Temperature and Humidity sensor entities.

## Configuration

In the add-on's **Configuration** tab, add one item under **HomePods** for each
device:

- **name**: a label used in add-on logs, such as `Kitchen HomePod`.
- **guid**: the identifier configured in the sender URL.

Configure **MQTT host**, port, and credentials for a broker that is already
connected to Home Assistant. The default host, `core-mosquitto`, works with the
official Mosquitto broker add-on. MQTT Discovery must be enabled in Home
Assistant (the default).

Only GUIDs in this list are accepted. Configure the sender to call
`http://<home-assistant-host>:8080/HomePod/<guid>` with a JSON body such as
`{"temperature": 21.5, "humidity": 43}`.

On the first accepted request, the add-on publishes retained MQTT Discovery
configuration and Home Assistant creates the device and its two sensor entities.
