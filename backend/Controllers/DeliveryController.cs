using KrishiMitra.OtpApi.Models;
using KrishiMitra.OtpApi.Services;
using Microsoft.AspNetCore.Mvc;

namespace KrishiMitra.OtpApi.Controllers;

[ApiController]
[Route("api/delivery")]
public class DeliveryController : ControllerBase
{
    private readonly IDeliveryService _deliveryService;
    private readonly ILogger<DeliveryController> _logger;

    public DeliveryController(IDeliveryService deliveryService, ILogger<DeliveryController> logger)
    {
        _deliveryService = deliveryService;
        _logger = logger;
    }

    [HttpPost("calculate")]
    public IActionResult CalculateDeliveryCharge([FromBody] CalculateDeliveryRequest request)
    {
        try
        {
            _logger.LogInformation("[DELIVERY_CONTROLLER] POST /api/delivery/calculate requested for Pickup='{Pickup}', Delivery='{Delivery}'", request.PickupAddress, request.DeliveryAddress);
            var result = _deliveryService.CalculateDeliveryCharge(request);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[DELIVERY_CONTROLLER] Error calculating delivery charge");
            return StatusCode(500, new { status = "error", message = ex.Message });
        }
    }

    [HttpPost("validate")]
    public IActionResult ValidateOrderTotal([FromBody] ValidateOrderRequest request)
    {
        try
        {
            _logger.LogInformation("[DELIVERY_CONTROLLER] POST /api/delivery/validate requested for ClaimedTotal={Total}", request.ClaimedFinalTotal);
            var result = _deliveryService.ValidateOrderTotal(request);
            if (!result.IsValid)
            {
                return BadRequest(result);
            }
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[DELIVERY_CONTROLLER] Error validating order total");
            return StatusCode(500, new { status = "error", message = ex.Message });
        }
    }
}
