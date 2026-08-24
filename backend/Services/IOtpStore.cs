namespace KrishiMitra.OtpApi.Services;

public class OtpRecord
{
    public string PhoneNumber { get; set; } = string.Empty;
    public string OtpCode { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset ExpiresAt { get; set; }
    public int VerificationAttempts { get; set; }
    public DateTimeOffset LastRequestedAt { get; set; }
    public int RequestCountInWindow { get; set; }
    public DateTimeOffset WindowStartAt { get; set; }
}

/// <summary>
/// Abstraction for OTP storage.
/// Allows swapping InMemory implementation with Redis/DistributedCache for production readiness.
/// </summary>
public interface IOtpStore
{
    Task SaveOtpAsync(OtpRecord record, CancellationToken ct = default);
    Task<OtpRecord?> GetOtpAsync(string phoneNumber, CancellationToken ct = default);
    Task UpdateOtpAsync(OtpRecord record, CancellationToken ct = default);
    Task DeleteOtpAsync(string phoneNumber, CancellationToken ct = default);
}
