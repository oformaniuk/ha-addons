namespace HomeAssistantCompanion.Options;

using Microsoft.Extensions.Configuration;

public sealed class MqttOptions
{
    [ConfigurationKeyName("mqtt_host")]
    public string Host { get; set; } = "core-mosquitto";

    [ConfigurationKeyName("mqtt_port")]
    public int Port { get; set; } = 1883;

    [ConfigurationKeyName("mqtt_username")]
    public string Username { get; set; } = string.Empty;

    [ConfigurationKeyName("mqtt_password")]
    public string Password { get; set; } = string.Empty;

    [ConfigurationKeyName("mqtt_discovery_prefix")]
    public string DiscoveryPrefix { get; set; } = "homeassistant";
}
