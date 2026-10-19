namespace KrishiMitra.OtpApi.Services;

public class SendOtpResult
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public int ExpirySeconds { get; set; } = 300;
    public int CooldownSeconds { get; set; } = 60;
    public int StatusCode { get; set; } = 200;
}

public class VerifyOtpResult
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public int StatusCode { get; set; } = 200;
}

public interface IOtpService
{
    Task<SendOtpResult> SendOtpAsync(string rawPhoneNumber, CancellationToken ct = default);
    Task<VerifyOtpResult> VerifyOtpAsync(string rawPhoneNumber, string otpCode, CancellationToken ct = default);
    Task<SendOtpResult> SendEmailOtpAsync(string rawEmail, CancellationToken ct = default);
    Task<VerifyOtpResult> VerifyEmailOtpAsync(string rawEmail, string otpCode, CancellationToken ct = default);
}
