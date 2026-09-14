using System.Text.Json.Serialization;
using DateOnlyTimeOnly.AspNet.Converters;
using HomeAssistantCompanion.Options;
using HomeAssistantCompanion.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration
    .AddJsonFile("/data/options.json", optional: true, reloadOnChange: true)
    .AddEnvironmentVariables();

// Add services to the container.

var services = builder.Services;
services.AddControllers().AddJsonOptions(static options =>
    {
        options.JsonSerializerOptions.PropertyNameCaseInsensitive = true;
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
        options.JsonSerializerOptions.Converters.Add(new DateOnlyJsonConverter());
    }
);

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
services.AddEndpointsApiExplorer();

services
    .AddOptions<HomePodOptions>()
    .Bind(builder.Configuration);

services
    .AddOptions<MqttOptions>()
    .Bind(builder.Configuration);

services.AddSingleton<IMqttDiscoveryService, MqttDiscoveryService>();

var app = builder.Build();

app.MapControllers();

app.Run();
