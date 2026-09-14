using System.Text.Json.Serialization;
using DateOnlyTimeOnly.AspNet.Converters;
using HomeAssistantCompanion.Options;
using HomeAssistantCompanion.Services;
using LiteDB.Async;
using Microsoft.IO;

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

services.AddSingleton<IHomeAssistantService, HomeAssistantService>();

services
    .AddOptions<HomeAssistantOptions>()
    .Bind(builder.Configuration.GetSection("HomeAssistant"));

services
    .AddOptions<HomePodOptions>()
    .Bind(builder.Configuration);

services.AddHttpClient();

var app = builder.Build();

app.MapControllers();

app.Run();
