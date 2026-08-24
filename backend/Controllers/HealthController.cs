using KrishiMitra.OtpApi.Models;
using Microsoft.AspNetCore.Mvc;

namespace KrishiMitra.OtpApi.Controllers;

[ApiController]
[Route("health")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult GetHealth()
    {
        return Ok(new HealthResponse { Status = "ok" });
    }
}
