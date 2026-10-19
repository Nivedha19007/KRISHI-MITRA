using System.Text.Json;
using System.Text.RegularExpressions;
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

    private const string PrimaryResourceId = "35985678-0d79-46b4-9ed6-6f13308a1d24";
    private const string SecondaryResourceId = "9ef84268-d588-465a-a308-a864a43d0070";

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

        var cleanState = (string.IsNullOrWhiteSpace(state) || state.Equals("All", StringComparison.OrdinalIgnoreCase)) ? null : state.Trim();
        var cleanDistrict = (string.IsNullOrWhiteSpace(district) || district.Equals("All", StringComparison.OrdinalIgnoreCase)) ? null : district.Trim();
        var cleanCommodity = (string.IsNullOrWhiteSpace(commodity) || commodity.Equals("All", StringComparison.OrdinalIgnoreCase)) ? null : commodity.Trim();

        var stateKey = cleanState?.ToLowerInvariant() ?? "all";
        var distKey = cleanDistrict?.ToLowerInvariant() ?? "all";
        var commKey = cleanCommodity?.ToLowerInvariant() ?? "all";

        var cacheKey = $"mandi_prices_v2_{stateKey}_{distKey}_{commKey}_{clampedLimit}_{clampedOffset}";

        if (_cache.TryGetValue(cacheKey, out JsonElement cachedResult))
        {
            _logger.LogInformation("[MANDI_SERVICE] Returning cached Mandi prices for key: {CacheKey}", cacheKey);
            return cachedResult;
        }

        // Fetch live data from data.gov.in with progressive query fallback
        var rawDoc = await FetchFromDataGovApiAsync(apiKey, cleanState, cleanDistrict, cleanCommodity, clampedLimit);

        var filteredRoot = FilterAndNormalizeRecords(rawDoc, cleanState, cleanDistrict, cleanCommodity, clampedLimit, clampedOffset);

        // Cache valid responses for 15 minutes
        _cache.Set(cacheKey, filteredRoot, TimeSpan.FromMinutes(15));
        return filteredRoot;
    }

    private async Task<JsonDocument> FetchFromDataGovApiAsync(
        string apiKey,
        string? state,
        string? district,
        string? commodity,
        int requestedLimit)
    {
        var attempts = new List<string>();

        // Build list of target state variations if state is provided
        var stateVariations = new List<string>();
        if (!string.IsNullOrWhiteSpace(state))
        {
            var s = state.Trim();
            stateVariations.Add(s);
            if (s.Equals("Kerala", StringComparison.OrdinalIgnoreCase)) stateVariations.Add("Keralam");
            if (s.Equals("Keralam", StringComparison.OrdinalIgnoreCase)) stateVariations.Add("Kerala");
            if (s.Equals("Odisha", StringComparison.OrdinalIgnoreCase)) stateVariations.Add("Orissa");
            if (s.Equals("Orissa", StringComparison.OrdinalIgnoreCase)) stateVariations.Add("Odisha");
            if (s.Equals("Puducherry", StringComparison.OrdinalIgnoreCase)) stateVariations.Add("Pondicherry");
        }

        var resourceIds = new[] { PrimaryResourceId, SecondaryResourceId };

        foreach (var resId in resourceIds)
        {
            foreach (var stVar in stateVariations.Distinct())
            {
                // Attempt 1: State + District + Commodity
                if (!string.IsNullOrWhiteSpace(district) && !string.IsNullOrWhiteSpace(commodity))
                {
                    attempts.Add($"https://api.data.gov.in/resource/{resId}?api-key={Uri.EscapeDataString(apiKey)}&format=json&limit=200&filters[state]={Uri.EscapeDataString(stVar)}&filters[district]={Uri.EscapeDataString(district.Trim())}&filters[commodity]={Uri.EscapeDataString(commodity.Trim())}");
                }

                // Attempt 2: State + Commodity
                if (!string.IsNullOrWhiteSpace(commodity))
                {
                    attempts.Add($"https://api.data.gov.in/resource/{resId}?api-key={Uri.EscapeDataString(apiKey)}&format=json&limit=200&filters[state]={Uri.EscapeDataString(stVar)}&filters[commodity]={Uri.EscapeDataString(commodity.Trim())}");
                }

                // Attempt 3: State + District
                if (!string.IsNullOrWhiteSpace(district))
                {
                    attempts.Add($"https://api.data.gov.in/resource/{resId}?api-key={Uri.EscapeDataString(apiKey)}&format=json&limit=200&filters[state]={Uri.EscapeDataString(stVar)}&filters[district]={Uri.EscapeDataString(district.Trim())}");
                }

                // Attempt 4: State only
                attempts.Add($"https://api.data.gov.in/resource/{resId}?api-key={Uri.EscapeDataString(apiKey)}&format=json&limit=500&filters[state]={Uri.EscapeDataString(stVar)}");
            }

            // If no state provided, try commodity-only or broad query
            if (stateVariations.Count == 0 && !string.IsNullOrWhiteSpace(commodity))
            {
                attempts.Add($"https://api.data.gov.in/resource/{resId}?api-key={Uri.EscapeDataString(apiKey)}&format=json&limit=300&filters[commodity]={Uri.EscapeDataString(commodity.Trim())}");
            }

            attempts.Add($"https://api.data.gov.in/resource/{resId}?api-key={Uri.EscapeDataString(apiKey)}&format=json&limit=1000");
        }

        Exception? lastException = null;

        foreach (var url in attempts.Distinct())
        {
            var maskedUrl = url.Replace(apiKey, "[API_KEY_HIDDEN]");
            _logger.LogInformation("[MANDI_SERVICE] Requesting data.gov.in endpoint: {Url}", maskedUrl);

            try
            {
                var response = await _httpClient.GetAsync(url);

                if (!response.IsSuccessStatusCode)
                {
                    string errorBody = await response.Content.ReadAsStringAsync();
                    _logger.LogWarning("[MANDI_SERVICE] data.gov.in returned HTTP {StatusCode}: {ErrorBody}", (int)response.StatusCode, errorBody);

                    if (response.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
                    {
                        throw new HttpRequestException("Rate limit exceeded from data.gov.in API. Please try again shortly.");
                    }

                    continue;
                }

                var jsonContent = await response.Content.ReadAsStringAsync();
                var doc = JsonDocument.Parse(jsonContent);

                if (doc.RootElement.TryGetProperty("records", out var recs) && recs.ValueKind == JsonValueKind.Array && recs.GetArrayLength() > 0)
                {
                    _logger.LogInformation("[MANDI_SERVICE] Received {Count} raw records from data.gov.in", recs.GetArrayLength());
                    return doc;
                }

                _logger.LogInformation("[MANDI_SERVICE] Query returned 0 records, trying fallback request strategy...");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[MANDI_SERVICE] Error querying data.gov.in endpoint: {Url}", maskedUrl);
                lastException = ex;
            }
        }

        if (lastException != null)
        {
            throw lastException;
        }

        return JsonDocument.Parse("{\"status\":\"ok\",\"total\":0,\"count\":0,\"limit\":100,\"offset\":0,\"records\":[]}");
    }

    private JsonElement FilterAndNormalizeRecords(
        JsonDocument doc,
        string? targetState,
        string? targetDistrict,
        string? targetCommodity,
        int limit,
        int offset)
    {
        var root = doc.RootElement;
        if (!root.TryGetProperty("records", out var recsElement) || recsElement.ValueKind != JsonValueKind.Array)
        {
            return root.Clone();
        }

        var allRecords = recsElement.EnumerateArray().ToList();

        // Perform strict normalized filtering
        var filteredRecords = allRecords.Where(r =>
        {
            var st = GetStringProperty(r, "State", "state", "state_name", "stateName");
            var dt = GetStringProperty(r, "District", "district", "district_name", "districtName");
            var cm = GetStringProperty(r, "Commodity", "commodity", "commodity_name", "crop", "product");

            if (!IsNormalizedMatch(st, targetState)) return false;
            if (!IsNormalizedMatch(dt, targetDistrict)) return false;
            if (!IsCommodityMatch(cm, targetCommodity)) return false;

            return true;
        }).ToList();

        var pagedRecords = filteredRecords.Skip(offset).Take(limit).ToList();

        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream))
        {
            writer.WriteStartObject();
            writer.WriteString("status", "ok");
            writer.WriteNumber("total", filteredRecords.Count);
            writer.WriteNumber("count", pagedRecords.Count);
            writer.WriteNumber("limit", limit);
            writer.WriteNumber("offset", offset);

            writer.WritePropertyName("records");
            writer.WriteStartArray();
            foreach (var rec in pagedRecords)
            {
                rec.WriteTo(writer);
            }
            writer.WriteEndArray();
            writer.WriteEndObject();
        }

        var filteredDoc = JsonDocument.Parse(stream.ToArray());
        return filteredDoc.RootElement.Clone();
    }

    private static string? GetStringProperty(JsonElement element, params string[] propertyNames)
    {
        foreach (var name in propertyNames)
        {
            if (element.TryGetProperty(name, out var prop) && prop.ValueKind == JsonValueKind.String)
            {
                var val = prop.GetString();
                if (!string.IsNullOrWhiteSpace(val)) return val;
            }
        }
        return null;
    }

    private static bool IsNormalizedMatch(string? value, string? target)
    {
        if (string.IsNullOrWhiteSpace(target) || target.Equals("All", StringComparison.OrdinalIgnoreCase)) return true;
        if (string.IsNullOrWhiteSpace(value)) return false;

        var cleanVal = NormalizeString(value);
        var cleanTarget = NormalizeString(target);

        if (cleanVal == cleanTarget) return true;
        if (cleanVal.Contains(cleanTarget) || cleanTarget.Contains(cleanVal)) return true;

        // State Aliases
        var stateAliases = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase)
        {
            ["Kerala"] = new[] { "kerala", "keralam" },
            ["Keralam"] = new[] { "kerala", "keralam" },
            ["Odisha"] = new[] { "odisha", "orissa" },
            ["Orissa"] = new[] { "odisha", "orissa" },
            ["Puducherry"] = new[] { "puducherry", "pondicherry" },
            ["Pondicherry"] = new[] { "puducherry", "pondicherry" },
        };

        foreach (var kvp in stateAliases)
        {
            var keyNorm = NormalizeString(kvp.Key);
            if (cleanTarget == keyNorm || cleanTarget.Contains(keyNorm) || keyNorm.Contains(cleanTarget))
            {
                foreach (var alias in kvp.Value)
                {
                    var aliasNorm = NormalizeString(alias);
                    if (cleanVal == aliasNorm || cleanVal.Contains(aliasNorm) || aliasNorm.Contains(cleanVal))
                    {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    private static bool IsCommodityMatch(string? recordCommodity, string? targetCommodity)
    {
        if (string.IsNullOrWhiteSpace(targetCommodity) || targetCommodity.Equals("All", StringComparison.OrdinalIgnoreCase)) return true;
        if (string.IsNullOrWhiteSpace(recordCommodity)) return false;

        var valNorm = NormalizeString(recordCommodity);
        var targetNorm = NormalizeString(targetCommodity);

        if (valNorm == targetNorm) return true;
        if (valNorm.Contains(targetNorm) || targetNorm.Contains(valNorm)) return true;

        // Alias / Synonym mappings
        var synonyms = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase)
        {
            ["tomato"] = new[] { "tomato", "tamato" },
            ["potato"] = new[] { "potato", "aloo" },
            ["onion"] = new[] { "onion", "pyaz" },
            ["rice"] = new[] { "rice", "paddy", "paddycommon", "bpt", "dhan" },
            ["paddy"] = new[] { "rice", "paddy", "paddycommon", "bpt", "dhan" },
            ["wheat"] = new[] { "wheat", "gehun" },
            ["banana"] = new[] { "banana", "bananaripe", "bananagreen" },
            ["banana - ripe"] = new[] { "banana", "bananaripe" },
            ["banana - green"] = new[] { "banana", "bananagreen" },
            ["chilli"] = new[] { "chilli", "chillies", "greenchilli", "chili", "chilired", "drychillies", "capsicum" },
            ["groundnut"] = new[] { "groundnut", "groundnutseed", "peanut" },
            ["ginger"] = new[] { "ginger", "gingergreen", "gingerdry" },
            ["brinjal"] = new[] { "brinjal", "eggplant" },
            ["maize"] = new[] { "maize", "corn" },
            ["cucumber"] = new[] { "cucumbar", "cucumbarkheera", "cucumber", "kheera" },
            ["okra"] = new[] { "bhindiladiesfinger", "bhindi", "ladiesfinger" },
            ["ladies finger"] = new[] { "bhindiladiesfinger", "bhindi", "ladiesfinger" },
            ["cauliflower"] = new[] { "cauliflower" },
            ["cabbage"] = new[] { "cabbage" },
            ["carrot"] = new[] { "carrot" },
            ["apple"] = new[] { "apple" },
            ["tur"] = new[] { "redgramarharturwhole", "tur", "arhar" },
            ["arhar"] = new[] { "redgramarharturwhole", "tur", "arhar" },
            ["urad"] = new[] { "blackgramurdbeanswhole", "urad", "urd" },
            ["moong"] = new[] { "greengrammoongwhole", "moong" },
            ["chana"] = new[] { "bengalgramgramwhole", "chana", "gram" },
        };

        foreach (var kvp in synonyms)
        {
            var keyNorm = NormalizeString(kvp.Key);
            if (targetNorm == keyNorm || targetNorm.Contains(keyNorm) || keyNorm.Contains(targetNorm))
            {
                foreach (var syn in kvp.Value)
                {
                    if (valNorm.Contains(syn)) return true;
                }
            }
        }

        return false;
    }

    private static string NormalizeString(string input)
    {
        if (string.IsNullOrWhiteSpace(input)) return "";
        var lowered = input.ToLowerInvariant();
        var cleaned = Regex.Replace(lowered, @"[^a-z0-9]", "");
        return cleaned.Trim();
    }
}