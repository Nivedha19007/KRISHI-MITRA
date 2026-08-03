class SchemeModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final String eligibility;
  final String benefits;
  final String applicationProcess;
  final String officialUrl;

  SchemeModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.eligibility,
    required this.benefits,
    required this.applicationProcess,
    this.officialUrl = 'https://pmkisan.gov.in',
  });
}
