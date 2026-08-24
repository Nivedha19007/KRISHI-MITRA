using KrishiMitra.OtpApi.Services;
using Microsoft.AspNetCore.Mvc;

namespace KrishiMitra.OtpApi.Controllers;

[ApiController]
[Route("api/mandi")]
public class MandiController : ControllerBase
{
    private readonly IMandiService _mandiService;
    private readonly ILogger<MandiController> _logger;

    public MandiController(IMandiService mandiService, ILogger<MandiController> logger)
    {
        _mandiService = mandiService;
        _logger = logger;
    }

    [HttpGet("prices")]
    public async Task<IActionResult> GetPrices(
        [FromQuery] string? state,
        [FromQuery] string? district,
        [FromQuery] string? commodity,
        [FromQuery] int limit = 100,
        [FromQuery] int offset = 0)
    {
        try
        {
            _logger.LogInformation("[MANDI_CONTROLLER] GET /api/mandi/prices requested with State={State}, District={District}, Commodity={Commodity}, Limit={Limit}, Offset={Offset}", state, district, commodity, limit, offset);

            var result = await _mandiService.GetPricesAsync(
                state,
                district,
                commodity,
                limit,
                offset);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[MANDI_CONTROLLER] Error processing Mandi prices request for State={State}, District={District}, Commodity={Commodity}", state, district, commodity);
            return StatusCode(500, new
            {
                error = "Unable to fetch mandi prices.",
                message = ex.Message
            });
        }
    }
}