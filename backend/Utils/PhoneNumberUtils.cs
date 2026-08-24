using System.Text.RegularExpressions;

namespace KrishiMitra.OtpApi.Utils;

public static class PhoneNumberUtils
{
    private static readonly Regex CleanRegex = new(@"[^\d+]", RegexOptions.Compiled);
    private static readonly Regex E164Regex = new(@"^\+[1-9]\d{9,14}$", RegexOptions.Compiled);

    /// <summary>
    /// Normalizes raw phone number inputs into E.164 international format (e.g., +919876543210).
    /// </summary>
    public static string Normalize(string? rawPhoneNumber, string defaultCountryCode = "+91")
    {
        if (string.IsNullOrWhiteSpace(rawPhoneNumber))
        {
            return string.Empty;
        }

        // Strip white spaces, dashes, parentheses, dots
        string cleaned = CleanRegex.Replace(rawPhoneNumber.Trim(), "");

        // Convert leading 00 to + (e.g., 00919876543210 -> +919876543210)
        if (cleaned.StartsWith("00"))
        {
            cleaned = "+" + cleaned[2..];
        }

        // If no leading +, handle national/country code formats
        if (!cleaned.StartsWith("+"))
        {
            // If 10 digits, assume default country code (+91)
            if (cleaned.Length == 10)
            {
                cleaned = defaultCountryCode + cleaned;
            }
            // If 12 digits starting with 91 (for India), prepend +
            else if (cleaned.Length == 12 && cleaned.StartsWith("91"))
            {
                cleaned = "+" + cleaned;
            }
            // Otherwise, prepend default country code if not already present
            else
            {
                cleaned = defaultCountryCode + cleaned.TrimStart('0');
            }
        }

        return cleaned;
    }

    /// <summary>
    /// Checks if a normalized phone number matches valid E.164 pattern.
    /// </summary>
    public static bool IsValidE164(string normalizedPhoneNumber)
    {
        return !string.IsNullOrWhiteSpace(normalizedPhoneNumber) && E164Regex.IsMatch(normalizedPhoneNumber);
    }
}
