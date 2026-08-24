using KrishiMitra.OtpApi.Models;
using KrishiMitra.OtpApi.Services;
using Microsoft.AspNetCore.Mvc;

namespace KrishiMitra.OtpApi.Controllers;

[ApiController]
[Route("api/otp")]
public class OtpController : ControllerBase
{
    private readonly IOtpService _otpService;
    private readonly IFirebaseAuthService _firebaseAuthService;
    private readonly ILogger<OtpController> _logger;

    public OtpController(IOtpService otpService, IFirebaseAuthService firebaseAuthService, ILogger<OtpController> logger)
    {
        _otpService = otpService;
        _firebaseAuthService = firebaseAuthService;
        _logger = logger;
    }

    [HttpPost("send")]
    public async Task<IActionResult> SendOtp([FromBody] SendOtpRequest request, CancellationToken ct)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.PhoneNumber))
        {
            return BadRequest(new ApiErrorResponse { Message = "Phone number is required." });
        }

        var result = await _otpService.SendOtpAsync(request.PhoneNumber, ct);

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, new ApiErrorResponse { Message = result.Message });
        }

        return Ok(new SendOtpResponse
        {
            Success = true,
            Message = result.Message,
            ExpirySeconds = result.ExpirySeconds,
            CooldownSeconds = result.CooldownSeconds
        });
    }

    [HttpPost("verify")]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequest request, CancellationToken ct)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.PhoneNumber) || string.IsNullOrWhiteSpace(request.Otp))
        {
            return BadRequest(new ApiErrorResponse { Message = "Phone number and OTP code are required." });
        }

        var result = await _otpService.VerifyOtpAsync(request.PhoneNumber, request.Otp, ct);

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, new ApiErrorResponse { Message = result.Message });
        }

        // Generate Firebase Custom Token after successful OTP verification
        string? customToken = await _firebaseAuthService.CreateCustomTokenAsync(request.PhoneNumber, ct);

        bool containsCustomToken = !string.IsNullOrEmpty(customToken);
        _logger.LogInformation("[DIAGNOSTIC 6] API response contains customToken: {ContainsCustomToken}", containsCustomToken);

        return Ok(new VerifyOtpResponse
        {
            Success = true,
            Message = result.Message,
            CustomToken = customToken
        });
    }
}
