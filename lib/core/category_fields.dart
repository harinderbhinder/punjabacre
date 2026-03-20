// ignore_for_file: dangling_library_doc_comments
/// Dynamic field definitions per category.

enum FieldType { text, number, dropdown }

class CategoryField {
  final String key;
  final String label;
  final FieldType type;
  final List<String> options;
  final bool required;

  const CategoryField({
    required this.key,
    required this.label,
    this.type = FieldType.text,
    this.options = const [],
    this.required = false,
  });
}

class CategoryFieldGroup {
  final List<String> keywords;
  final List<CategoryField> fields;
  const CategoryFieldGroup({required this.keywords, required this.fields});
}

// ── Field lists ──────────────────────────────────────────────────────────────

const _propertyFields = [
  CategoryField(
    key: 'purpose',
    label: 'Purpose',
    type: FieldType.dropdown,
    options: ['For Sale', 'For Rent'],
    required: true,
  ),
  CategoryField(key: 'areaSize', label: 'Area Size', type: FieldType.text),
  CategoryField(
    key: 'areaUnit',
    label: 'Area Unit',
    type: FieldType.dropdown,
    options: ['Marla', 'Kanal', 'Sq Ft', 'Sq Yd', 'Sq M'],
  ),
  CategoryField(
    key: 'bedrooms',
    label: 'Bedrooms',
    type: FieldType.dropdown,
    options: ['Studio', '1', '2', '3', '4', '5', '6+'],
  ),
  CategoryField(
    key: 'bathrooms',
    label: 'Bathrooms',
    type: FieldType.dropdown,
    options: ['1', '2', '3', '4', '5+'],
  ),
  CategoryField(
    key: 'furnishing',
    label: 'Furnishing',
    type: FieldType.dropdown,
    options: ['Furnished', 'Semi-Furnished', 'Unfurnished'],
  ),
];

const _commercialFields = [
  CategoryField(
    key: 'purpose',
    label: 'Purpose',
    type: FieldType.dropdown,
    options: ['For Sale', 'For Rent'],
    required: true,
  ),
  CategoryField(key: 'areaSize', label: 'Area Size', type: FieldType.text),
  CategoryField(
    key: 'areaUnit',
    label: 'Area Unit',
    type: FieldType.dropdown,
    options: ['Marla', 'Kanal', 'Sq Ft', 'Sq Yd', 'Sq M'],
  ),
  CategoryField(key: 'floor', label: 'Floor / Level', type: FieldType.text),
  CategoryField(
    key: 'furnishing',
    label: 'Furnishing',
    type: FieldType.dropdown,
    options: ['Furnished', 'Semi-Furnished', 'Unfurnished'],
  ),
];

const _plotFields = [
  CategoryField(
    key: 'purpose',
    label: 'Purpose',
    type: FieldType.dropdown,
    options: ['For Sale', 'For Rent'],
    required: true,
  ),
  CategoryField(
    key: 'areaSize',
    label: 'Area Size',
    type: FieldType.text,
    required: true,
  ),
  CategoryField(
    key: 'areaUnit',
    label: 'Area Unit',
    type: FieldType.dropdown,
    options: ['Marla', 'Kanal', 'Sq Ft', 'Sq Yd', 'Sq M'],
  ),
  CategoryField(
    key: 'plotType',
    label: 'Plot Type',
    type: FieldType.dropdown,
    options: ['Residential', 'Commercial', 'Agricultural', 'Industrial'],
  ),
];

const _vehicleFields = [
  CategoryField(
    key: 'year',
    label: 'Year',
    type: FieldType.number,
    required: true,
  ),
  CategoryField(key: 'mileage', label: 'Mileage (km)', type: FieldType.number),
  CategoryField(
    key: 'fuelType',
    label: 'Fuel Type',
    type: FieldType.dropdown,
    options: ['Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid'],
  ),
  CategoryField(
    key: 'transmission',
    label: 'Transmission',
    type: FieldType.dropdown,
    options: ['Manual', 'Automatic'],
  ),
  CategoryField(key: 'color', label: 'Color', type: FieldType.text),
  CategoryField(
    key: 'condition',
    label: 'Condition',
    type: FieldType.dropdown,
    options: ['New', 'Used - Like New', 'Used - Good', 'Used - Fair'],
  ),
  CategoryField(key: 'engineCC', label: 'Engine (cc)', type: FieldType.number),
];

const _electronicsFields = [
  CategoryField(
    key: 'condition',
    label: 'Condition',
    type: FieldType.dropdown,
    options: [
      'New',
      'Open Box',
      'Used - Like New',
      'Used - Good',
      'Used - Fair',
    ],
    required: true,
  ),
  CategoryField(
    key: 'storage',
    label: 'Storage',
    type: FieldType.dropdown,
    options: ['16GB', '32GB', '64GB', '128GB', '256GB', '512GB', '1TB'],
  ),
  CategoryField(
    key: 'ram',
    label: 'RAM',
    type: FieldType.dropdown,
    options: ['2GB', '3GB', '4GB', '6GB', '8GB', '12GB', '16GB', '32GB'],
  ),
  CategoryField(key: 'color', label: 'Color', type: FieldType.text),
  CategoryField(
    key: 'warranty',
    label: 'Warranty',
    type: FieldType.dropdown,
    options: ['No Warranty', 'Under Warranty', 'Extended Warranty'],
  ),
];

const _jobFields = [
  CategoryField(
    key: 'jobType',
    label: 'Job Type',
    type: FieldType.dropdown,
    options: ['Full Time', 'Part Time', 'Contract', 'Freelance', 'Internship'],
    required: true,
  ),
  CategoryField(
    key: 'salaryType',
    label: 'Salary Type',
    type: FieldType.dropdown,
    options: ['Monthly', 'Weekly', 'Daily', 'Hourly', 'Commission'],
  ),
  CategoryField(
    key: 'experience',
    label: 'Experience Required',
    type: FieldType.dropdown,
    options: [
      'No Experience',
      'Less than 1 year',
      '1-2 years',
      '3-5 years',
      '5+ years',
    ],
  ),
  CategoryField(key: 'company', label: 'Company Name', type: FieldType.text),
  CategoryField(
    key: 'education',
    label: 'Education',
    type: FieldType.dropdown,
    options: ['Matric', 'Intermediate', 'Bachelor', 'Master', 'PhD', 'Any'],
  ),
];

const _serviceFields = [
  CategoryField(
    key: 'serviceType',
    label: 'Service Type',
    type: FieldType.text,
    required: true,
  ),
  CategoryField(
    key: 'experience',
    label: 'Experience',
    type: FieldType.dropdown,
    options: [
      'Less than 1 year',
      '1-2 years',
      '3-5 years',
      '5-10 years',
      '10+ years',
    ],
  ),
  CategoryField(
    key: 'availability',
    label: 'Availability',
    type: FieldType.dropdown,
    options: ['Full Time', 'Part Time', 'Weekends Only', 'On Call'],
  ),
];

const _animalFields = [
  CategoryField(key: 'breed', label: 'Breed', type: FieldType.text),
  CategoryField(key: 'age', label: 'Age', type: FieldType.text),
  CategoryField(
    key: 'gender',
    label: 'Gender',
    type: FieldType.dropdown,
    options: ['Male', 'Female', 'Unknown'],
  ),
  CategoryField(
    key: 'vaccinated',
    label: 'Vaccinated',
    type: FieldType.dropdown,
    options: ['Yes', 'No', 'Partially'],
  ),
];

const _furnitureFields = [
  CategoryField(
    key: 'condition',
    label: 'Condition',
    type: FieldType.dropdown,
    options: ['New', 'Like New', 'Good', 'Fair'],
    required: true,
  ),
  CategoryField(
    key: 'material',
    label: 'Material',
    type: FieldType.dropdown,
    options: [
      'Wood',
      'Metal',
      'Plastic',
      'Glass',
      'Fabric',
      'Leather',
      'Mixed',
    ],
  ),
  CategoryField(key: 'color', label: 'Color', type: FieldType.text),
];

// ── Keyword groups ────────────────────────────────────────────────────────────

const List<CategoryFieldGroup> categoryFieldGroups = [
  // Residential property
  CategoryFieldGroup(
    keywords: [
      'house',
      'home',
      'apartment',
      'flat',
      'room',
      'portion',
      'villa',
      'bungalow',
      'penthouse',
      'kothi',
      'residential',
    ],
    fields: _propertyFields,
  ),

  // Commercial property
  CategoryFieldGroup(
    keywords: [
      'shop',
      'booth',
      'store',
      'warehouse',
      'office',
      'commercial',
      'business',
      'showroom',
      'factory',
      'plaza',
      'building',
    ],
    fields: _commercialFields,
  ),

  // Land / Plots
  CategoryFieldGroup(
    keywords: [
      'plot',
      'land',
      'agriculture',
      'farm',
      'tubewell',
      'industrial',
      'sector',
      'block',
      'scheme',
    ],
    fields: _plotFields,
  ),

  // Vehicles
  CategoryFieldGroup(
    keywords: [
      'car',
      'vehicle',
      'bike',
      'motorcycle',
      'auto',
      'truck',
      'van',
      'bus',
      'scooter',
      'rickshaw',
      'loader',
      'tractor',
      'jeep',
      'suv',
    ],
    fields: _vehicleFields,
  ),

  // Electronics / Mobiles
  CategoryFieldGroup(
    keywords: [
      'mobile',
      'phone',
      'electronic',
      'laptop',
      'computer',
      'tablet',
      'gadget',
      'camera',
      'tv',
      'television',
      'monitor',
      'printer',
      'speaker',
      'headphone',
      'watch',
      'smartwatch',
    ],
    fields: _electronicsFields,
  ),

  // Jobs
  CategoryFieldGroup(
    keywords: [
      'job',
      'career',
      'vacancy',
      'hiring',
      'employment',
      'work',
      'staff',
    ],
    fields: _jobFields,
  ),

  // Services
  CategoryFieldGroup(
    keywords: [
      'service',
      'repair',
      'maintenance',
      'cleaning',
      'plumber',
      'electrician',
      'tutor',
      'teacher',
      'driver',
      'cook',
      'tailor',
    ],
    fields: _serviceFields,
  ),

  // Animals / Pets
  CategoryFieldGroup(
    keywords: [
      'animal',
      'pet',
      'dog',
      'cat',
      'bird',
      'fish',
      'livestock',
      'cattle',
      'goat',
      'cow',
      'horse',
      'rabbit',
      'parrot',
      'hen',
      'sheep',
      'buffalo',
    ],
    fields: _animalFields,
  ),

  // Furniture / Home
  CategoryFieldGroup(
    keywords: [
      'furniture',
      'sofa',
      'bed',
      'table',
      'chair',
      'wardrobe',
      'cabinet',
      'desk',
      'shelf',
      'cupboard',
      'mattress',
      'appliance',
    ],
    fields: _furnitureFields,
  ),
];

/// Returns the matching field group for a given category name.
/// Falls back to commercial property fields if nothing matches
/// (since most unrecognised categories in this app are property-related).
CategoryFieldGroup? getFieldsForCategory(String categoryName) {
  final lower = categoryName.toLowerCase();

  // 1. Try keyword match
  for (final group in categoryFieldGroups) {
    for (final kw in group.keywords) {
      if (lower.contains(kw)) return group;
    }
  }

  // 2. Fallback: treat as commercial/property (covers Businesses, etc.)
  return const CategoryFieldGroup(keywords: [], fields: _commercialFields);
}
