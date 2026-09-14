namespace HomeAssistantCompanion.Options;

public sealed class HomePodOptions
{
    public List<HomePodConfiguration> HomePods { get; set; } = [];
}

public sealed class HomePodConfiguration
{
    public string Name { get; set; } = string.Empty;
    public string Guid { get; set; } = string.Empty;
}
