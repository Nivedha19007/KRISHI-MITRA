namespace KrishiMitra.OtpApi.Models;

public class CalculateDeliveryRequest
{
    public string PickupAddress { get; set; } = string.Empty;
    public string DeliveryAddress { get; set; } = string.Empty;
    public double PickupLatitude { get; set; }
    public double PickupLongitude { get; set; }
    public double DeliveryLatitude { get; set; }
    public double DeliveryLongitude { get; set; }
    public double BaseFee { get; set; } = 30.0;
    public double RatePerKm { get; set; } = 5.0;
}

public class CalculateDeliveryResponse
{
    public double DeliveryCharge { get; set; }
    public double DistanceKm { get; set; }
    public double BaseFee { get; set; }
    public double RatePerKm { get; set; }
    public string Status { get; set; } = "success";
}

public class ValidateOrderRequest
{
    public double ProductSubtotal { get; set; }
    public double DiscountSavings { get; set; }
    public double DeliveryCharge { get; set; }
    public double ClaimedFinalTotal { get; set; }
    public string PickupAddress { get; set; } = string.Empty;
    public string DeliveryAddress { get; set; } = string.Empty;
    public double PickupLatitude { get; set; }
    public double PickupLongitude { get; set; }
    public double DeliveryLatitude { get; set; }
    public double DeliveryLongitude { get; set; }
}

public class ValidateOrderResponse
{
    public bool IsValid { get; set; }
    public double ExpectedDeliveryCharge { get; set; }
    public double ExpectedFinalTotal { get; set; }
    public string Message { get; set; } = string.Empty;
}
