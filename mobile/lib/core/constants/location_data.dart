/// Reference location, craft category, language, and artisan type data for onboarding.
class LocationData {
  static const List<String> craftCategories = [
    'Handloom',
    'Handicraft',
    'Pottery',
    'Woodwork',
    'Metalwork',
    'Jewellery',
    'Other',
  ];

  static const List<String> preferredLanguages = [
    'Odia',
    'Hindi',
    'English',
    'Other',
  ];

  static const List<String> artisanTypes = [
    'Individual',
    'Self-help group',
    'Cooperative',
    'Small business',
  ];

  static const Map<String, List<String>> stateDistricts = {
    'Odisha': [
      'Bargarh',
      'Sambalpur',
      'Puri',
      'Cuttack',
      'Khurda',
      'Ganjam',
      'Mayurbhanj',
      'Koraput',
      'Sonepur',
      'Balasore',
      'Sundargarh',
      'Kendrapara',
      'Other District',
    ],
    'Rajasthan': [
      'Jaipur',
      'Jodhpur',
      'Udaipur',
      'Bikaner',
      'Kota',
      'Barmer',
      'Jaisalmer',
      'Ajmer',
      'Nagaur',
      'Other District',
    ],
    'Uttar Pradesh': [
      'Varanasi',
      'Lucknow',
      'Agra',
      'Moradabad',
      'Bhadohi',
      'Saharanpur',
      'Kannauj',
      'Gorakhpur',
      'Prayagraj',
      'Other District',
    ],
    'Gujarat': [
      'Kutch',
      'Ahmedabad',
      'Surat',
      'Rajkot',
      'Patan',
      'Surendranagar',
      'Vadodara',
      'Other District',
    ],
    'West Bengal': [
      'Bankura',
      'Nadia',
      'Birbhum',
      'Murshidabad',
      'Purulia',
      'Kolkata',
      'Hooghly',
      'Other District',
    ],
    'Madhya Pradesh': [
      'Chanderi',
      'Maheshwar',
      'Bhopal',
      'Indore',
      'Gwalior',
      'Dhar',
      'Bastar',
      'Other District',
    ],
    'Maharashtra': [
      'Mumbai',
      'Pune',
      'Paithan',
      'Kolhapur',
      'Nagpur',
      'Aurangabad',
      'Solapur',
      'Other District',
    ],
    'Karnataka': [
      'Mysuru',
      'Bengaluru',
      'Channapatna',
      'Ilkal',
      'Dharwad',
      'Bidar',
      'Other District',
    ],
    'Tamil Nadu': [
      'Kanchipuram',
      'Madurai',
      'Thanjavur',
      'Coimbatore',
      'Salem',
      'Chennai',
      'Other District',
    ],
    'Andhra Pradesh': [
      'Dharmavaram',
      'Mangalagiri',
      'Machilipatnam',
      'Srikalahasti',
      'Visakhapatnam',
      'Other District',
    ],
    'Bihar': [
      'Madhubani',
      'Bhagalpur',
      'Patna',
      'Gaya',
      'Muzaffarpur',
      'Other District',
    ],
    'Assam': [
      'Sualkuchi',
      'Kamrup',
      'Guwahati',
      'Barpeta',
      'Jorhat',
      'Other District',
    ],
    'Punjab': [
      'Amritsar',
      'Ludhiana',
      'Patiala',
      'Jalandhar',
      'Other District',
    ],
    'Kerala': [
      'Thrissur',
      'Balaramapuram',
      'Kozhikode',
      'Thiruvananthapuram',
      'Other District',
    ],
    'Other State': [
      'Central District',
      'North District',
      'South District',
      'East District',
      'West District',
      'Other',
    ],
  };

  static List<String> get states => stateDistricts.keys.toList();

  static List<String> getDistrictsForState(String state) {
    return stateDistricts[state] ?? ['Other District'];
  }
}
