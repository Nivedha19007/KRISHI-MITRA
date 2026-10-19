using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using KrishiMitra.OtpApi.Services;

var builder = WebApplication.CreateBuilder(args);

// Render / Production PORT Binding configuration
var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";
builder.WebHost.UseUrls($"http://0.0.0.0:{port}");

// Initialize Firebase Admin SDK for project krishi-mitra-38a5f
if (FirebaseApp.DefaultInstance == null)
{
    var serviceAccountJson = Environment.GetEnvironmentVariable("FIREBASE_SERVICE_ACCOUNT_JSON")
        ?? builder.Configuration["Firebase:ServiceAccountJson"];

    var serviceAccountPath = Environment.GetEnvironmentVariable("FIREBASE_SERVICE_ACCOUNT_PATH")
        ?? Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS")
        ?? builder.Configuration["Firebase:ServiceAccountFilePath"]
        ?? builder.Configuration["Firebase:ServiceAccountPath"];

    // Auto-detect downloaded service account file in user's Downloads directory for local development
    if (string.IsNullOrWhiteSpace(serviceAccountJson) && (string.IsNullOrWhiteSpace(serviceAccountPath) || !File.Exists(serviceAccountPath)))
    {
        try
        {
            var userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            var downloadsPath = Path.Combine(userProfile, "Downloads");
            if (Directory.Exists(downloadsPath))
            {
                var matchingFiles = Directory.GetFiles(downloadsPath, "krishi-mitra-38a5f-firebase-adminsdk-*.json");
                if (matchingFiles.Length > 0)
                {
                    serviceAccountPath = matchingFiles[0];
                }
            }
        }
        catch
        {
            // Ignore auto-detection errors
        }
    }

    GoogleCredential? credential = null;
    if (!string.IsNullOrWhiteSpace(serviceAccountJson))
    {
        credential = GoogleCredential.FromJson(serviceAccountJson);
    }
    else if (!string.IsNullOrWhiteSpace(serviceAccountPath) && File.Exists(serviceAccountPath))
    {
        credential = GoogleCredential.FromFile(serviceAccountPath);
    }

    if (credential != null)
    {
        try
        {
            FirebaseApp.Create(new AppOptions
            {
                Credential = credential,
                ProjectId = "krishi-mitra-38a5f"
            });
            Console.WriteLine("[FIREBASE_AUTH] Firebase Admin SDK initialized successfully.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[FIREBASE_AUTH] Error initializing Firebase Admin SDK: {ex.Message}");
            if (builder.Environment.IsDevelopment())
            {
                throw;
            }
        }
    }
    else
    {
        Console.WriteLine("[FIREBASE_AUTH] ERROR: Firebase service account credentials could not be found.");
        if (builder.Environment.IsDevelopment())
        {
            throw new InvalidOperationException(
                "[FIREBASE_AUTH] Firebase service account credentials missing for project 'krishi-mitra-38a5f'. " +
                "Please set FIREBASE_SERVICE_ACCOUNT_PATH or GOOGLE_APPLICATION_CREDENTIALS environment variable, " +
                "or configure Firebase:ServiceAccountFilePath in appsettings.Development.json.");
        }
    }
}

// Add services to DI container
builder.Services.AddMemoryCache();
builder.Services.AddControllers();
builder.Services.AddHttpClient();
builder.Services.AddHttpClient<IMandiService, MandiService>();
builder.Services.AddOpenApi();

// Register OTP & Firebase & Delivery Services
builder.Services.AddSingleton<IOtpStore, InMemoryOtpStore>();
builder.Services.AddTransient<ISmsService, SmsService>();
builder.Services.AddTransient<IOtpService, OtpService>();
builder.Services.AddTransient<IFirebaseAuthService, FirebaseAuthService>();
builder.Services.AddTransient<IDeliveryService, DeliveryService>();




// Configure CORS
var allowedOriginsEnv = Environment.GetEnvironmentVariable("ALLOWED_ORIGINS");
builder.Services.AddCors(options =>
{
    options.AddPolicy("DefaultCorsPolicy", policy =>
    {
        if (!string.IsNullOrWhiteSpace(allowedOriginsEnv) && allowedOriginsEnv != "*")
        {
            var origins = allowedOriginsEnv.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
            policy.WithOrigins(origins)
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
        }
        else
        {
            policy.AllowAnyOrigin()
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        }
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("DefaultCorsPolicy");
app.UseAuthorization();

// Production health check
app.MapGet("/health", () => Results.Ok(new
{
    status = "ok"
}));

app.MapControllers();

app.Run();
