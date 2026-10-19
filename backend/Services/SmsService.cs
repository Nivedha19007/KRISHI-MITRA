using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace KrishiMitra.OtpApi.Services;

public class SmsService : ISmsService
{
    private readonly ILogger<SmsService> _logger;
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;

    private const string Fast2SmsApiUrl = "https://www.fast2sms.com/dev/bulkV2";

    public SmsService(ILogger<SmsService> logger, IConfiguration configuration, IHttpClientFactory httpClientFactory)
    {
        _logger = logger;
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
    }

    public async Task<bool> SendSmsAsync(string phoneNumber, string otpCode, CancellationToken ct = default)
    {
        var otpMode = _configuration["OTP_MODE"] ?? _configuration["OtpSettings:Mode"] ?? "demo";

        if (string.Equals(otpMode, "real", StringComparison.OrdinalIgnoreCase))
        {
            var apiKey = _configuration["FAST2SMS_API_KEY"] ?? _configuration["SMS_PROVIDER_API_KEY"];

            if (string.IsNullOrWhiteSpace(apiKey))
            {
                _logger.LogError("REAL SMS MODE ENABLED (OTP_MODE=real), but FAST2SMS_API_KEY environment variable is not configured!");
                return false;
            }

            // Extract 10-digit Indian mobile number from E.164 (e.g. +919876543210 -> 9876543210)
            string tenDigitPhone = ExtractTenDigitPhoneNumber(phoneNumber);
            if (string.IsNullOrWhiteSpace(tenDigitPhone) || tenDigitPhone.Length != 10)
            {
                _logger.LogError("Invalid phone number format for Fast2SMS. Expected 10-digit mobile number, received: {PhoneNumber}", phoneNumber);
                return false;
            }

            _logger.LogInformation("REAL SMS MODE: Dispatching OTP via Fast2SMS API to target phone {PhoneNumber}...", phoneNumber);

            try
            {
                var client = _httpClientFactory.CreateClient("Fast2SMS");
                var request = new HttpRequestMessage(HttpMethod.Post, Fast2SmsApiUrl);
                request.Headers.Add("authorization", apiKey.Trim());

                var payload = new Fast2SmsRequest
                {
                    Route = "otp",
                    Numbers = tenDigitPhone,
                    VariablesValues = otpCode
                };

                string jsonContent = JsonSerializer.Serialize(payload);
                request.Content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

                var response = await client.SendAsync(request, ct);
                string responseBody = await response.Content.ReadAsStringAsync(ct);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError("Fast2SMS HTTP Error [{StatusCode}]: {ResponseBody}", response.StatusCode, responseBody);
                    return false;
                }

                var apiResult = JsonSerializer.Deserialize<Fast2SmsResponse>(responseBody);
                if (apiResult != null && apiResult.Return)
                {
                    _logger.LogInformation("Fast2SMS OTP successfully dispatched. Request ID: {RequestId}", apiResult.RequestId);
                    return true;
                }

                _logger.LogError("Fast2SMS API returned failure response: {ResponseBody}", responseBody);
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Exception encountered while calling Fast2SMS API for phone {PhoneNumber}", phoneNumber);
                return false;
            }
        }

        // Default: DEMO Mode
        Console.WriteLine($"\n=================================================================");
        Console.WriteLine($"[DEMO OTP MODE] Verification OTP for {phoneNumber} is: {otpCode}");
        Console.WriteLine($"=================================================================\n");
        _logger.LogInformation("=================================================================");
        _logger.LogInformation("[DEMO OTP MODE] Verification OTP for {PhoneNumber} is: {OtpCode}", phoneNumber, otpCode);
        _logger.LogInformation("=================================================================");

        return true;
    }

    private static string ExtractTenDigitPhoneNumber(string input)
    {
        if (string.IsNullOrWhiteSpace(input)) return string.Empty;
        var digitsOnly = new string(input.Where(char.IsDigit).ToArray());
        if (digitsOnly.Length == 10) return digitsOnly;
        if (digitsOnly.Length > 10) return digitsOnly.Substring(digitsOnly.Length - 10);
        return digitsOnly;
    }

    private class Fast2SmsRequest
    {
        [JsonPropertyName("route")]
        public string Route { get; set; } = "otp";

        [JsonPropertyName("numbers")]
        public string Numbers { get; set; } = string.Empty;

        [JsonPropertyName("variables_values")]
        public string VariablesValues { get; set; } = string.Empty;
    }

    private class Fast2SmsResponse
    {
        [JsonPropertyName("return")]
        public bool Return { get; set; }

        [JsonPropertyName("request_id")]
        public string? RequestId { get; set; }

        [JsonPropertyName("message")]
        public object? Message { get; set; }
    }
}
