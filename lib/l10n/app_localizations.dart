import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('ta'),
    Locale('te'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'KRISHI MITRA'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Connecting Farmers Directly with Consumers'**
  String get tagline;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get greeting;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmer;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village / Town'**
  String get village;

  /// No description provided for @mandi.
  ///
  /// In en, this message translates to:
  /// **'Mandi / Market'**
  String get mandi;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop / Produce'**
  String get crop;

  /// No description provided for @farmerType.
  ///
  /// In en, this message translates to:
  /// **'Farming Speciality'**
  String get farmerType;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Account Role'**
  String get selectRole;

  /// No description provided for @selectAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select App Language'**
  String get selectAppLanguage;

  /// No description provided for @selectModule.
  ///
  /// In en, this message translates to:
  /// **'Select Module'**
  String get selectModule;

  /// No description provided for @farmerRoleChip.
  ///
  /// In en, this message translates to:
  /// **'Farmer 🌾'**
  String get farmerRoleChip;

  /// No description provided for @customerRoleChip.
  ///
  /// In en, this message translates to:
  /// **'Customer 🛒'**
  String get customerRoleChip;

  /// No description provided for @farmerLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer Login (Mobile OTP)'**
  String get farmerLoginTitle;

  /// No description provided for @farmerLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered name and mobile number.'**
  String get farmerLoginSubtitle;

  /// No description provided for @farmerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Farmer Name'**
  String get farmerNameLabel;

  /// No description provided for @farmerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered name'**
  String get farmerNameHint;

  /// No description provided for @mobileNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumberLabel;

  /// No description provided for @emailAndPasswordTab.
  ///
  /// In en, this message translates to:
  /// **'Email & Password'**
  String get emailAndPasswordTab;

  /// No description provided for @mobileOtpTab.
  ///
  /// In en, this message translates to:
  /// **'Mobile OTP'**
  String get mobileOtpTab;

  /// No description provided for @newFarmerPrompt.
  ///
  /// In en, this message translates to:
  /// **'New farmer? '**
  String get newFarmerPrompt;

  /// No description provided for @dontHaveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccountPrompt;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @adminPortalLogin.
  ///
  /// In en, this message translates to:
  /// **'Admin Portal Login'**
  String get adminPortalLogin;

  /// No description provided for @errEmailPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter both email and password.'**
  String get errEmailPasswordRequired;

  /// No description provided for @errFarmerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your registered Farmer Name.'**
  String get errFarmerNameRequired;

  /// No description provided for @errMobileRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your 10-digit mobile number.'**
  String get errMobileRequired;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get createAccountTitle;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Krishi Mitra directly to connect with buyers and farmers'**
  String get createAccountSubtitle;

  /// No description provided for @alreadyHaveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccountPrompt;

  /// No description provided for @otpVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get otpVerificationTitle;

  /// No description provided for @enterOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-Digit OTP'**
  String get enterOtpTitle;

  /// No description provided for @weSentOtpTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to'**
  String get weSentOtpTo;

  /// No description provided for @verifyAndProceed.
  ///
  /// In en, this message translates to:
  /// **'Verify & Proceed'**
  String get verifyAndProceed;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in'**
  String get resendCodeIn;

  /// No description provided for @emailOtpVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Email OTP Verification'**
  String get emailOtpVerificationTitle;

  /// No description provided for @enterTerminalOtpDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit verification code shown in the terminal for:'**
  String get enterTerminalOtpDesc;

  /// No description provided for @generateNewCode.
  ///
  /// In en, this message translates to:
  /// **'Generate New Code'**
  String get generateNewCode;

  /// No description provided for @newCodeGeneratedInTerminal.
  ///
  /// In en, this message translates to:
  /// **'New OTP code generated in terminal for:'**
  String get newCodeGeneratedInTerminal;

  /// No description provided for @emailOtpTab.
  ///
  /// In en, this message translates to:
  /// **'Email OTP'**
  String get emailOtpTab;

  /// No description provided for @errEnterCompleteOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter the complete 6-digit OTP code.'**
  String get errEnterCompleteOtp;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Farmer Community'**
  String get community;

  /// No description provided for @mandiPrices.
  ///
  /// In en, this message translates to:
  /// **'Live Mandi Prices'**
  String get mandiPrices;

  /// No description provided for @pricePrediction.
  ///
  /// In en, this message translates to:
  /// **'Price Prediction'**
  String get pricePrediction;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Farm Marketplace'**
  String get marketplace;

  /// No description provided for @productTimeline.
  ///
  /// In en, this message translates to:
  /// **'Product Timeline'**
  String get productTimeline;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get orders;

  /// No description provided for @myProducts.
  ///
  /// In en, this message translates to:
  /// **'My Products'**
  String get myProducts;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Sell Produce'**
  String get addProduct;

  /// No description provided for @buyProducts.
  ///
  /// In en, this message translates to:
  /// **'Buy Products'**
  String get buyProducts;

  /// No description provided for @advisory.
  ///
  /// In en, this message translates to:
  /// **'Agri Advisory'**
  String get advisory;

  /// No description provided for @schemes.
  ///
  /// In en, this message translates to:
  /// **'Government Schemes'**
  String get schemes;

  /// No description provided for @verifiedFarmer.
  ///
  /// In en, this message translates to:
  /// **'Verified Farmer'**
  String get verifiedFarmer;

  /// No description provided for @organic.
  ///
  /// In en, this message translates to:
  /// **'Organic Certified'**
  String get organic;

  /// No description provided for @fpo.
  ///
  /// In en, this message translates to:
  /// **'FPO Certified'**
  String get fpo;

  /// No description provided for @qualityChecked.
  ///
  /// In en, this message translates to:
  /// **'Quality Checked'**
  String get qualityChecked;

  /// No description provided for @certificateVerified.
  ///
  /// In en, this message translates to:
  /// **'Certificate Verified'**
  String get certificateVerified;

  /// No description provided for @pendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Pending Verification'**
  String get pendingVerification;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @pricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get pricePerUnit;

  /// No description provided for @harvestDate.
  ///
  /// In en, this message translates to:
  /// **'Harvest Date'**
  String get harvestDate;

  /// No description provided for @batchId.
  ///
  /// In en, this message translates to:
  /// **'Batch ID'**
  String get batchId;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan Product QR'**
  String get scanQr;

  /// No description provided for @currentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current Price'**
  String get currentPrice;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// No description provided for @avgPrice.
  ///
  /// In en, this message translates to:
  /// **'Average Price'**
  String get avgPrice;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @forecast7Days.
  ///
  /// In en, this message translates to:
  /// **'7-Day Forecast'**
  String get forecast7Days;

  /// No description provided for @forecast15Days.
  ///
  /// In en, this message translates to:
  /// **'15-Day Forecast'**
  String get forecast15Days;

  /// No description provided for @forecast30Days.
  ///
  /// In en, this message translates to:
  /// **'30-Day Forecast'**
  String get forecast30Days;

  /// No description provided for @expectedTrend.
  ///
  /// In en, this message translates to:
  /// **'Market Trend'**
  String get expectedTrend;

  /// No description provided for @confidenceScore.
  ///
  /// In en, this message translates to:
  /// **'Confidence Score'**
  String get confidenceScore;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search crops, farmers, districts, mandis...'**
  String get searchPlaceholder;

  /// No description provided for @todaysOrders.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Orders'**
  String get todaysOrders;

  /// No description provided for @productsListed.
  ///
  /// In en, this message translates to:
  /// **'Products Listed'**
  String get productsListed;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @pendingDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Pending Deliveries'**
  String get pendingDeliveries;

  /// No description provided for @weatherSummary.
  ///
  /// In en, this message translates to:
  /// **'Weather Summary'**
  String get weatherSummary;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @sellCrop.
  ///
  /// In en, this message translates to:
  /// **'Sell Crop'**
  String get sellCrop;

  /// No description provided for @buyCrop.
  ///
  /// In en, this message translates to:
  /// **'Buy Crop'**
  String get buyCrop;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get cart;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @orderSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order Placed Successfully!'**
  String get orderSuccess;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @postPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Share update, ask questions, or discuss prices...'**
  String get postPlaceholder;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get verificationStatus;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get confirmLogout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No Data Found'**
  String get noDataFound;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @allCommodities.
  ///
  /// In en, this message translates to:
  /// **'All Commodities'**
  String get allCommodities;

  /// No description provided for @allStates.
  ///
  /// In en, this message translates to:
  /// **'All States'**
  String get allStates;

  /// No description provided for @allDistricts.
  ///
  /// In en, this message translates to:
  /// **'All Districts'**
  String get allDistricts;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About Krishi Mitra'**
  String get aboutApp;

  /// No description provided for @sellDirectlyToCustomers.
  ///
  /// In en, this message translates to:
  /// **'Sell Directly to Customers'**
  String get sellDirectlyToCustomers;

  /// No description provided for @sellDirectlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upon submission, your crop will automatically appear in the Customer Marketplace.'**
  String get sellDirectlySubtitle;

  /// No description provided for @farmerLocationInfo.
  ///
  /// In en, this message translates to:
  /// **'Farmer & Location Information'**
  String get farmerLocationInfo;

  /// No description provided for @farmLocation.
  ///
  /// In en, this message translates to:
  /// **'Farm Location'**
  String get farmLocation;

  /// No description provided for @cropDetailsPricing.
  ///
  /// In en, this message translates to:
  /// **'Crop Details & Pricing'**
  String get cropDetailsPricing;

  /// No description provided for @cropName.
  ///
  /// In en, this message translates to:
  /// **'Crop Name'**
  String get cropName;

  /// No description provided for @cropVariety.
  ///
  /// In en, this message translates to:
  /// **'Crop Variety'**
  String get cropVariety;

  /// No description provided for @harvestQty.
  ///
  /// In en, this message translates to:
  /// **'Harvest Qty'**
  String get harvestQty;

  /// No description provided for @availableStock.
  ///
  /// In en, this message translates to:
  /// **'Available Stock'**
  String get availableStock;

  /// No description provided for @pricePerUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Price / Unit'**
  String get pricePerUnitLabel;

  /// No description provided for @supplyChainTraceabilityStatus.
  ///
  /// In en, this message translates to:
  /// **'Supply Chain & Traceability Status'**
  String get supplyChainTraceabilityStatus;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @expectedDeliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Expected Delivery Time'**
  String get expectedDeliveryTime;

  /// No description provided for @listCropForSale.
  ///
  /// In en, this message translates to:
  /// **'LIST CROP FOR SALE'**
  String get listCropForSale;

  /// No description provided for @organicCertified.
  ///
  /// In en, this message translates to:
  /// **'Organic Certified'**
  String get organicCertified;

  /// No description provided for @fpoCertified.
  ///
  /// In en, this message translates to:
  /// **'FPO Certified'**
  String get fpoCertified;

  /// No description provided for @uploadCropPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Crop Photo'**
  String get uploadCropPhoto;

  /// No description provided for @salesAnalyticsOverview.
  ///
  /// In en, this message translates to:
  /// **'Sales Analytics & Revenue Overview'**
  String get salesAnalyticsOverview;

  /// No description provided for @productsSold.
  ///
  /// In en, this message translates to:
  /// **'Products Sold'**
  String get productsSold;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @pendingOrders.
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pendingOrders;

  /// No description provided for @completedOrders.
  ///
  /// In en, this message translates to:
  /// **'Completed Orders'**
  String get completedOrders;

  /// No description provided for @averageRating.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get averageRating;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @farmerResponsibilitiesActions.
  ///
  /// In en, this message translates to:
  /// **'Farmer Responsibilities & Actions'**
  String get farmerResponsibilitiesActions;

  /// No description provided for @listNewHarvest.
  ///
  /// In en, this message translates to:
  /// **'List new harvest'**
  String get listNewHarvest;

  /// No description provided for @manageListings.
  ///
  /// In en, this message translates to:
  /// **'Manage listings'**
  String get manageListings;

  /// No description provided for @ordersReceived.
  ///
  /// In en, this message translates to:
  /// **'Orders Received'**
  String get ordersReceived;

  /// No description provided for @manageBuyers.
  ///
  /// In en, this message translates to:
  /// **'Manage buyers'**
  String get manageBuyers;

  /// No description provided for @checkApmcRates.
  ///
  /// In en, this message translates to:
  /// **'Check APMC rates'**
  String get checkApmcRates;

  /// No description provided for @farmerCommunity.
  ///
  /// In en, this message translates to:
  /// **'Farmer Community'**
  String get farmerCommunity;

  /// No description provided for @qnaMachinery.
  ///
  /// In en, this message translates to:
  /// **'Q&A & Machinery'**
  String get qnaMachinery;

  /// No description provided for @recentCustomerOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent Customer Orders'**
  String get recentCustomerOrders;

  /// No description provided for @viewAllOrders.
  ///
  /// In en, this message translates to:
  /// **'View All Orders'**
  String get viewAllOrders;

  /// No description provided for @noCustomerOrders.
  ///
  /// In en, this message translates to:
  /// **'No customer orders received yet.'**
  String get noCustomerOrders;

  /// No description provided for @buyerStatus.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get buyerStatus;

  /// No description provided for @productPerformanceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Product Performance Breakdown'**
  String get productPerformanceBreakdown;

  /// No description provided for @noActiveCrops.
  ///
  /// In en, this message translates to:
  /// **'No active crops listed yet.'**
  String get noActiveCrops;

  /// No description provided for @varietyStock.
  ///
  /// In en, this message translates to:
  /// **'Variety'**
  String get varietyStock;

  /// No description provided for @soldOrders.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get soldOrders;

  /// No description provided for @noRatings.
  ///
  /// In en, this message translates to:
  /// **'No ratings'**
  String get noRatings;

  /// No description provided for @customerFeedbackRatings.
  ///
  /// In en, this message translates to:
  /// **'Customer Feedback & Ratings'**
  String get customerFeedbackRatings;

  /// No description provided for @noCustomerFeedback.
  ///
  /// In en, this message translates to:
  /// **'No customer feedback received yet.'**
  String get noCustomerFeedback;

  /// No description provided for @accountVerificationPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Verification Pending'**
  String get accountVerificationPendingTitle;

  /// No description provided for @accountVerificationPendingDesc.
  ///
  /// In en, this message translates to:
  /// **'Your farmer profile is under review by government/admin officers. Market features remain active.'**
  String get accountVerificationPendingDesc;

  /// No description provided for @categoryVegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get categoryVegetables;

  /// No description provided for @categoryFruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get categoryFruits;

  /// No description provided for @categoryGrains.
  ///
  /// In en, this message translates to:
  /// **'Grains & Cereals'**
  String get categoryGrains;

  /// No description provided for @categoryPulses.
  ///
  /// In en, this message translates to:
  /// **'Pulses & Legumes'**
  String get categoryPulses;

  /// No description provided for @categorySpices.
  ///
  /// In en, this message translates to:
  /// **'Spices & Herbs'**
  String get categorySpices;

  /// No description provided for @categoryOrganic.
  ///
  /// In en, this message translates to:
  /// **'Organic Produce'**
  String get categoryOrganic;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitQuintal.
  ///
  /// In en, this message translates to:
  /// **'Quintal'**
  String get unitQuintal;

  /// No description provided for @unitTon.
  ///
  /// In en, this message translates to:
  /// **'Ton'**
  String get unitTon;

  /// No description provided for @unitDozen.
  ///
  /// In en, this message translates to:
  /// **'Dozen'**
  String get unitDozen;

  /// No description provided for @unitItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get unitItem;

  /// No description provided for @farmerTypeOrganic.
  ///
  /// In en, this message translates to:
  /// **'Organic Farmer'**
  String get farmerTypeOrganic;

  /// No description provided for @farmerTypeGrainPaddy.
  ///
  /// In en, this message translates to:
  /// **'Grain & Paddy Producer'**
  String get farmerTypeGrainPaddy;

  /// No description provided for @farmerTypeHorticulture.
  ///
  /// In en, this message translates to:
  /// **'Horticulture & Fruits'**
  String get farmerTypeHorticulture;

  /// No description provided for @farmerTypeVegetable.
  ///
  /// In en, this message translates to:
  /// **'Vegetable Cultivator'**
  String get farmerTypeVegetable;

  /// No description provided for @farmerTypeSpices.
  ///
  /// In en, this message translates to:
  /// **'Spices & Plantation'**
  String get farmerTypeSpices;

  /// No description provided for @farmerTypeDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy & Mixed Farming'**
  String get farmerTypeDairy;

  /// No description provided for @deliveringTo.
  ///
  /// In en, this message translates to:
  /// **'Delivering to'**
  String get deliveringTo;

  /// No description provided for @marketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'KRISHI MITRA Marketplace 🌾'**
  String get marketplaceTitle;

  /// No description provided for @bannerTitle1.
  ///
  /// In en, this message translates to:
  /// **'Farm Fresh Crops'**
  String get bannerTitle1;

  /// No description provided for @bannerSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Directly from verified Indian farmers at zero commission markup'**
  String get bannerSubtitle1;

  /// No description provided for @bannerTitle2.
  ///
  /// In en, this message translates to:
  /// **'Traceability via QR Code'**
  String get bannerTitle2;

  /// No description provided for @bannerSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Scan produce QR to view crop timeline from seed to doorstep'**
  String get bannerSubtitle2;

  /// No description provided for @bannerTitle3.
  ///
  /// In en, this message translates to:
  /// **'100% Organic & FPO Certified'**
  String get bannerTitle3;

  /// No description provided for @bannerSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'Verified heirloom crops harvested cleanly with zero chemicals'**
  String get bannerSubtitle3;

  /// No description provided for @nearbyFarmersBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'📍 Nearby Farmers & Local Crops'**
  String get nearbyFarmersBannerTitle;

  /// No description provided for @nearbyFarmersBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Filter available crops by distance radius (5 km, 10 km, 20 km)'**
  String get nearbyFarmersBannerSubtitle;

  /// No description provided for @browseMarket.
  ///
  /// In en, this message translates to:
  /// **'Browse Market'**
  String get browseMarket;

  /// No description provided for @nearbyFarmers.
  ///
  /// In en, this message translates to:
  /// **'Nearby Farmers'**
  String get nearbyFarmers;

  /// No description provided for @mandiRates.
  ///
  /// In en, this message translates to:
  /// **'Mandi Rates'**
  String get mandiRates;

  /// No description provided for @browseCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse Categories'**
  String get browseCategories;

  /// No description provided for @freshFarmHarvests.
  ///
  /// In en, this message translates to:
  /// **'Fresh Farm Harvests'**
  String get freshFarmHarvests;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @addedToCartSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Added to cart successfully!'**
  String get addedToCartSnackbar;

  /// No description provided for @communityTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer Knowledge Sharing & Community'**
  String get communityTitle;

  /// No description provided for @postQuestionBtn.
  ///
  /// In en, this message translates to:
  /// **'Post Agronomic Question / Crop Sale'**
  String get postQuestionBtn;

  /// No description provided for @allPosts.
  ///
  /// In en, this message translates to:
  /// **'All Posts'**
  String get allPosts;

  /// No description provided for @machineryTools.
  ///
  /// In en, this message translates to:
  /// **'Machinery & Tools'**
  String get machineryTools;

  /// No description provided for @agriQna.
  ///
  /// In en, this message translates to:
  /// **'Agri Q&A'**
  String get agriQna;

  /// No description provided for @priceAlerts.
  ///
  /// In en, this message translates to:
  /// **'Price Alerts'**
  String get priceAlerts;

  /// No description provided for @noCommunityPosts.
  ///
  /// In en, this message translates to:
  /// **'No community posts found.'**
  String get noCommunityPosts;

  /// No description provided for @createPostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your farming experience, query, or machine rental...'**
  String get createPostSubtitle;

  /// No description provided for @schemesTitle.
  ///
  /// In en, this message translates to:
  /// **'Government Subsidies & Farmer Schemes'**
  String get schemesTitle;

  /// No description provided for @schemesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Direct Benefit Transfer (DBT) & Agricultural Assistance'**
  String get schemesSubtitle;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get applyNow;

  /// No description provided for @schemeDetails.
  ///
  /// In en, this message translates to:
  /// **'Scheme Details'**
  String get schemeDetails;

  /// No description provided for @advisoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Agri Advisory & Advisory Helpline'**
  String get advisoryTitle;

  /// No description provided for @advisorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Crop Disease Diagnosis & Weather Advisories'**
  String get advisorySubtitle;

  /// No description provided for @askAiAgronomist.
  ///
  /// In en, this message translates to:
  /// **'Ask AI Agronomist'**
  String get askAiAgronomist;

  /// No description provided for @mandiScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'APMC Live Mandi Market Prices'**
  String get mandiScreenTitle;

  /// No description provided for @mandiScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Agmarknet Real-time Daily Wholesale Rates'**
  String get mandiScreenSubtitle;

  /// No description provided for @filterState.
  ///
  /// In en, this message translates to:
  /// **'Filter State'**
  String get filterState;

  /// No description provided for @filterDistrict.
  ///
  /// In en, this message translates to:
  /// **'Filter District'**
  String get filterDistrict;

  /// No description provided for @filterCommodity.
  ///
  /// In en, this message translates to:
  /// **'Filter Commodity'**
  String get filterCommodity;

  /// No description provided for @pricePredictionTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Price Forecasting & Market Trends'**
  String get pricePredictionTitle;

  /// No description provided for @pricePredictionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'7-Day, 15-Day & 30-Day APMC Rate Predictions'**
  String get pricePredictionSubtitle;

  /// No description provided for @timelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm-to-Doorstep Traceability Timeline'**
  String get timelineTitle;

  /// No description provided for @timelineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verified Seed-to-Fork Journey'**
  String get timelineSubtitle;

  /// No description provided for @scanQrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Crop QR Code'**
  String get scanQrCodeTitle;

  /// No description provided for @alignCameraNotice.
  ///
  /// In en, this message translates to:
  /// **'Align camera over produce QR code'**
  String get alignCameraNotice;

  /// No description provided for @officerPortal.
  ///
  /// In en, this message translates to:
  /// **'Officer Portal'**
  String get officerPortal;

  /// No description provided for @adminPortalTitle.
  ///
  /// In en, this message translates to:
  /// **'Government & Admin Verification Portal'**
  String get adminPortalTitle;

  /// No description provided for @pendingVerifications.
  ///
  /// In en, this message translates to:
  /// **'Pending Verification Applications'**
  String get pendingVerifications;

  /// No description provided for @verifyFarmer.
  ///
  /// In en, this message translates to:
  /// **'Verify Farmer'**
  String get verifyFarmer;

  /// No description provided for @rejectApplication.
  ///
  /// In en, this message translates to:
  /// **'Reject Application'**
  String get rejectApplication;

  /// No description provided for @noOrdersPlaced.
  ///
  /// In en, this message translates to:
  /// **'No orders placed yet'**
  String get noOrdersPlaced;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @enterMobilePrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid mobile number'**
  String get enterMobilePrompt;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @myOrdersAndTraceability.
  ///
  /// In en, this message translates to:
  /// **'My Orders & Traceability'**
  String get myOrdersAndTraceability;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDenied;

  /// No description provided for @adminPrivilegesRequired.
  ///
  /// In en, this message translates to:
  /// **'Access Denied: Admin Privileges Required'**
  String get adminPrivilegesRequired;

  /// No description provided for @productApprovals.
  ///
  /// In en, this message translates to:
  /// **'Product Approvals'**
  String get productApprovals;

  /// No description provided for @registrationConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration Confirmation'**
  String get registrationConfirmationTitle;

  /// No description provided for @registrationSuccessfulTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful!'**
  String get registrationSuccessfulTitle;

  /// No description provided for @farmerRegistrationSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Your farmer account has been registered successfully. You can now log in to manage your profile and produce.'**
  String get farmerRegistrationSuccessDesc;

  /// No description provided for @customerRegistrationSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Your customer account has been registered successfully. You can now log in to explore fresh farm produce.'**
  String get customerRegistrationSuccessDesc;

  /// No description provided for @farmerProfileSummary.
  ///
  /// In en, this message translates to:
  /// **'Farmer Profile Summary'**
  String get farmerProfileSummary;

  /// No description provided for @customerProfileSummary.
  ///
  /// In en, this message translates to:
  /// **'Customer Profile Summary'**
  String get customerProfileSummary;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressLabel;

  /// No description provided for @accountRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Role'**
  String get accountRoleLabel;

  /// No description provided for @stateLabel.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get stateLabel;

  /// No description provided for @districtLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabel;

  /// No description provided for @villageLabel.
  ///
  /// In en, this message translates to:
  /// **'Village / Town'**
  String get villageLabel;

  /// No description provided for @farmerTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Farmer Type'**
  String get farmerTypeLabel;

  /// No description provided for @verificationStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get verificationStatusLabel;

  /// No description provided for @verifiedStatus.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedStatus;

  /// No description provided for @pendingVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending Verification'**
  String get pendingVerificationStatus;

  /// No description provided for @uploadedCertificateLabel.
  ///
  /// In en, this message translates to:
  /// **'Uploaded Certificate'**
  String get uploadedCertificateLabel;

  /// No description provided for @continueToLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to Login'**
  String get continueToLoginButton;

  /// No description provided for @availableStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Available Stock'**
  String get availableStockLabel;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @bulkDiscountTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk Order Discount'**
  String get bulkDiscountTitle;

  /// No description provided for @bulkPriceNotice.
  ///
  /// In en, this message translates to:
  /// **'Special Bulk Price Available!'**
  String get bulkPriceNotice;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Price per unit'**
  String get unitPrice;

  /// No description provided for @discountAmount.
  ///
  /// In en, this message translates to:
  /// **'Discount Savings'**
  String get discountAmount;

  /// No description provided for @confirmRejection.
  ///
  /// In en, this message translates to:
  /// **'Confirm Rejection'**
  String get confirmRejection;

  /// No description provided for @rejectionReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Enter reason for rejection / remarks...'**
  String get rejectionReasonHint;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @approveAndVerify.
  ///
  /// In en, this message translates to:
  /// **'Approve & Verify'**
  String get approveAndVerify;

  /// No description provided for @approveAndPublish.
  ///
  /// In en, this message translates to:
  /// **'Approve & Publish'**
  String get approveAndPublish;

  /// No description provided for @rejectProduct.
  ///
  /// In en, this message translates to:
  /// **'Reject Product'**
  String get rejectProduct;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @copiedLinkSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Copied Public QR Trace Link!'**
  String get copiedLinkSnackbar;

  /// No description provided for @scanQrTimeline.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Timeline'**
  String get scanQrTimeline;

  /// No description provided for @openAppTimeline.
  ///
  /// In en, this message translates to:
  /// **'Open App Timeline'**
  String get openAppTimeline;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to cart successfully!'**
  String get addedToCart;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @allNotificationsRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read.'**
  String get allNotificationsRead;

  /// No description provided for @noOrdersRecordedYet.
  ///
  /// In en, this message translates to:
  /// **'No platform orders recorded yet.'**
  String get noOrdersRecordedYet;

  /// No description provided for @orderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get orderIdLabel;

  /// No description provided for @buyerLabel.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get buyerLabel;

  /// No description provided for @farmerLabel.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmerLabel;

  /// No description provided for @productLabel.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get productLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @paymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentLabel;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @noUsersRegisteredYet.
  ///
  /// In en, this message translates to:
  /// **'No users registered yet.'**
  String get noUsersRegisteredYet;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @pendingFilter.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingFilter;

  /// No description provided for @approvedFilter.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvedFilter;

  /// No description provided for @rejectedFilter.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedFilter;

  /// No description provided for @searchCropPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search crop (e.g. Tomato, Rice, Potato)...'**
  String get searchCropPlaceholder;

  /// No description provided for @organicCropTag.
  ///
  /// In en, this message translates to:
  /// **'Organic Crop Tag'**
  String get organicCropTag;

  /// No description provided for @organicCropTagSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Grown 100% naturally without synthetic chemicals'**
  String get organicCropTagSubtitle;

  /// No description provided for @verifiedFarmerBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified Farmer Badge'**
  String get verifiedFarmerBadge;

  /// No description provided for @verifiedFarmerBadgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Government / FPO farmer verification active'**
  String get verifiedFarmerBadgeSubtitle;

  /// No description provided for @publishInMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Publish in Marketplace'**
  String get publishInMarketplace;

  /// No description provided for @publishInMarketplaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visible to customers in the marketplace'**
  String get publishInMarketplaceSubtitle;

  /// No description provided for @minBulkQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Min Bulk Qty'**
  String get minBulkQtyLabel;

  /// No description provided for @bulkPricePerUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Bulk Price / Unit (₹)'**
  String get bulkPricePerUnitLabel;

  /// No description provided for @optionalCertificateInfo.
  ///
  /// In en, this message translates to:
  /// **'Optional Certificate Info'**
  String get optionalCertificateInfo;

  /// No description provided for @cropImageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Crop Image URL'**
  String get cropImageUrlLabel;

  /// No description provided for @publicTraceabilityLink.
  ///
  /// In en, this message translates to:
  /// **'Public Traceability Link'**
  String get publicTraceabilityLink;

  /// No description provided for @editTimelineStages.
  ///
  /// In en, this message translates to:
  /// **'EDIT PRODUCT TIMELINE & STAGES'**
  String get editTimelineStages;

  /// No description provided for @previewCustomerPage.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW PUBLIC CUSTOMER PAGE'**
  String get previewCustomerPage;

  /// No description provided for @farmerTraceabilityQr.
  ///
  /// In en, this message translates to:
  /// **'Farmer Traceability QR'**
  String get farmerTraceabilityQr;

  /// No description provided for @variety.
  ///
  /// In en, this message translates to:
  /// **'Variety'**
  String get variety;

  /// No description provided for @launchScanner.
  ///
  /// In en, this message translates to:
  /// **'Launch Camera Scanner'**
  String get launchScanner;

  /// No description provided for @closeScanner.
  ///
  /// In en, this message translates to:
  /// **'Close Camera Scanner'**
  String get closeScanner;

  /// No description provided for @scanBatchBtn.
  ///
  /// In en, this message translates to:
  /// **'Scan Batch'**
  String get scanBatchBtn;

  /// No description provided for @manualBatchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Batch ID (e.g. TOM-ERD-101)'**
  String get manualBatchHint;

  /// No description provided for @editProductTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Product Timeline'**
  String get editProductTimelineTitle;

  /// No description provided for @timelineSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Product timeline saved to Firestore! Public QR updated.'**
  String get timelineSavedSnackbar;

  /// No description provided for @qualityGradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Quality Grade & Certification'**
  String get qualityGradeTitle;

  /// No description provided for @qualityGradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Quality Status / Grade'**
  String get qualityGradeLabel;

  /// No description provided for @certificationInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Certification Info'**
  String get certificationInfoLabel;

  /// No description provided for @saveTimelineBtn.
  ///
  /// In en, this message translates to:
  /// **'SAVE PRODUCT TIMELINE TO FIRESTORE'**
  String get saveTimelineBtn;

  /// No description provided for @savingTimelineBtn.
  ///
  /// In en, this message translates to:
  /// **'SAVING TO FIRESTORE...'**
  String get savingTimelineBtn;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @eventDescription.
  ///
  /// In en, this message translates to:
  /// **'Event Description'**
  String get eventDescription;

  /// No description provided for @eligibility.
  ///
  /// In en, this message translates to:
  /// **'Eligibility'**
  String get eligibility;

  /// No description provided for @keyBenefits.
  ///
  /// In en, this message translates to:
  /// **'Key Benefits'**
  String get keyBenefits;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @helpful.
  ///
  /// In en, this message translates to:
  /// **'Helpful'**
  String get helpful;

  /// No description provided for @replies.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get replies;

  /// No description provided for @farmerReply.
  ///
  /// In en, this message translates to:
  /// **'Farmer Reply'**
  String get farmerReply;

  /// No description provided for @replyHint.
  ///
  /// In en, this message translates to:
  /// **'Reply to farmer discussion...'**
  String get replyHint;

  /// No description provided for @qualityAndTrust.
  ///
  /// In en, this message translates to:
  /// **'Quality & Trust'**
  String get qualityAndTrust;

  /// No description provided for @qualityVerified.
  ///
  /// In en, this message translates to:
  /// **'Quality Verified'**
  String get qualityVerified;

  /// No description provided for @organicCertificateVerified.
  ///
  /// In en, this message translates to:
  /// **'Organic Certificate Verified'**
  String get organicCertificateVerified;

  /// No description provided for @deliveryCharge.
  ///
  /// In en, this message translates to:
  /// **'Delivery Charge'**
  String get deliveryCharge;

  /// No description provided for @productSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Product Subtotal'**
  String get productSubtotal;

  /// No description provided for @discountSavings.
  ///
  /// In en, this message translates to:
  /// **'Discount Savings'**
  String get discountSavings;

  /// No description provided for @finalTotal.
  ///
  /// In en, this message translates to:
  /// **'Final Total'**
  String get finalTotal;

  /// No description provided for @reportQualityIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Quality Issue'**
  String get reportQualityIssue;

  /// No description provided for @spoiledProduce.
  ///
  /// In en, this message translates to:
  /// **'Spoiled Produce'**
  String get spoiledProduce;

  /// No description provided for @poorQuality.
  ///
  /// In en, this message translates to:
  /// **'Poor Quality'**
  String get poorQuality;

  /// No description provided for @incorrectQuality.
  ///
  /// In en, this message translates to:
  /// **'Incorrect Quality'**
  String get incorrectQuality;

  /// No description provided for @otherQualityIssue.
  ///
  /// In en, this message translates to:
  /// **'Other Quality Issue'**
  String get otherQualityIssue;

  /// No description provided for @complaintSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Quality complaint submitted successfully!'**
  String get complaintSubmitted;

  /// No description provided for @adminVerification.
  ///
  /// In en, this message translates to:
  /// **'Admin Verification'**
  String get adminVerification;

  /// No description provided for @verifyCertificate.
  ///
  /// In en, this message translates to:
  /// **'Verify Certificate'**
  String get verifyCertificate;

  /// No description provided for @verifyBatch.
  ///
  /// In en, this message translates to:
  /// **'Verify Batch'**
  String get verifyBatch;

  /// No description provided for @reviewComplaint.
  ///
  /// In en, this message translates to:
  /// **'Review Complaint'**
  String get reviewComplaint;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @needsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs Review'**
  String get needsReview;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason / Remarks'**
  String get rejectionReason;

  /// No description provided for @organicCertificates.
  ///
  /// In en, this message translates to:
  /// **'Organic Certificates'**
  String get organicCertificates;

  /// No description provided for @harvestBatches.
  ///
  /// In en, this message translates to:
  /// **'Harvest Batches'**
  String get harvestBatches;

  /// No description provided for @qualityComplaints.
  ///
  /// In en, this message translates to:
  /// **'Quality Complaints'**
  String get qualityComplaints;

  /// No description provided for @issueType.
  ///
  /// In en, this message translates to:
  /// **'Issue Type'**
  String get issueType;

  /// No description provided for @complaintDescription.
  ///
  /// In en, this message translates to:
  /// **'Complaint Description'**
  String get complaintDescription;

  /// No description provided for @photoEvidence.
  ///
  /// In en, this message translates to:
  /// **'Photo Evidence (Optional)'**
  String get photoEvidence;

  /// No description provided for @deliveryPartner.
  ///
  /// In en, this message translates to:
  /// **'Delivery Partner'**
  String get deliveryPartner;

  /// No description provided for @deliveryStatus.
  ///
  /// In en, this message translates to:
  /// **'Delivery Status'**
  String get deliveryStatus;

  /// No description provided for @deliveryDetails.
  ///
  /// In en, this message translates to:
  /// **'Delivery Details'**
  String get deliveryDetails;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickupLocation;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @assignedPartner.
  ///
  /// In en, this message translates to:
  /// **'Assigned Partner'**
  String get assignedPartner;

  /// No description provided for @assignDeliveryPartner.
  ///
  /// In en, this message translates to:
  /// **'Assign Delivery Partner'**
  String get assignDeliveryPartner;

  /// No description provided for @updateDeliveryStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Delivery Status'**
  String get updateDeliveryStatus;

  /// No description provided for @deliveryStatusPlaced.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get deliveryStatusPlaced;

  /// No description provided for @deliveryStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get deliveryStatusAssigned;

  /// No description provided for @deliveryStatusPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get deliveryStatusPickup;

  /// No description provided for @deliveryStatusInTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get deliveryStatusInTransit;

  /// No description provided for @deliveryStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveryStatusDelivered;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter the address'**
  String get enterAddress;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addAddress;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get editAddress;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @paymentUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get paymentUpi;

  /// No description provided for @paymentCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card/Debit Card'**
  String get paymentCard;

  /// No description provided for @paymentCod.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get paymentCod;

  /// No description provided for @deliveryFeeForKm.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee for {distance} km - ₹{fee}'**
  String deliveryFeeForKm(String distance, String fee);

  /// No description provided for @deliveryFeeLabelForKm.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee for {distance} km'**
  String deliveryFeeLabelForKm(String distance);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'hi',
    'kn',
    'ml',
    'mr',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
