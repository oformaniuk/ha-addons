namespace HomeAssistantCompanion.Services;

using System.Text.Json;
using HomeAssistantCompanion.Model;
using HomeAssistantCompanion.Options;
using Microsoft.Extensions.Options;
using MQTTnet;
using MQTTnet.Client;
using MQTTnet.Protocol;

public interface IMqttDiscoveryService
{
    Task PublishSensorData(HomePodConfiguration homePod, Sensor sensor, CancellationToken cancellationToken);
}

public sealed class MqttDiscoveryService : IMqttDiscoveryService
{
    private readonly ILogger<MqttDiscoveryService> _logger;
    private readonly IOptions<MqttOptions> _options;

    public MqttDiscoveryService(
        ILogger<MqttDiscoveryService> logger,
        IOptions<MqttOptions> options)
    {
        _logger = logger;
        _options = options;
    }

    public async Task PublishSensorData(
        HomePodConfiguration homePod,
        Sensor sensor,
        CancellationToken cancellationToken)
    {
        var options = _options.Value;
        var deviceId = ToIdentifier(homePod.Guid);
        var discoveryPrefix = options.DiscoveryPrefix.Trim('/');
        var stateTopic = $"homepod_adapter/{deviceId}/state";

        if (string.IsNullOrWhiteSpace(options.Host) || string.IsNullOrWhiteSpace(discoveryPrefix))
        {
            throw new InvalidOperationException("MQTT host and discovery prefix must be configured.");
        }

        var factory = new MqttFactory();
        using var client = factory.CreateMqttClient();
        var clientOptions = new MqttClientOptionsBuilder()
            .WithTcpServer(options.Host, options.Port)
            .WithClientId($"homepod-adapter-{deviceId}")
            .WithCleanSession()
            .Build();

        if (!string.IsNullOrWhiteSpace(options.Username))
        {
            clientOptions = new MqttClientOptionsBuilder()
                .WithTcpServer(options.Host, options.Port)
                .WithClientId($"homepod-adapter-{deviceId}")
                .WithCredentials(options.Username, options.Password)
                .WithCleanSession()
                .Build();
        }

        await client.ConnectAsync(clientOptions, cancellationToken);

        try
        {
            await Publish(client, $"{discoveryPrefix}/sensor/{deviceId}/temperature/config", new
            {
                name = "Temperature",
                unique_id = $"homepod_adapter_{deviceId}_temperature",
                state_topic = stateTopic,
                value_template = "{{ value_json.temperature }}",
                device_class = "temperature",
                state_class = "measurement",
                unit_of_measurement = "°C",
                device = Device(homePod, deviceId),
            }, cancellationToken);

            await Publish(client, $"{discoveryPrefix}/sensor/{deviceId}/humidity/config", new
            {
                name = "Humidity",
                unique_id = $"homepod_adapter_{deviceId}_humidity",
                state_topic = stateTopic,
                value_template = "{{ value_json.humidity }}",
                device_class = "humidity",
                state_class = "measurement",
                unit_of_measurement = "%",
                device = Device(homePod, deviceId),
            }, cancellationToken);

            await Publish(client, stateTopic, sensor, cancellationToken);
            _logger.LogInformation("Published sensor data for HomePod {name} to MQTT", homePod.Name);
        }
        finally
        {
            await client.DisconnectAsync(cancellationToken: cancellationToken);
        }
    }

    private static object Device(HomePodConfiguration homePod, string deviceId) => new
    {
        identifiers = new[] { $"homepod_adapter_{deviceId}" },
        name = homePod.Name,
        manufacturer = "Apple",
        model = "HomePod",
        sw_version = "HomePod Adapter",
    };

    private static async Task Publish(
        IMqttClient client,
        string topic,
        object payload,
        CancellationToken cancellationToken)
    {
        var message = new MqttApplicationMessageBuilder()
            .WithTopic(topic)
            .WithPayload(JsonSerializer.Serialize(payload))
            .WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce)
            .WithRetainFlag()
            .Build();

        await client.PublishAsync(message, cancellationToken);
    }

    private static string ToIdentifier(string value)
    {
        var identifier = new string(value
            .ToLowerInvariant()
            .Select(character => char.IsLetterOrDigit(character) ? character : '_')
            .ToArray())
            .Trim('_');

        return string.IsNullOrEmpty(identifier) ? "unknown_homepod" : identifier;
    }
}
