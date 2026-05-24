class ExpertHelp {
  final int? exid;
  final int? userid;
  final String associateName;
  final double? longitude;
  final double? latitude;
  final String? description;
  final String? address;
  final String? contactInfo;
  final String? clinicImage; // URL or base64 string from backend
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExpertHelp({
    this.exid,
    this.userid,
    required this.associateName,
    this.longitude,
    this.latitude,
    this.description,
    this.address,
    this.contactInfo,
    this.clinicImage,
    this.createdAt,
    this.updatedAt,
  });

  factory ExpertHelp.fromJson(Map<String, dynamic> json) {
    return ExpertHelp(
      exid: json['exid'],
      userid: json['userid'],
      associateName: json['associatename'] ?? '',
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      description: json['description'],
      address: json['address'],
      contactInfo: json['contactinfo'],
      clinicImage: json['clinic_image'] ?? json['clinicimage'] ?? json['image_url'],
      createdAt: json['createdat'] != null ? DateTime.parse(json['createdat']) : null,
      updatedAt: json['updatedat'] != null ? DateTime.parse(json['updatedat']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exid': exid,
      'userid': userid,
      'associatename': associateName,
      'address': address,
      'longitude': longitude,
      'latitude': latitude,
      'description': description,
      'contactinfo': contactInfo,
      'clinic_image': clinicImage,
    };
  }
}
