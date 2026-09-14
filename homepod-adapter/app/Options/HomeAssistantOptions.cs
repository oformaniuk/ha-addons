namespace HomeAssistantCompanion.Options
{
    using HomeAssistantCompanion.Model;

    public class HomeAssistantOptions
    {
        public Uri BaseAddress { get; set; } = new("http://supervisor/core/");
        public LongLivingToken Token { get; set; }
    }
}
