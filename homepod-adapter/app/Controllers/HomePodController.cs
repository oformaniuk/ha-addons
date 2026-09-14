namespace HomeAssistantCompanion.Controllers;

using System.Collections.Concurrent;
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
    private readonly IHomeAssistantService _homeAssistantService;
    private readonly IOptions<HomePodOptions> _homePodOptions;

    public HomePodController(
        ILogger<HomePodController> logger,
        IHomeAssistantService homeAssistantService,
        IOptions<HomePodOptions> homePodOptions
    )
    {
        _logger = logger;
        _homeAssistantService = homeAssistantService;
        _homePodOptions = homePodOptions;
    }

    [HttpPost("{id}", Name = "Post HomePod data")]
    public async Task<IActionResult> Data(
        [FromRoute] WebhookId id,
        [FromBody] Sensor sensor
    )
    {
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
        await _homeAssistantService.SendWebHook(id, sensor);

        return Ok();
    }
}
