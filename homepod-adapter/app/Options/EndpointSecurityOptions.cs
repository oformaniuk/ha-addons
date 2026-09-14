namespace HomeAssistantCompanion.Options;

using Microsoft.Extensions.Configuration;

public sealed class EndpointSecurityOptions
{
    [ConfigurationKeyName("endpoint_token")]
    public string Token { get; set; } = string.Empty;
}
