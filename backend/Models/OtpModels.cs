namespace KrishiMitra.OtpApi.Models;

public class HealthResponse
{
    public string Status { get; set; } = "ok";
}

public class SendOtpRequest
{
    public string PhoneNumber { get; set; } = string.Empty;
}

public class SendOtpResponse
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public int ExpirySeconds { get; set; } = 300;
    public int CooldownSeconds { get; set; } = 60;
}

public class VerifyOtpRequest
{
    public string PhoneNumber { get; set; } = string.Empty;
    public string Otp { get; set; } = string.Empty;
}

public class VerifyOtpResponse
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public string? CustomToken { get; set; }
}

public class ApiErrorResponse
{
    public bool Success { get; set; } = false;
    public string Message { get; set; } = string.Empty;
}
