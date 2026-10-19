namespace KrishiMitra.OtpApi.Services;

using KrishiMitra.OtpApi.Models;

public class DeliveryService : IDeliveryService
{
    private static readonly Dictionary<string, (double Lat, double Lng)> DistrictCoordinates = new(StringComparer.OrdinalIgnoreCase)
    {
        { "Erode", (11.3410, 77.7172) },
        { "Coimbatore", (11.0168, 76.9558) },
        { "Salem", (11.6643, 78.1460) },
        { "Pollachi", (10.6609, 77.0048) },
        { "Tiruppur", (11.1085, 77.3411) },
        { "Madurai", (9.9252, 78.1198) },
        { "Dindigul", (10.3673, 77.9803) },
        { "Tiruchirappalli", (10.7905, 78.7047) },
        { "Thanjavur", (10.7870, 79.1378) },
        { "Chennai", (13.0827, 80.2707) },
        { "Bengaluru", (12.9716, 77.5946) },
        { "Mysuru", (12.2958, 76.6394) },
        { "Kolar", (13.1368, 78.1291) },
        { "Hyderabad", (17.3850, 78.4867) },
        { "Vijayawada", (16.5062, 80.6480) },
        { "Nashik", (19.9975, 73.7898) },
        { "Pune", (18.5204, 73.8567) }
    };

    public CalculateDeliveryResponse CalculateDeliveryCharge(CalculateDeliveryRequest request)
    {
        var pickup = GetCoordinates(request.PickupAddress, request.PickupLatitude, request.PickupLongitude);
        var delivery = GetCoordinates(request.DeliveryAddress, request.DeliveryLatitude, request.DeliveryLongitude, pickup);

        double distanceKm = CalculateHaversineDistance(pickup.Lat, pickup.Lng, delivery.Lat, delivery.Lng);
        distanceKm = Math.Round(distanceKm, 2);

        double baseFee = request.BaseFee > 0 ? request.BaseFee : 10.0;
        double ratePerKm = request.RatePerKm > 0 ? request.RatePerKm : 1.0;
        double maxFee = 30.0;

        double calculated = baseFee + (distanceKm * ratePerKm);
        double finalCharge = Math.Min(maxFee, Math.Max(10.0, Math.Round(calculated, 2)));

        return new CalculateDeliveryResponse
        {
            DeliveryCharge = finalCharge,
            DistanceKm = distanceKm,
            BaseFee = baseFee,
            RatePerKm = ratePerKm,
            Status = "success"
        };
    }

    public ValidateOrderResponse ValidateOrderTotal(ValidateOrderRequest request)
    {
        var calcResponse = CalculateDeliveryCharge(new CalculateDeliveryRequest
        {
            PickupAddress = request.PickupAddress,
            DeliveryAddress = request.DeliveryAddress,
            PickupLatitude = request.PickupLatitude,
            PickupLongitude = request.PickupLongitude,
            DeliveryLatitude = request.DeliveryLatitude,
            DeliveryLongitude = request.DeliveryLongitude,
        });

        double expectedSubtotalAfterDiscount = Math.Max(0, request.ProductSubtotal - request.DiscountSavings);
        double expectedFinalTotal = Math.Round(expectedSubtotalAfterDiscount + calcResponse.DeliveryCharge, 2);
        double claimedTotal = Math.Round(request.ClaimedFinalTotal, 2);

        bool isValid = Math.Abs(expectedFinalTotal - claimedTotal) <= 1.0;

        return new ValidateOrderResponse
        {
            IsValid = isValid,
            ExpectedDeliveryCharge = calcResponse.DeliveryCharge,
            ExpectedFinalTotal = expectedFinalTotal,
            Message = isValid
                ? "Order pricing and delivery charge successfully validated."
                : $"Order validation failed. Claimed total ₹{claimedTotal} does not match expected total ₹{expectedFinalTotal}."
        };
    }

    private static (double Lat, double Lng) GetCoordinates(string address, double lat, double lng, (double Lat, double Lng)? fallback = null)
    {
        if (lat != 0.0 && lng != 0.0)
        {
            return (lat, lng);
        }

        if (!string.IsNullOrWhiteSpace(address))
        {
            foreach (var kvp in DistrictCoordinates)
            {
                if (address.Contains(kvp.Key, StringComparison.OrdinalIgnoreCase))
                {
                    return kvp.Value;
                }
            }
        }

        return fallback ?? (11.0168, 76.9558); // Default Coimbatore
    }

    private static double CalculateHaversineDistance(double lat1, double lon1, double lat2, double lon2)
    {
        if (lat1 == lat2 && lon1 == lon2) return 0.0;

        const double p = Math.PI / 180.0;
        double a = 0.5 - Math.Cos((lat2 - lat1) * p) / 2 +
                   Math.Cos(lat1 * p) * Math.Cos(lat2 * p) * (1 - Math.Cos((lon2 - lon1) * p)) / 2;

        return 12742.0 * Math.Asin(Math.Sqrt(a));
    }
}
