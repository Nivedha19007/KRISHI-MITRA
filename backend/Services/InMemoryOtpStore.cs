using System.Collections.Concurrent;

namespace KrishiMitra.OtpApi.Services;

/// <summary>
/// =========================================================================
/// [DEVELOPMENT ONLY] In-Memory OTP Store
/// =========================================================================
/// WARNING: Render instances can restart, scale, or go idle, which will wipe
/// in-memory state. For production, replace this implementation with a
/// persistent store such as Redis (RedisOtpStore implementing IOtpStore).
/// =========================================================================
/// </summary>
public class InMemoryOtpStore : IOtpStore
{
    private readonly ConcurrentDictionary<string, OtpRecord> _store = new();

    public Task SaveOtpAsync(OtpRecord record, CancellationToken ct = default)
    {
        _store[record.PhoneNumber] = record;
        return Task.CompletedTask;
    }

    public Task<OtpRecord?> GetOtpAsync(string phoneNumber, CancellationToken ct = default)
    {
        _store.TryGetValue(phoneNumber, out var record);
        return Task.FromResult(record);
    }

    public Task UpdateOtpAsync(OtpRecord record, CancellationToken ct = default)
    {
        _store[record.PhoneNumber] = record;
        return Task.CompletedTask;
    }

    public Task DeleteOtpAsync(string phoneNumber, CancellationToken ct = default)
    {
        _store.TryRemove(phoneNumber, out _);
        return Task.CompletedTask;
    }
}
