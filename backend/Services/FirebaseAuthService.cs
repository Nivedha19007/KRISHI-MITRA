using FirebaseAdmin;
using FirebaseAdmin.Auth;
using KrishiMitra.OtpApi.Utils;
using System.Text.RegularExpressions;

namespace KrishiMitra.OtpApi.Services;

public class FirebaseAuthService : IFirebaseAuthService
{
    private readonly ILogger<FirebaseAuthService> _logger;

    public FirebaseAuthService(ILogger<FirebaseAuthService> logger)
    {
        _logger = logger;
    }

    public async Task<string?> CreateCustomTokenAsync(string rawIdentifier, CancellationToken ct = default)
    {
        if (FirebaseApp.DefaultInstance == null)
        {
            _logger.LogWarning("[FIREBASE_AUTH] FirebaseAdmin App is not initialized. Skipping Custom Token generation.");
            return null;
        }

        if (string.IsNullOrWhiteSpace(rawIdentifier))
        {
            _logger.LogWarning("[FIREBASE_AUTH] Empty rawIdentifier provided for custom token generation.");
            return null;
        }

        string trimmed = rawIdentifier.Trim();
        bool isEmail = trimmed.Contains("@");

        try
        {
            UserRecord userRecord;

            if (isEmail)
            {
                string normalizedEmail = trimmed.ToLowerInvariant();
                string sanitizedEmailPart = Regex.Replace(normalizedEmail, @"[^a-zA-Z0-9_-]", "_");
                string uid = $"email_{sanitizedEmailPart}";
                if (uid.Length > 128) uid = uid.Substring(0, 128);

                _logger.LogInformation("[FIREBASE_AUTH] Processing Email Custom Token for {Email} (UID: {Uid})", normalizedEmail, uid);

                try
                {
                    userRecord = await FirebaseAuth.DefaultInstance.GetUserAsync(uid, ct);
                    _logger.LogInformation("[FIREBASE_AUTH] Found existing user by UID: {Uid}", userRecord.Uid);
                }
                catch (FirebaseAuthException ex) when (ex.AuthErrorCode == AuthErrorCode.UserNotFound)
                {
                    try
                    {
                        userRecord = await FirebaseAuth.DefaultInstance.GetUserByEmailAsync(normalizedEmail, ct);
                        _logger.LogInformation("[FIREBASE_AUTH] Found existing user by Email: {Email} (UID: {Uid})", normalizedEmail, userRecord.Uid);
                    }
                    catch (FirebaseAuthException)
                    {
                        _logger.LogInformation("[FIREBASE_AUTH] User not found. Creating new Firebase Auth user for Email: {Email} (UID: {Uid})...", normalizedEmail, uid);
                        var args = new UserRecordArgs
                        {
                            Uid = uid,
                            Email = normalizedEmail,
                            EmailVerified = true,
                            Disabled = false
                        };
                        userRecord = await FirebaseAuth.DefaultInstance.CreateUserAsync(args, ct);
                        _logger.LogInformation("[FIREBASE_AUTH] Successfully created user for Email: {Email} (UID: {Uid})", normalizedEmail, userRecord.Uid);
                    }
                }
            }
            else
            {
                // Phone Number Flow
                string normalizedPhone = PhoneNumberUtils.Normalize(trimmed);
                string sanitizedDigits = new string(normalizedPhone.Where(char.IsDigit).ToArray());
                string uid = $"phone_{sanitizedDigits}";

                _logger.LogInformation("[FIREBASE_AUTH] Processing Phone Custom Token for {Phone} (UID: {Uid})", normalizedPhone, uid);

                try
                {
                    userRecord = await FirebaseAuth.DefaultInstance.GetUserAsync(uid, ct);
                }
                catch (FirebaseAuthException ex) when (ex.AuthErrorCode == AuthErrorCode.UserNotFound)
                {
                    try
                    {
                        userRecord = await FirebaseAuth.DefaultInstance.GetUserByPhoneNumberAsync(normalizedPhone, ct);
                    }
                    catch (FirebaseAuthException)
                    {
                        _logger.LogInformation("[FIREBASE_AUTH] User not found. Creating new Firebase Auth user for Phone: {Phone} (UID: {Uid})...", normalizedPhone, uid);
                        var args = new UserRecordArgs
                        {
                            Uid = uid,
                            PhoneNumber = normalizedPhone,
                            Disabled = false
                        };
                        userRecord = await FirebaseAuth.DefaultInstance.CreateUserAsync(args, ct);
                    }
                }
            }

            string customToken = await FirebaseAuth.DefaultInstance.CreateCustomTokenAsync(userRecord.Uid, ct);
            _logger.LogInformation("[FIREBASE_AUTH] CreateCustomTokenAsync succeeded for UID: {Uid}", userRecord.Uid);
            return customToken;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[FIREBASE_AUTH] Failed to generate custom token for identifier {Identifier}: {Message}", rawIdentifier, ex.Message);
            return null;
        }
    }
}
