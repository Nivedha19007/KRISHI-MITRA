using FirebaseAdmin;
using FirebaseAdmin.Auth;
using KrishiMitra.OtpApi.Utils;

namespace KrishiMitra.OtpApi.Services;

public class FirebaseAuthService : IFirebaseAuthService
{
    private readonly ILogger<FirebaseAuthService> _logger;

    public FirebaseAuthService(ILogger<FirebaseAuthService> logger)
    {
        _logger = logger;
    }

    public async Task<string?> CreateCustomTokenAsync(string rawPhoneNumber, CancellationToken ct = default)
    {
        if (FirebaseApp.DefaultInstance == null)
        {
            _logger.LogWarning("[FIREBASE_AUTH] FirebaseAdmin App is not initialized. Skipping Custom Token generation.");
            _logger.LogInformation("[DIAGNOSTIC 3] FirebaseAuth.GetUserAsync(uid) found existing user: FALSE (FirebaseApp is null)");
            _logger.LogInformation("[DIAGNOSTIC 4] CreateUserAsync(uid) created new user: FALSE (FirebaseApp is null)");
            _logger.LogInformation("[DIAGNOSTIC 5] CreateCustomTokenAsync(uid) succeeded: FALSE (FirebaseApp is null)");
            return null;
        }

        try
        {
            string normalizedPhone = PhoneNumberUtils.Normalize(rawPhoneNumber);
            string sanitizedDigits = new string(normalizedPhone.Where(char.IsDigit).ToArray());
            string uid = $"phone_{sanitizedDigits}";

            _logger.LogInformation("[DIAGNOSTIC 1] Normalized phone number: {NormalizedPhone}", normalizedPhone);
            _logger.LogInformation("[DIAGNOSTIC 2] Deterministic Firebase UID being used: {Uid}", uid);

            UserRecord userRecord;
            try
            {
                userRecord = await FirebaseAuth.DefaultInstance.GetUserAsync(uid, ct);
                _logger.LogInformation("[DIAGNOSTIC 3] FirebaseAuth.GetUserAsync(uid) found existing user: TRUE (UID: {Uid})", userRecord.Uid);
                _logger.LogInformation("[DIAGNOSTIC 4] CreateUserAsync(uid) created new user: FALSE (User already existed)");
            }
            catch (FirebaseAuthException ex) when (ex.AuthErrorCode == AuthErrorCode.UserNotFound)
            {
                _logger.LogInformation("[DIAGNOSTIC 3] FirebaseAuth.GetUserAsync(uid) found existing user: FALSE");
                _logger.LogInformation("[FIREBASE_AUTH] User not found. Creating new Firebase Auth user for UID: {Uid}...", uid);
                var args = new UserRecordArgs
                {
                    Uid = uid,
                    PhoneNumber = normalizedPhone,
                    Disabled = false
                };
                userRecord = await FirebaseAuth.DefaultInstance.CreateUserAsync(args, ct);
                _logger.LogInformation("[DIAGNOSTIC 4] CreateUserAsync(uid) created new user: TRUE (UID: {Uid})", userRecord.Uid);
            }

            string customToken = await FirebaseAuth.DefaultInstance.CreateCustomTokenAsync(userRecord.Uid, ct);
            bool tokenSucceeded = !string.IsNullOrEmpty(customToken);
            _logger.LogInformation("[DIAGNOSTIC 5] CreateCustomTokenAsync(uid) succeeded: {Succeeded}", tokenSucceeded);
            return customToken;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[FIREBASE_AUTH] Failed to generate custom token for phone {PhoneNumber}", rawPhoneNumber);
            _logger.LogInformation("[DIAGNOSTIC 5] CreateCustomTokenAsync(uid) succeeded: FALSE (Exception: {Message})", ex.Message);
            return null; // Graceful fallback if Firebase Admin SDK encounters an error
        }
    }
}
