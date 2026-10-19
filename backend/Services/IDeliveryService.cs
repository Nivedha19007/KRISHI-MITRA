namespace KrishiMitra.OtpApi.Services;

using KrishiMitra.OtpApi.Models;

public interface IDeliveryService
{
    CalculateDeliveryResponse CalculateDeliveryCharge(CalculateDeliveryRequest request);
    ValidateOrderResponse ValidateOrderTotal(ValidateOrderRequest request);
}
