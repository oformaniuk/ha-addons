namespace HomeAssistantCompanion.Services
{
    using HomeAssistantCompanion.Model;
    using HomeAssistantCompanion.Options;
    using Microsoft.Extensions.Options;

    public interface IHomeAssistantService
    {
        Task SendWebHook(WebhookId webhookId, Sensor sensor);
    }

    public class HomeAssistantService : IHomeAssistantService
    {
        private readonly HttpClient _httpClient;
        private readonly IOptions<HomeAssistantOptions> _options;

        public HomeAssistantService(
            HttpClient httpClient,
            IOptions<HomeAssistantOptions> options
        )
        {
            _httpClient = httpClient;
            _options = options;
        }

        public async Task SendWebHook(WebhookId webhookId, Sensor sensor)
        {
            var options = _options.Value;

            var sendWebHook = await _httpClient.PostAsync(
                $"{options.BaseAddress}api/webhook/{webhookId}",
                JsonContent.Create(sensor)
            );

            sendWebHook.EnsureSuccessStatusCode();
        }
    }
}
