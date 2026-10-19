using System.Security.Cryptography;
using KrishiMitra.OtpApi.Utils;

namespace KrishiMitra.OtpApi.Services;

public class OtpService : IOtpService
{
    private readonly IOtpStore _otpStore;
    private readonly ISmsService _smsService;
    private readonly ILogger<OtpService> _logger;

    private const int OtpExpiryMinutes = 5;
    private const int ResendCooldownSeconds = 60;
    private const int MaxVerificationAttempts = 5;
    private const int MaxRequestsPerHour = 5;

    public OtpService(IOtpStore otpStore, ISmsService smsService, ILogger<OtpService> logger)
    {
        _otpStore = otpStore;
        _smsService = smsService;
        _logger = logger;
    }



    public async Task<SendOtpResult> SendOtpAsync(string rawPhoneNumber, CancellationToken ct = default)
    {
        string normalizedPhone = PhoneNumberUtils.Normalize(rawPhoneNumber);
        _logger.LogInformation("[OTP] Received OTP request for {PhoneNumber}", normalizedPhone);

        if (!PhoneNumberUtils.IsValidE164(normalizedPhone))
        {
            return new SendOtpResult
            {
                Success = false,
                Message = "Invalid phone number format. Provide international format (e.g. +919876543210).",
                StatusCode = 400
            };
        }

        var now = DateTimeOffset.UtcNow;
        var existingRecord = await _otpStore.GetOtpAsync(normalizedPhone, ct);

        // 1. Resend Cooldown Rate Limit
        if (existingRecord != null)
        {
            var secondsSinceLastRequest = (now - existingRecord.LastRequestedAt).TotalSeconds;
            if (secondsSinceLastRequest < ResendCooldownSeconds)
            {
                int retryAfter = ResendCooldownSeconds - (int)secondsSinceLastRequest;
                return new SendOtpResult
                {
                    Success = false,
                    Message = $"Please wait {retryAfter} seconds before requesting another OTP.",
                    CooldownSeconds = retryAfter,
                    StatusCode = 429
                };
            }

            // 2. Hourly Rate Limit
            var windowAge = (now - existingRecord.WindowStartAt).TotalHours;
            int currentWindowCount = windowAge >= 1 ? 0 : existingRecord.RequestCountInWindow;

            if (currentWindowCount >= MaxRequestsPerHour)
            {
                return new SendOtpResult
                {
                    Success = false,
                    Message = "Too many OTP requests for this phone number. Please try again in an hour.",
                    StatusCode = 429
                };
            }
        }

        // 3. Server-side Cryptographically Secure 6-digit OTP Generation
        string otpCode = RandomNumberGenerator.GetInt32(100000, 1000000).ToString("D6");
        _logger.LogInformation("[OTP] Generated demo OTP");

        int requestCount = existingRecord == null || (now - existingRecord.WindowStartAt).TotalHours >= 1
            ? 1
            : existingRecord.RequestCountInWindow + 1;

        DateTimeOffset windowStart = existingRecord == null || (now - existingRecord.WindowStartAt).TotalHours >= 1
            ? now
            : existingRecord.WindowStartAt;

        var newRecord = new OtpRecord
        {
            PhoneNumber = normalizedPhone,
            OtpCode = otpCode,
            CreatedAt = now,
            ExpiresAt = now.AddMinutes(OtpExpiryMinutes),
            VerificationAttempts = 0,
            LastRequestedAt = now,
            RequestCountInWindow = requestCount,
            WindowStartAt = windowStart
        };

        await _otpStore.SaveOtpAsync(newRecord, ct);

        // 4. Dispatch via SMS Service (Demo logs, Real sends SMS)
        bool smsSent = await _smsService.SendSmsAsync(normalizedPhone, otpCode, ct);
        if (!smsSent)
        {
            return new SendOtpResult
            {
                Success = false,
                Message = "Failed to send SMS. Please try again later.",
                StatusCode = 500
            };
        }

        return new SendOtpResult
        {
            Success = true,
            Message = "OTP sent successfully.",
            ExpirySeconds = OtpExpiryMinutes * 60,
            CooldownSeconds = ResendCooldownSeconds,
            StatusCode = 200
        };
    }

    public async Task<VerifyOtpResult> VerifyOtpAsync(string rawPhoneNumber, string otpCode, CancellationToken ct = default)
    {
        string normalizedPhone = PhoneNumberUtils.Normalize(rawPhoneNumber);

        if (!PhoneNumberUtils.IsValidE164(normalizedPhone))
        {
            return new VerifyOtpResult
            {
                Success = false,
                Message = "Invalid phone number format.",
                StatusCode = 400
            };
        }

        if (string.IsNullOrWhiteSpace(otpCode) || otpCode.Trim().Length != 6)
        {
            return new VerifyOtpResult
            {
                Success = false,
                Message = "OTP must be a 6-digit number.",
                StatusCode = 400
            };
        }

        var record = await _otpStore.GetOtpAsync(normalizedPhone, ct);
        if (record == null)
        {
            return new VerifyOtpResult
            {
                Success = false,
                Message = "No OTP request found for this phone number. Please request a new OTP.",
                StatusCode = 400
            };
        }

        var now = DateTimeOffset.UtcNow;

        // 1. Expiration check
        if (now > record.ExpiresAt)
        {
            await _otpStore.DeleteOtpAsync(normalizedPhone, ct);
            return new VerifyOtpResult
            {
                Success = false,
                Message = "OTP has expired. Please request a new OTP.",
                StatusCode = 400
            };
        }

        // 2. Attempt count check
        if (record.VerificationAttempts >= MaxVerificationAttempts)
        {
            await _otpStore.DeleteOtpAsync(normalizedPhone, ct);
            return new VerifyOtpResult
            {
                Success = false,
                Message = "Maximum verification attempts exceeded. Please request a new OTP.",
                StatusCode = 400
            };
        }

        // 3. Verify Code
        bool isMatch = CryptographicOperations.FixedTimeEquals(
            System.Text.Encoding.UTF8.GetBytes(record.OtpCode),
            System.Text.Encoding.UTF8.GetBytes(otpCode.Trim())
        );

        if (isMatch)
        {
            // OTP verified! Invalidate immediately so it cannot be reused
            await _otpStore.DeleteOtpAsync(normalizedPhone, ct);
            _logger.LogInformation("OTP successfully verified for {PhoneNumber}", normalizedPhone);

            return new VerifyOtpResult
            {
                Success = true,
                Message = "OTP verified successfully.",
                StatusCode = 200
            };
        }

        // Incorrect OTP: increment attempt count
        record.VerificationAttempts++;
        await _otpStore.UpdateOtpAsync(record, ct);

        int remainingAttempts = MaxVerificationAttempts - record.VerificationAttempts;
        if (remainingAttempts <= 0)
        {
            await _otpStore.DeleteOtpAsync(normalizedPhone, ct);
            return new VerifyOtpResult
            {
                Success = false,
                Message = "Maximum verification attempts exceeded. Please request a new OTP.",
                StatusCode = 400
            };
        }

        return new VerifyOtpResult
        {
            Success = false,
            Message = $"Invalid OTP code. {remainingAttempts} attempt(s) remaining.",
            StatusCode = 400
        };
    }

    public async Task<SendOtpResult> SendEmailOtpAsync(string rawEmail, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(rawEmail) || !rawEmail.Contains("@"))
        {
            return new SendOtpResult
            {
                Success = false,
                Message = "Invalid registered email address format.",
                StatusCode = 400
            };
        }

        string normalizedEmail = rawEmail.Trim().ToLowerInvariant();
        _logger.LogInformation("[EMAIL_OTP] Received Email OTP request for {Email}", normalizedEmail);

        var now = DateTimeOffset.UtcNow;
        var existingRecord = await _otpStore.GetOtpAsync(normalizedEmail, ct);

        if (existingRecord != null)
        {
            var secondsSinceLastRequest = (now - existingRecord.LastRequestedAt).TotalSeconds;
            if (secondsSinceLastRequest < ResendCooldownSeconds)
            {
                int retryAfter = ResendCooldownSeconds - (int)secondsSinceLastRequest;
                return new SendOtpResult
                {
                    Success = false,
                    Message = $"Please wait {retryAfter} seconds before requesting another OTP.",
                    CooldownSeconds = retryAfter,
                    StatusCode = 429
                };
            }
        }

        string otpCode = RandomNumberGenerator.GetInt32(100000, 1000000).ToString("D6");

        var newRecord = new OtpRecord
        {
            PhoneNumber = normalizedEmail,
            OtpCode = otpCode,
            CreatedAt = now,
            ExpiresAt = now.AddMinutes(OtpExpiryMinutes),
            VerificationAttempts = 0,
            LastRequestedAt = now,
            RequestCountInWindow = 1,
            WindowStartAt = now
        };

        await _otpStore.SaveOtpAsync(newRecord, ct);

        Console.WriteLine($"\n=================================================================");
        Console.WriteLine($"[DEMO EMAIL OTP MODE] Verification OTP for {normalizedEmail} is: {otpCode}");
        Console.WriteLine($"=================================================================\n");
        _logger.LogInformation("=================================================================");
        _logger.LogInformation("[DEMO EMAIL OTP MODE] Verification OTP for {Email} is: {OtpCode}", normalizedEmail, otpCode);
        _logger.LogInformation("=================================================================");

        return new SendOtpResult
        {
            Success = true,
            Message = $"OTP sent successfully to registered email: {normalizedEmail}",
            ExpirySeconds = OtpExpiryMinutes * 60,
            CooldownSeconds = ResendCooldownSeconds,
            StatusCode = 200
        };
    }



    public async Task<VerifyOtpResult> VerifyEmailOtpAsync(string rawEmail, string otpCode, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(rawEmail) || !rawEmail.Contains("@"))
        {
            return new VerifyOtpResult
            {
                Success = false,
                Message = "Invalid email format.",
                StatusCode = 400
            };
        }

        if (string.IsNullOrWhiteSpace(otpCode) || otpCode.Trim().Length != 6)
        {
            return new VerifyOtpResult
            {
                Success = false,
                Message = "OTP must be a 6-digit number.",
                StatusCode = 400
            };
        }

        string normalizedEmail = rawEmail.Trim().ToLowerInvariant();
        var record = await _otpStore.GetOtpAsync(normalizedEmail, ct);

        if (record == null)
        {
            return new VerifyOtpResult
            {
                Success = false,
                Message = "No OTP request found for this email. Please request a new OTP.",
                StatusCode = 400
            };
        }

        var now = DateTimeOffset.UtcNow;
        if (now > record.ExpiresAt)
        {
            await _otpStore.DeleteOtpAsync(normalizedEmail, ct);
            return new VerifyOtpResult
            {
                Success = false,
                Message = "Email OTP has expired. Please request a new OTP.",
                StatusCode = 400
            };
        }

        if (record.VerificationAttempts >= MaxVerificationAttempts)
        {
            await _otpStore.DeleteOtpAsync(normalizedEmail, ct);
            return new VerifyOtpResult
            {
                Success = false,
                Message = "Maximum verification attempts exceeded. Please request a new OTP.",
                StatusCode = 400
            };
        }

        bool isMatch = CryptographicOperations.FixedTimeEquals(
            System.Text.Encoding.UTF8.GetBytes(record.OtpCode),
            System.Text.Encoding.UTF8.GetBytes(otpCode.Trim())
        );

        if (isMatch)
        {
            await _otpStore.DeleteOtpAsync(normalizedEmail, ct);
            _logger.LogInformation("Email OTP successfully verified for {Email}", normalizedEmail);
            return new VerifyOtpResult
            {
                Success = true,
                Message = "Email OTP verified successfully.",
                StatusCode = 200
            };
        }

        record.VerificationAttempts++;
        await _otpStore.UpdateOtpAsync(record, ct);

        int remainingAttempts = MaxVerificationAttempts - record.VerificationAttempts;
        return new VerifyOtpResult
        {
            Success = false,
            Message = $"Invalid Email OTP code. {remainingAttempts} attempt(s) remaining.",
            StatusCode = 400
        };
    }
}
