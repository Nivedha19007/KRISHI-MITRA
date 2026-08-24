using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;

namespace KrishiMitra.OtpApi.Services;

public interface IMandiService
{
    Task<JsonElement> GetPricesAsync(
        string? state,
        string? district,
        string? commodity,
        int limit = 100,
        int offset = 0);
}

public class MandiService : IMandiService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly IMemoryCache _cache;
    private readonly ILogger<MandiService> _logger;

    private const string ResourceId = "9ef84268-d588-465a-a308-a864a43d0070";

    public MandiService(
        HttpClient httpClient,
        IConfiguration configuration,
        IMemoryCache cache,
        ILogger<MandiService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _cache = cache;
        _logger = logger;
    }

    public async Task<JsonElement> GetPricesAsync(
        string? state,
        string? district,
        string? commodity,
        int limit = 100,
        int offset = 0)
    {
        var apiKey = _configuration["DATA_GOV_API_KEY"]
            ?? Environment.GetEnvironmentVariable("DATA_GOV_API_KEY")
            ?? _configuration["DataGovApiKey"];

        if (string.IsNullOrWhiteSpace(apiKey))
        {
            _logger.LogError("[MANDI_SERVICE] DATA_GOV_API_KEY is not configured in appsettings or environment variables.");
            throw new InvalidOperationException(
                "DATA_GOV_API_KEY is not configured in appsettings or environment variables.");
        }

        var clampedLimit = Math.Clamp(limit, 1, 1000);
        var clampedOffset = Math.Max(0, offset);

        var cleanState = (string.IsNullOrWhiteSpace(state) || state.Equals("All", StringComparison.OrdinalIgnoreCase)) ? "" : state.Trim();
        var cleanDistrict = (string.IsNullOrWhiteSpace(district) || district.Equals("All", StringComparison.OrdinalIgnoreCase)) ? "" : district.Trim();
        var cleanCommodity = (string.IsNullOrWhiteSpace(commodity) || commodity.Equals("All", StringComparison.OrdinalIgnoreCase)) ? "" : commodity.Trim();

        var cacheKey = $"mandi_prices_{cleanState.ToLowerInvariant()}_{cleanDistrict.ToLowerInvariant()}_{cleanCommodity.ToLowerInvariant()}_{clampedLimit}_{clampedOffset}";

        if (_cache.TryGetValue(cacheKey, out JsonElement cachedResult))
        {
            _logger.LogInformation("[MANDI_SERVICE] Returning cached Mandi prices for key: {CacheKey}", cacheKey);
            return cachedResult;
        }

        var url = $"https://api.data.gov.in/resource/{ResourceId}?api-key={Uri.EscapeDataString(apiKey)}&format=json&limit={clampedLimit}&offset={clampedOffset}";

        if (!string.IsNullOrWhiteSpace(cleanState))
        {
            url += $"&filters[state]={Uri.EscapeDataString(cleanState)}";
        }

        if (!string.IsNullOrWhiteSpace(cleanDistrict))
        {
            url += $"&filters[district]={Uri.EscapeDataString(cleanDistrict)}";
        }

        if (!string.IsNullOrWhiteSpace(cleanCommodity))
        {
            url += $"&filters[commodity]={Uri.EscapeDataString(cleanCommodity)}";
        }

        var maskedUrl = url.Replace(apiKey, "[API_KEY_HIDDEN]");
        _logger.LogInformation("[MANDI_SERVICE] Requesting data.gov.in endpoint: {Url}", maskedUrl);

        try
        {
            var response = await _httpClient.GetAsync(url);

            if (!response.IsSuccessStatusCode)
            {
                string errorBody = await response.Content.ReadAsStringAsync();
                _logger.LogWarning("[MANDI_SERVICE] data.gov.in returned HTTP {StatusCode}: {ErrorBody}", (int)response.StatusCode, errorBody);

                // Handle Rate Limiting (429) or transient errors gracefully without crashing with 500
                if (response.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
                {
                    _logger.LogWarning("[MANDI_SERVICE] Rate limit exceeded from data.gov.in. Returning empty records list to caller.");
                    using var fallbackDoc = JsonDocument.Parse("{\"status\":\"ok\",\"total\":0,\"count\":0,\"limit\":100,\"offset\":0,\"records\":[],\"message\":\"Rate limit exceeded from data.gov.in upstream. Please try again in a few moments.\"}");
                    return fallbackDoc.RootElement.Clone();
                }

                throw new HttpRequestException($"data.gov.in API returned HTTP {(int)response.StatusCode}: {errorBody}");
            }

            var jsonContent = await response.Content.ReadAsStringAsync();
            using var document = JsonDocument.Parse(jsonContent);
            var root = document.RootElement.Clone();

            // Cache valid responses for 15 minutes
            _cache.Set(cacheKey, root, TimeSpan.FromMinutes(15));
            return root;
        }
        catch (Exception ex) when (ex is not InvalidOperationException)
        {
            _logger.LogError(ex, "[MANDI_SERVICE] Exception querying data.gov.in. Returning empty records response.");
            using var errorDoc = JsonDocument.Parse("{\"status\":\"error\",\"total\":0,\"count\":0,\"limit\":100,\"offset\":0,\"records\":[],\"message\":\"Upstream data.gov.in service temporarily unavailable.\"}");
            return errorDoc.RootElement.Clone();
        }
    }
}