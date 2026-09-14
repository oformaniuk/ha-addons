namespace HomeAssistantCompanion.Model
{
    using System.Text.Json.Serialization;

    public class Sensor
    {
        [JsonPropertyName("temperature")]
        public double Temperature { get; set; }

        [JsonPropertyName("humidity")]
        public double Humidity { get; set; }
    }
}