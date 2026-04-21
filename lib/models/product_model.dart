// Supported units for products in the Kirana store
enum ProductUnit { kg, g, litre, ml, pcs }

extension ProductUnitExtension on ProductUnit {
  String get label {
    switch (this) {
      case ProductUnit.kg:
        return 'kg';
      case ProductUnit.g:
        return 'g';
      case ProductUnit.litre:
        return 'litre';
      case ProductUnit.ml:
        return 'ml';
      case ProductUnit.pcs:
        return 'pcs';
    }
  }

  String get displayName {
    switch (this) {
      case ProductUnit.kg:
        return 'Kilogram (kg)';
      case ProductUnit.g:
        return 'Gram (g)';
      case ProductUnit.litre:
        return 'Litre (L)';
      case ProductUnit.ml:
        return 'Millilitre (ml)';
      case ProductUnit.pcs:
        return 'Pieces (pcs)';
    }
  }

  // The step used when adding to cart: 0.5 kg, 100 g, 0.5 L, 100 ml, 1 pcs
  double get cartStep {
    switch (this) {
      case ProductUnit.kg:
        return 0.5;
      case ProductUnit.g:
        return 100;
      case ProductUnit.litre:
        return 0.5;
      case ProductUnit.ml:
        return 100;
      case ProductUnit.pcs:
        return 1;
    }
  }

  // The minimum quantity that can be added
  double get minQty {
    switch (this) {
      case ProductUnit.kg:
        return 0.5;
      case ProductUnit.g:
        return 100;
      case ProductUnit.litre:
        return 0.5;
      case ProductUnit.ml:
        return 100;
      case ProductUnit.pcs:
        return 1;
    }
  }

  static ProductUnit fromString(String? value) {
    switch (value) {
      case 'kg':
        return ProductUnit.kg;
      case 'g':
        return ProductUnit.g;
      case 'litre':
        return ProductUnit.litre;
      case 'ml':
        return ProductUnit.ml;
      default:
        return ProductUnit.pcs;
    }
  }
}

class Product {
  String id;
  String name;
  double price;      // price per unit (per kg, per g, per pcs, etc.)
  double quantity;   // total stock in the selected unit
  ProductUnit unit;  // unit of measurement

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.unit = ProductUnit.pcs,
  });

  /// Human-readable quantity string e.g. "5 kg", "500 g", "12 pcs"
  String get quantityDisplay {
    if (unit == ProductUnit.pcs) {
      return '${quantity.toInt()} ${unit.label}';
    }
    // Show without decimal if whole number
    final qStr = quantity == quantity.truncateToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(2);
    return '$qStr ${unit.label}';
  }

  /// Price label e.g. "₹120 / kg"
  String get priceDisplay => '₹${price.toStringAsFixed(2)} / ${unit.label}';

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'unit': unit.label,
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: ProductUnitExtension.fromString(map['unit']),
    );
  }
}