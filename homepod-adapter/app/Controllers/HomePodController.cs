namespace HomeAssistantCompanion.Controllers;

using System.Collections.Concurrent;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using HomeAssistantCompanion.Model;
using HomeAssistantCompanion.Options;
using HomeAssistantCompanion.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

[ApiController]
[Route("[controller]")]
public class HomePodController : ControllerBase
{
    private static readonly ConcurrentDictionary<WebhookId, Sensor> Sensors = new();

    private readonly ILogger<HomePodController> _logger;
    private readonly IMqttDiscoveryService _mqttDiscoveryService;
    private readonly IOptions<HomePodOptions> _homePodOptions;
    private readonly IOptions<EndpointSecurityOptions> _endpointSecurityOptions;

    public HomePodController(
        ILogger<HomePodController> logger,
        IMqttDiscoveryService mqttDiscoveryService,
        IOptions<HomePodOptions> homePodOptions,
        IOptions<EndpointSecurityOptions> endpointSecurityOptions
    )
    {
        _logger = logger;
        _mqttDiscoveryService = mqttDiscoveryService;
        _homePodOptions = homePodOptions;
        _endpointSecurityOptions = endpointSecurityOptions;
    }

    [HttpPost("{id}", Name = "Post HomePod data")]
    public async Task<IActionResult> Data(
        [FromRoute] WebhookId id,
        [FromBody] Sensor sensor
    )
    {
        var configuredToken = _endpointSecurityOptions.Value.Token;
        if (!string.IsNullOrWhiteSpace(configuredToken) && !HasValidToken(configuredToken))
        {
            _logger.LogWarning("Rejected unauthenticated HomePod request for GUID [{id}]", id);
            return Unauthorized();
        }

        var homePod = _homePodOptions.Value.HomePods.FirstOrDefault(homePod =>
            string.Equals(homePod.Guid, id.ToString(), StringComparison.OrdinalIgnoreCase));

        if (homePod is null)
        {
            _logger.LogWarning("Rejected data for unconfigured HomePod GUID [{id}]", id);
            return NotFound();
        }

        _logger.LogInformation(
            "Received data from HomePod {name} [{id}]: {data}",
            homePod.Name,
            id,
            JsonSerializer.Serialize(sensor)
        );

        Sensors.TryAdd(id, sensor);

        var existingSensor = Sensors[id];
        if (sensor.Humidity < 10)
        {
            if (existingSensor.Humidity > 10)
            {
                _logger.LogWarning("HomePod [{id}] Humidity is 0, using existing value", id);
                sensor.Humidity = existingSensor.Humidity;
            }
            else
            {
                _logger.LogWarning("HomePod [{id}] Humidity is 0, using average value", id);
                sensor.Humidity = Sensors
                    .Where(o => o.Key != id)
                    .Average(static s => s.Value.Humidity);
            }
        }
        else
        {
            existingSensor.Humidity = sensor.Humidity;
        }
        if (sensor.Temperature < 5)
        {
            if (existingSensor.Temperature > 5)
            {
                _logger.LogWarning("HomePod [{id}] Temperature is 0, using existing value", id);
                sensor.Temperature = existingSensor.Temperature;
            }
            else
            {
                _logger.LogWarning("HomePod [{id}] Temperature is 0, using average value", id);
                sensor.Temperature = Sensors
                    .Where(o => o.Key != id)
                    .Average(static s => s.Value.Temperature);
            }
        }
        else
        {
            existingSensor.Temperature = sensor.Temperature;
        }
        await _mqttDiscoveryService.PublishSensorData(homePod, sensor, HttpContext.RequestAborted);

        return Ok();
    }

    private bool HasValidToken(string configuredToken)
    {
        var authorization = Request.Headers.Authorization.ToString();
        var suppliedToken = authorization.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
            ? authorization["Bearer ".Length..]
            : string.Empty;

        return CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(configuredToken),
            Encoding.UTF8.GetBytes(suppliedToken));
    }
}
