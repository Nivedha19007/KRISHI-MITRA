namespace KrishiMitra.OtpApi.Services;

public interface ISmsService
{
    Task<bool> SendSmsAsync(string phoneNumber, string otpCode, CancellationToken ct = default);
}
