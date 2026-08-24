namespace KrishiMitra.OtpApi.Services;

public interface IFirebaseAuthService
{
    Task<string?> CreateCustomTokenAsync(string rawPhoneNumber, CancellationToken ct = default);
}
