// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'कृषि मित्र';

  @override
  String get tagline => 'किसानों को उपभोक्ताओं से सीधे जोड़ना';

  @override
  String get greeting => 'नमस्ते';

  @override
  String get farmer => 'किसान';

  @override
  String get customer => 'ग्राहक';

  @override
  String get admin => 'व्यवस्थापक';

  @override
  String get login => 'लॉग इन करें';

  @override
  String get register => 'पंजीकरण करें';

  @override
  String get email => 'ईमेल पता';

  @override
  String get password => 'पासवर्ड';

  @override
  String get name => 'पूरा नाम';

  @override
  String get phone => 'फोन नंबर';

  @override
  String get state => 'राज्य';

  @override
  String get district => 'ज़िला';

  @override
  String get village => 'गांव / कस्बा';

  @override
  String get mandi => 'मंडी / बाज़ार';

  @override
  String get crop => 'फ़सल / उत्पाद';

  @override
  String get farmerType => 'कृषि विशेषज्ञता';

  @override
  String get selectRole => 'खाता भूमिका चुनें';

  @override
  String get selectAppLanguage => 'ऐप भाषा चुनें';

  @override
  String get selectModule => 'मॉड्यूल चुनें';

  @override
  String get farmerRoleChip => 'किसान 🌾';

  @override
  String get customerRoleChip => 'ग्राहक 🛒';

  @override
  String get farmerLoginTitle => 'किसान लॉग इन (मोबाइल ओटीपी)';

  @override
  String get farmerLoginSubtitle =>
      'अपना पंजीकृत नाम और मोबाइल नंबर दर्ज करें।';

  @override
  String get farmerNameLabel => 'किसान का नाम';

  @override
  String get farmerNameHint => 'अपना पंजीकृत नाम दर्ज करें';

  @override
  String get mobileNumberLabel => 'मोबाइल नंबर';

  @override
  String get emailAndPasswordTab => 'ईमेल और पासवर्ड';

  @override
  String get mobileOtpTab => 'मोबाइल ओटीपी';

  @override
  String get newFarmerPrompt => 'नए किसान हैं? ';

  @override
  String get dontHaveAccountPrompt => 'खाता नहीं है? ';

  @override
  String get createAccount => 'खाता बनाएं';

  @override
  String get adminPortalLogin => 'व्यवस्थापक पोर्टल लॉगिन';

  @override
  String get errEmailPasswordRequired =>
      'कृपया ईमेल और पासवर्ड दोनों दर्ज करें।';

  @override
  String get errFarmerNameRequired => 'कृपया अपना पंजीकृत किसान नाम दर्ज करें।';

  @override
  String get errMobileRequired =>
      'कृपया अपना 10 अंकों का मोबाइल नंबर दर्ज करें।';

  @override
  String get createAccountTitle => 'नया खाता बनाएं';

  @override
  String get createAccountSubtitle =>
      'खरीदारों और किसानों से सीधे जुड़ने के लिए कृषि मित्र में शामिल हों';

  @override
  String get alreadyHaveAccountPrompt => 'पहले से ही एक खाता है? ';

  @override
  String get otpVerificationTitle => 'ओटीपी सत्यापन';

  @override
  String get enterOtpTitle => '6 अंकों का ओटीपी दर्ज करें';

  @override
  String get weSentOtpTo => 'हमने सत्यापन कोड भेजा है:';

  @override
  String get verifyAndProceed => 'सत्यापित करें और आगे बढ़ें';

  @override
  String get resendOtp => 'ओटीपी पुनः भेजें';

  @override
  String get resendCodeIn => 'कोड पुनः भेजें';

  @override
  String get emailOtpVerificationTitle => 'ईमेल ओटीपी सत्यापन';

  @override
  String get enterTerminalOtpDesc =>
      'टर्मिनल में दिखाया गया 6-अंकीय सत्यापन कोड दर्ज करें:';

  @override
  String get generateNewCode => 'नया कोड जनरेट करें';

  @override
  String get newCodeGeneratedInTerminal =>
      'टर्मिनल में नया ओटीपी कोड जनरेट किया गया:';

  @override
  String get emailOtpTab => 'ईमेल ओटीपी';

  @override
  String get errEnterCompleteOtp =>
      'कृपया पूरा 6 अंकों का ओटीपी कोड दर्ज करें।';

  @override
  String get home => 'होम';

  @override
  String get community => 'किसान समुदाय';

  @override
  String get mandiPrices => 'लाइव मंडी भाव';

  @override
  String get pricePrediction => 'मूल्य पूर्वानुमान';

  @override
  String get marketplace => 'कृषि बाज़ार';

  @override
  String get productTimeline => 'उत्पाद समय-सीमा';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get orders => 'मेरे ऑर्डर';

  @override
  String get myProducts => 'मेरे उत्पाद';

  @override
  String get addProduct => 'उत्पाद बेचें';

  @override
  String get buyProducts => 'उत्पाद खरीदें';

  @override
  String get advisory => 'कृषि सलाह';

  @override
  String get schemes => 'सरकारी योजनाएं';

  @override
  String get verifiedFarmer => 'सत्यापित किसान';

  @override
  String get organic => 'जैविक प्रमाणित';

  @override
  String get fpo => 'एफपीओ प्रमाणित';

  @override
  String get qualityChecked => 'गुणवत्ता जांची गई';

  @override
  String get certificateVerified => 'प्रमाणपत्र सत्यापित';

  @override
  String get pendingVerification => 'सत्यापन लंबित';

  @override
  String get quantity => 'मात्रा';

  @override
  String get pricePerUnit => 'मूल्य';

  @override
  String get harvestDate => 'कटाई की तिथि';

  @override
  String get batchId => 'बैच आईडी';

  @override
  String get scanQr => 'क्यूआर कोड स्कैन करें';

  @override
  String get currentPrice => 'वर्तमान मूल्य';

  @override
  String get minPrice => 'न्यूनतम मूल्य';

  @override
  String get maxPrice => 'अधिकतम मूल्य';

  @override
  String get avgPrice => 'औसत मूल्य';

  @override
  String get lastUpdated => 'अंतिम अद्यतन';

  @override
  String get forecast7Days => '7-दिवसीय पूर्वानुमान';

  @override
  String get forecast15Days => '15-दिवसीय पूर्वानुमान';

  @override
  String get forecast30Days => '30-दिवसीय पूर्वानुमान';

  @override
  String get expectedTrend => 'बाजार रुझान';

  @override
  String get confidenceScore => 'विश्वास स्कोर';

  @override
  String get searchPlaceholder => 'फ़सलें, किसान, ज़िले, मंडियाँ खोजें...';

  @override
  String get todaysOrders => 'आज के ऑर्डर';

  @override
  String get productsListed => 'सूचीबद्ध उत्पाद';

  @override
  String get totalRevenue => 'कुल राजस्व';

  @override
  String get pendingDeliveries => 'लंबित डिलीवरी';

  @override
  String get weatherSummary => 'मौसम सारांश';

  @override
  String get welcomeBack => 'वापसी पर स्वागत है';

  @override
  String get quickActions => 'त्वरित कार्य';

  @override
  String get sellCrop => 'फ़सल बेचें';

  @override
  String get buyCrop => 'फ़सल खरीदें';

  @override
  String get category => 'श्रेणी';

  @override
  String get location => 'स्थान';

  @override
  String get addToCart => 'कार्ट में जोड़ें';

  @override
  String get buyNow => 'अभी खरीदें';

  @override
  String get cart => 'शॉपिंग कार्ट';

  @override
  String get checkout => 'चेकआउट';

  @override
  String get totalAmount => 'कुल राशि';

  @override
  String get placeOrder => 'ऑर्डर दें';

  @override
  String get orderSuccess => 'ऑर्डर सफलतापूर्वक दिया गया!';

  @override
  String get createPost => 'पोस्ट बनाएं';

  @override
  String get postPlaceholder =>
      'अपडेट साझा करें, प्रश्न पूछें, या कीमतों पर चर्चा करें...';

  @override
  String get post => 'पोस्ट';

  @override
  String get like => 'लाइक';

  @override
  String get comment => 'टिप्पणी';

  @override
  String get share => 'शेयर';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get verificationStatus => 'सत्यापन स्थिति';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get confirmLogout => 'क्या आप वाकई लॉग आउट करना चाहते हैं?';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get submit => 'सबमिट करें';

  @override
  String get back => 'वापस';

  @override
  String get next => 'आगे';

  @override
  String get previous => 'पिछला';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get viewDetails => 'विवरण देखें';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get noDataFound => 'कोई डेटा नहीं मिला';

  @override
  String get success => 'सफलता';

  @override
  String get error => 'त्रुटि';

  @override
  String get allCommodities => 'सभी वस्तुएं';

  @override
  String get allStates => 'सभी राज्य';

  @override
  String get allDistricts => 'सभी ज़िले';

  @override
  String get helpSupport => 'सहायता और समर्थन';

  @override
  String get aboutApp => 'कृषि मित्र के बारे में';

  @override
  String get sellDirectlyToCustomers => 'ग्राहकों को सीधे बेचें';

  @override
  String get sellDirectlySubtitle =>
      'सबमिट करने पर, आपकी फ़सल स्वचालित रूप से ग्राहक बाज़ार में दिखाई देगी।';

  @override
  String get farmerLocationInfo => 'किसान और स्थान की जानकारी';

  @override
  String get farmLocation => 'खेत का स्थान';

  @override
  String get cropDetailsPricing => 'फ़सल विवरण और मूल्य निर्धारण';

  @override
  String get cropName => 'फ़सल का नाम';

  @override
  String get cropVariety => 'फ़सल की किस्म';

  @override
  String get harvestQty => 'कटाई की मात्रा';

  @override
  String get availableStock => 'उपलब्ध स्टॉक';

  @override
  String get pricePerUnitLabel => 'मूल्य / इकाई';

  @override
  String get supplyChainTraceabilityStatus =>
      'आपूर्ति श्रृंखला और पता लगाने की स्थिति';

  @override
  String get change => 'बदलें';

  @override
  String get expectedDeliveryTime => 'अपेक्षित डिलीवरी समय';

  @override
  String get listCropForSale => 'बिक्री के लिए फ़सल सूचीबद्ध करें';

  @override
  String get organicCertified => 'जैविक प्रमाणित';

  @override
  String get fpoCertified => 'एफपीओ प्रमाणित';

  @override
  String get uploadCropPhoto => 'फ़सल की फोटो अपलोड करें';

  @override
  String get salesAnalyticsOverview => 'बिक्री विश्लेषण और राजस्व अवलोकन';

  @override
  String get productsSold => 'बेचे गए उत्पाद';

  @override
  String get totalOrders => 'कुल ऑर्डर';

  @override
  String get pendingOrders => 'लंबित ऑर्डर';

  @override
  String get completedOrders => 'पूरे किए गए ऑर्डर';

  @override
  String get averageRating => 'औसत रेटिंग';

  @override
  String get noReviewsYet => 'अभी तक कोई समीक्षा नहीं';

  @override
  String get farmerResponsibilitiesActions => 'किसान जिम्मेदारियां और कार्य';

  @override
  String get listNewHarvest => 'नई कटाई सूचीबद्ध करें';

  @override
  String get manageListings => 'सूचियों का प्रबंधन करें';

  @override
  String get ordersReceived => 'प्राप्त ऑर्डर';

  @override
  String get manageBuyers => 'खरीदारों का प्रबंधन करें';

  @override
  String get checkApmcRates => 'एपीएमसी दरें जांचें';

  @override
  String get farmerCommunity => 'किसान समुदाय';

  @override
  String get qnaMachinery => 'प्रश्नोत्तर और मशीनरी';

  @override
  String get recentCustomerOrders => 'हाल के ग्राहक ऑर्डर';

  @override
  String get viewAllOrders => 'सभी ऑर्डर देखें';

  @override
  String get noCustomerOrders => 'अभी तक कोई ग्राहक ऑर्डर प्राप्त नहीं हुआ।';

  @override
  String get buyerStatus => 'खरीदार';

  @override
  String get productPerformanceBreakdown => 'उत्पाद प्रदर्शन विवरण';

  @override
  String get noActiveCrops => 'अभी तक कोई सक्रिय फ़सल सूचीबद्ध नहीं है।';

  @override
  String get varietyStock => 'किस्म';

  @override
  String get soldOrders => 'बेचा गया';

  @override
  String get noRatings => 'कोई रेटिंग नहीं';

  @override
  String get customerFeedbackRatings => 'ग्राहक प्रतिक्रिया और रेटिंग';

  @override
  String get noCustomerFeedback =>
      'अभी तक कोई ग्राहक प्रतिक्रिया प्राप्त नहीं हुई।';

  @override
  String get accountVerificationPendingTitle => 'खाता सत्यापन लंबित';

  @override
  String get accountVerificationPendingDesc =>
      'आपकी किसान प्रोफ़ाइल सरकारी/व्यवस्थापक अधिकारियों की समीक्षाधीन है। बाज़ार सुविधाएं सक्रिय रहेंगी।';

  @override
  String get categoryVegetables => 'सब्ज़ियाँ';

  @override
  String get categoryFruits => 'फल';

  @override
  String get categoryGrains => 'अनाज';

  @override
  String get categoryPulses => 'दालें';

  @override
  String get categorySpices => 'मसाले';

  @override
  String get categoryOrganic => 'जैविक उत्पाद';

  @override
  String get unitKg => 'किग्रा';

  @override
  String get unitQuintal => 'क्विंटल';

  @override
  String get unitTon => 'टन';

  @override
  String get unitDozen => 'दर्जन';

  @override
  String get unitItem => 'इकाई';

  @override
  String get farmerTypeOrganic => 'जैविक किसान';

  @override
  String get farmerTypeGrainPaddy => 'धान एवं अनाज उत्पादक';

  @override
  String get farmerTypeHorticulture => 'बागवानी एवं फल';

  @override
  String get farmerTypeVegetable => 'सब्जी उत्पादक';

  @override
  String get farmerTypeSpices => 'मसाले एवं वृक्षारोपण';

  @override
  String get farmerTypeDairy => 'डेयरी एवं मिश्रित खेती';

  @override
  String get deliveringTo => 'डिलीवरी स्थान';

  @override
  String get marketplaceTitle => 'कृषि मित्र बाज़ार 🌾';

  @override
  String get bannerTitle1 => 'खेत की ताज़ा फ़सलें';

  @override
  String get bannerSubtitle1 =>
      'शून्य कमीशन पर सत्यापित भारतीय किसानों से सीधे';

  @override
  String get bannerTitle2 => 'क्यूआर कोड द्वारा ट्रैसेबिलिटी';

  @override
  String get bannerSubtitle2 =>
      'बीज से घर तक की यात्रा देखने के लिए क्यूआर स्कैन करें';

  @override
  String get bannerTitle3 => '100% जैविक और एफपीओ प्रमाणित';

  @override
  String get bannerSubtitle3 => 'रसायन मुक्त स्वच्छ कटाई वाली सत्यापित फ़सलें';

  @override
  String get nearbyFarmersBannerTitle => '📍 नजदीकी किसान और स्थानीय फ़सलें';

  @override
  String get nearbyFarmersBannerSubtitle =>
      'दूरी के दायरे से फ़सलें फ़िल्टर करें (5 किमी, 10 किमी, 20 किमी)';

  @override
  String get browseMarket => 'बाज़ार देखें';

  @override
  String get nearbyFarmers => 'नजदीकी किसान';

  @override
  String get mandiRates => 'मंडी भाव';

  @override
  String get browseCategories => 'श्रेणियां देखें';

  @override
  String get freshFarmHarvests => 'ताज़ा कृषि उपज';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get addedToCartSnackbar => 'सफलतापूर्वक कार्ट में जोड़ा गया!';

  @override
  String get communityTitle => 'किसान ज्ञान साझाकरण और समुदाय';

  @override
  String get postQuestionBtn => 'कृषि प्रश्न / फ़सल बिक्री पोस्ट करें';

  @override
  String get allPosts => 'सभी पोस्ट';

  @override
  String get machineryTools => 'मशीनरी और उपकरण';

  @override
  String get agriQna => 'कृषि प्रश्नोत्तर';

  @override
  String get priceAlerts => 'मूल्य अलर्ट';

  @override
  String get noCommunityPosts => 'कोई समुदाय पोस्ट नहीं मिली।';

  @override
  String get createPostSubtitle =>
      'अपना खेती का अनुभव, प्रश्न या मशीन किराया साझा करें...';

  @override
  String get schemesTitle => 'सरकारी सब्सिडी और किसान योजनाएं';

  @override
  String get schemesSubtitle => 'प्रत्यक्ष लाभ अंतरण (DBT) और कृषि सहायता';

  @override
  String get applyNow => 'अभी आवेदन करें';

  @override
  String get schemeDetails => 'योजना विवरण';

  @override
  String get advisoryTitle => 'कृषि सलाह और हेल्पलाइन';

  @override
  String get advisorySubtitle => 'फ़सल रोग निदान और मौसम सलाह';

  @override
  String get askAiAgronomist => 'एआई कृषि विशेषज्ञ से पूछें';

  @override
  String get mandiScreenTitle => 'एपीएमसी लाइव मंडी बाज़ार भाव';

  @override
  String get mandiScreenSubtitle => 'एगमार्कनेट वास्तविक समय दैनिक थोक दरें';

  @override
  String get filterState => 'राज्य फ़िल्टर करें';

  @override
  String get filterDistrict => 'ज़िला फ़िल्टर करें';

  @override
  String get filterCommodity => 'वस्तु फ़िल्टर करें';

  @override
  String get pricePredictionTitle => 'एआई मूल्य पूर्वानुमान और बाज़ार रुझान';

  @override
  String get pricePredictionSubtitle =>
      '7-दिवसीय, 15-दिवसीय और 30-दिवसीय एपीएमसी दर पूर्वानुमान';

  @override
  String get timelineTitle => 'खेत से घर तक ट्रैसेबिलिटी समय-सीमा';

  @override
  String get timelineSubtitle => 'सत्यापित बीज से थाली तक की यात्रा';

  @override
  String get scanQrCodeTitle => 'फ़सल क्यूआर कोड स्कैन करें';

  @override
  String get alignCameraNotice => 'उत्पाद के क्यूआर कोड पर कैमरा संरेखित करें';

  @override
  String get officerPortal => 'अधिकारी पोर्टल';

  @override
  String get adminPortalTitle => 'सरकारी एवं व्यवस्थापक सत्यापन पोर्टल';

  @override
  String get pendingVerifications => 'लंबित सत्यापन आवेदन';

  @override
  String get verifyFarmer => 'किसान को सत्यापित करें';

  @override
  String get rejectApplication => 'आवेदन अस्वीकार करें';

  @override
  String get noOrdersPlaced => 'अभी तक कोई ऑर्डर नहीं दिया गया है';

  @override
  String get totalPrice => 'कुल मूल्य';

  @override
  String get enterMobilePrompt => 'कृपया एक मान्य मोबाइल नंबर दर्ज करें';

  @override
  String get ok => 'ठीक है';

  @override
  String get myOrdersAndTraceability => 'मेरे ऑर्डर और ट्रेसिबिलिटी';

  @override
  String get submitReview => 'समीक्षा सबमिट करें';

  @override
  String get accessDenied => 'पहुँच अस्वीकृत';

  @override
  String get adminPrivilegesRequired =>
      'पहुँच अस्वीकृत: एडमिन अधिकार आवश्यक हैं';

  @override
  String get productApprovals => 'उत्पाद अनुमोदन';

  @override
  String get registrationConfirmationTitle => 'पंजीकरण पुष्टिकरण';

  @override
  String get registrationSuccessfulTitle => 'पंजीकरण सफल!';

  @override
  String get farmerRegistrationSuccessDesc =>
      'आपका किसान खाता सफलतापूर्वक पंजीकृत हो गया है। अब आप अपनी प्रोफ़ाइल और उपज का प्रबंधन करने के लिए लॉग इन कर सकते हैं।';

  @override
  String get customerRegistrationSuccessDesc =>
      'आपका ग्राहक खाता सफलतापूर्वक पंजीकृत हो गया है। अब आप ताज़ा कृषि उत्पाद देखने के लिए लॉग इन कर सकते हैं।';

  @override
  String get farmerProfileSummary => 'किसान प्रोफ़ाइल विवरण';

  @override
  String get customerProfileSummary => 'ग्राहक प्रोफ़ाइल विवरण';

  @override
  String get fullNameLabel => 'पूरा नाम';

  @override
  String get emailAddressLabel => 'ईमेल पता';

  @override
  String get accountRoleLabel => 'खाता भूमिका';

  @override
  String get stateLabel => 'राज्य';

  @override
  String get districtLabel => 'ज़िला';

  @override
  String get villageLabel => 'गांव / कस्बा';

  @override
  String get farmerTypeLabel => 'कृषि प्रकार';

  @override
  String get verificationStatusLabel => 'सत्यापन स्थिति';

  @override
  String get verifiedStatus => 'सत्यापित';

  @override
  String get pendingVerificationStatus => 'सत्यापन लंबित';

  @override
  String get uploadedCertificateLabel => 'अपलोड किया गया प्रमाणपत्र';

  @override
  String get continueToLoginButton => 'लॉगिन करने के लिए आगे बढ़ें';

  @override
  String get availableStockLabel => 'उपलब्ध स्टॉक';

  @override
  String get outOfStock => 'स्टॉक समाप्त';

  @override
  String get bulkDiscountTitle => 'थोक ऑर्डर छूट';

  @override
  String get bulkPriceNotice => 'विशेष थोक मूल्य उपलब्ध!';

  @override
  String get unitPrice => 'प्रति इकाई मूल्य';

  @override
  String get discountAmount => 'छूट की बचत';

  @override
  String get confirmRejection => 'अस्वीकृति की पुष्टि करें';

  @override
  String get rejectionReasonHint => 'अस्वीकृति का कारण / टिप्पणी दर्ज करें...';

  @override
  String get reject => 'अस्वीकार करें';

  @override
  String get approveAndVerify => 'स्वीकृत एवं सत्यापित करें';

  @override
  String get approveAndPublish => 'स्वीकृत एवं प्रकाशित करें';

  @override
  String get rejectProduct => 'उत्पाद अस्वीकार करें';

  @override
  String get copyLink => 'लिंक कॉपी करें';

  @override
  String get copiedLinkSnackbar => 'सार्वजनिक क्यूआर ट्रेस लिंक कॉपी किया गया!';

  @override
  String get scanQrTimeline => 'क्यूआर टाइमलाइन स्कैन करें';

  @override
  String get openAppTimeline => 'ऐप टाइमलाइन खोलें';

  @override
  String get addedToCart => 'सफलतापूर्वक कार्ट में जोड़ा गया!';

  @override
  String get close => 'बंद करें';

  @override
  String get allNotificationsRead =>
      'सभी सूचनाएं पढ़ी गई के रूप में चिह्नित की गईं।';

  @override
  String get noOrdersRecordedYet =>
      'अभी तक कोई प्लेटफ़ॉर्म ऑर्डर दर्ज नहीं किया गया है।';

  @override
  String get orderIdLabel => 'ऑर्डर';

  @override
  String get buyerLabel => 'खरीदार';

  @override
  String get farmerLabel => 'किसान';

  @override
  String get productLabel => 'उत्पाद';

  @override
  String get quantityLabel => 'मात्रा';

  @override
  String get statusLabel => 'स्थिति';

  @override
  String get paymentLabel => 'भुगतान';

  @override
  String get roleLabel => 'भूमिका';

  @override
  String get locationLabel => 'स्थान';

  @override
  String get phoneLabel => 'फोन';

  @override
  String get noUsersRegisteredYet => 'अभी तक कोई उपयोगकर्ता पंजीकृत नहीं है।';

  @override
  String get allFilter => 'सभी';

  @override
  String get pendingFilter => 'लंबित';

  @override
  String get approvedFilter => 'स्वीकृत';

  @override
  String get rejectedFilter => 'अस्वीकृत';

  @override
  String get searchCropPlaceholder => 'फ़सल खोजें (जैसे टमाटर, चावल, आलू)...';

  @override
  String get organicCropTag => 'जैविक फ़सल टैग';

  @override
  String get organicCropTagSubtitle =>
      'सिंथेटिक रसायनों के बिना 100% प्राकृतिक रूप से उगाई गई';

  @override
  String get verifiedFarmerBadge => 'सत्यापित किसान बैज';

  @override
  String get verifiedFarmerBadgeSubtitle =>
      'सरकारी / एफपीओ किसान सत्यापन सक्रिय';

  @override
  String get publishInMarketplace => 'बाज़ार में प्रकाशित करें';

  @override
  String get publishInMarketplaceSubtitle =>
      'बाज़ार में ग्राहकों को दिखाई देगा';

  @override
  String get minBulkQtyLabel => 'न्यूनतम थोक मात्रा';

  @override
  String get bulkPricePerUnitLabel => 'थोक मूल्य / इकाई (₹)';

  @override
  String get optionalCertificateInfo => 'वैकल्पिक प्रमाणपत्र जानकारी';

  @override
  String get cropImageUrlLabel => 'फ़सल छवि यूआरएल';

  @override
  String get publicTraceabilityLink =>
      'सार्वजनिक पता लगाने की क्षमता (ट्रेसिबिलिटी) लिंक';

  @override
  String get editTimelineStages => 'उत्पाद टाइमलाइन और चरण संपादित करें';

  @override
  String get previewCustomerPage => 'सार्वजनिक ग्राहक पृष्ठ पूर्वावलोकन';

  @override
  String get farmerTraceabilityQr => 'किसान ट्रेसिबिलिटी क्यूआर';

  @override
  String get variety => 'किस्म';

  @override
  String get launchScanner => 'कैमरा स्कैनर शुरू करें';

  @override
  String get closeScanner => 'कैमरा स्कैनर बंद करें';

  @override
  String get scanBatchBtn => 'बैच स्कैन करें';

  @override
  String get manualBatchHint => 'बैच आईडी दर्ज करें (उदा. TOM-ERD-101)';

  @override
  String get editProductTimelineTitle => 'उत्पाद टाइमलाइन संपादित करें';

  @override
  String get timelineSavedSnackbar =>
      'उत्पाद टाइमलाइन सुरक्षित की गई! सार्वजनिक क्यूआर अपडेट हुआ।';

  @override
  String get qualityGradeTitle => 'गुणवत्ता श्रेणी एवं प्रमाणीकरण';

  @override
  String get qualityGradeLabel => 'गुणवत्ता स्थिति / ग्रेड';

  @override
  String get certificationInfoLabel => 'प्रमाणपत्र जानकारी';

  @override
  String get saveTimelineBtn => 'उत्पाद टाइमलाइन को सहेजें';

  @override
  String get savingTimelineBtn => 'सहेजा जा रहा है...';

  @override
  String get selectDate => 'तिथि चुनें';

  @override
  String get selectTime => 'समय चुनें';

  @override
  String get eventDescription => 'घटना विवरण';

  @override
  String get eligibility => 'पात्रता';

  @override
  String get keyBenefits => 'मुख्य लाभ';

  @override
  String get categoryLabel => 'श्रेणी';

  @override
  String get helpful => 'सहायक';

  @override
  String get replies => 'उत्तर';

  @override
  String get farmerReply => 'किसान का उत्तर';

  @override
  String get replyHint => 'किसान चर्चा का उत्तर दें...';

  @override
  String get qualityAndTrust => 'गुणवत्ता एवं भरोसा';

  @override
  String get qualityVerified => 'गुणवत्ता सत्यापित';

  @override
  String get organicCertificateVerified => 'जैविक प्रमाणपत्र सत्यापित';

  @override
  String get deliveryCharge => 'डिलीवरी शुल्क';

  @override
  String get productSubtotal => 'उत्पाद उपयोग';

  @override
  String get discountSavings => 'छूट की बचत';

  @override
  String get finalTotal => 'कुल राशि';

  @override
  String get reportQualityIssue => 'गुणवत्ता संबंधी शिकायत करें';

  @override
  String get spoiledProduce => 'खराब उपज';

  @override
  String get poorQuality => 'खराब गुणवत्ता';

  @override
  String get incorrectQuality => 'गलत गुणवत्ता';

  @override
  String get otherQualityIssue => 'अन्य गुणवत्ता समस्या';

  @override
  String get complaintSubmitted => 'गुणवत्ता शिकायत सफलतापूर्वक दर्ज की गई!';

  @override
  String get adminVerification => 'एडमिन सत्यापन';

  @override
  String get verifyCertificate => 'प्रमाणपत्र सत्यापित करें';

  @override
  String get verifyBatch => 'बैच सत्यापित करें';

  @override
  String get reviewComplaint => 'शिकायत की समीक्षा करें';

  @override
  String get approve => 'स्वीकृत करें';

  @override
  String get needsReview => 'पुनरावलोकन आवश्यक';

  @override
  String get rejectionReason => 'अस्वीकृति का कारण / टिप्पणी';

  @override
  String get organicCertificates => 'जैविक प्रमाणपत्र';

  @override
  String get harvestBatches => 'कटाई बैच';

  @override
  String get qualityComplaints => 'गुणवत्ता शिकायतें';

  @override
  String get issueType => 'समस्या का प्रकार';

  @override
  String get complaintDescription => 'शिकायत का विवरण';

  @override
  String get photoEvidence => 'फ़ोटो साक्ष्य (वैकल्पिक)';

  @override
  String get deliveryPartner => 'डिलीवरी पार्टनर';

  @override
  String get deliveryStatus => 'डिलीवरी की स्थिति';

  @override
  String get deliveryDetails => 'डिलीवरी विवरण';

  @override
  String get pickupLocation => 'पिकअप स्थान';

  @override
  String get deliveryAddress => 'डिलीवरी का पता';

  @override
  String get assignedPartner => 'सौंपा गया पार्टनर';

  @override
  String get assignDeliveryPartner => 'डिलीवरी पार्टनर सौंपें';

  @override
  String get updateDeliveryStatus => 'डिलीवरी स्थिति अपडेट करें';

  @override
  String get deliveryStatusPlaced => 'ऑर्डर दिया गया';

  @override
  String get deliveryStatusAssigned => 'सौंपा गया';

  @override
  String get deliveryStatusPickup => 'पिकअप';

  @override
  String get deliveryStatusInTransit => 'मार्ग में है';

  @override
  String get deliveryStatusDelivered => 'डिलीवर हो गया';

  @override
  String get enterAddress => 'पता दर्ज करें';

  @override
  String get distance => 'दूरी';

  @override
  String get deliveryFee => 'डिलीवरी शुल्क';

  @override
  String get address => 'पता';

  @override
  String get addAddress => 'पता जोड़ें';

  @override
  String get editAddress => 'पता संपादित करें';

  @override
  String get paymentMethod => 'भुगतान का तरीका';

  @override
  String get paymentUpi => 'यूपीआई (UPI)';

  @override
  String get paymentCard => 'क्रेडिट कार्ड / डेबिट कार्ड';

  @override
  String get paymentCod => 'कैश ऑन डिलीवरी (COD)';

  @override
  String deliveryFeeForKm(String distance, String fee) {
    return '$distance किमी के लिए डिलीवरी शुल्क - ₹$fee';
  }

  @override
  String deliveryFeeLabelForKm(String distance) {
    return '$distance किमी के लिए डिलीवरी शुल्क';
  }
}
