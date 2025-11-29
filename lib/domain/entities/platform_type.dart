enum PlatformType {
  facebook,
  instagram,
  twitter, // X
  youtube,
  linkedin,
  other;

  String get displayName {
    switch (this) {
      case PlatformType.facebook:
        return 'Facebook';
      case PlatformType.instagram:
        return 'Instagram';
      case PlatformType.twitter:
        return 'X';
      case PlatformType.youtube:
        return 'YouTube';
      case PlatformType.linkedin:
        return 'LinkedIn';
      case PlatformType.other:
        return 'Website';
    }
  }
}
