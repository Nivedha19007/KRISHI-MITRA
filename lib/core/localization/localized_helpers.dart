import 'package:flutter/material.dart';
import 'locale_provider.dart';
export 'locale_provider.dart';

/// Helper utility for mapping fixed internal database/API string keys
/// (e.g. "Vegetables", "kg", "Organic Farmer") to localized display strings.
class LocalizedHelpers {
  /// Localized category display name
  static String getCategoryName(BuildContext context, String rawCategory) {
    final l10n = context.l10n;
    switch (rawCategory.trim().toLowerCase()) {
      case 'vegetables':
      case 'vegetable':
        return l10n.categoryVegetables;
      case 'fruits':
      case 'fruit':
        return l10n.categoryFruits;
      case 'grains':
      case 'grain':
      case 'grains & paddy':
      case 'cereals':
        return l10n.categoryGrains;
      case 'pulses':
      case 'pulse':
      case 'legumes':
        return l10n.categoryPulses;
      case 'spices':
      case 'spice':
      case 'herbs':
        return l10n.categorySpices;
      case 'organic':
      case 'organic certified':
        return l10n.categoryOrganic;
      default:
        return rawCategory;
    }
  }

  /// Localized unit display name
  static String getUnitName(BuildContext context, String rawUnit) {
    final l10n = context.l10n;
    switch (rawUnit.trim().toLowerCase()) {
      case 'kg':
      case 'kilo':
      case 'kilogram':
        return l10n.unitKg;
      case 'quintal':
      case 'qtl':
        return l10n.unitQuintal;
      case 'ton':
      case 'tonne':
        return l10n.unitTon;
      case 'dozen':
      case 'doz':
        return l10n.unitDozen;
      case 'item':
      case 'piece':
      case 'pcs':
        return l10n.unitItem;
      default:
        return rawUnit;
    }
  }

  /// Localized farming specialty display name
  static String getFarmerTypeName(BuildContext context, String rawType) {
    final l10n = context.l10n;
    switch (rawType.trim().toLowerCase()) {
      case 'organic farmer':
        return l10n.farmerTypeOrganic;
      case 'grain & paddy producer':
      case 'grain producer':
        return l10n.farmerTypeGrainPaddy;
      case 'horticulture & fruits':
      case 'horticulture':
        return l10n.farmerTypeHorticulture;
      case 'vegetable cultivator':
      case 'vegetable farmer':
        return l10n.farmerTypeVegetable;
      case 'spices & plantation':
      case 'spice farmer':
        return l10n.farmerTypeSpices;
      case 'dairy & mixed farming':
      case 'dairy farmer':
        return l10n.farmerTypeDairy;
      default:
        return rawType;
    }
  }
}
