/// Topic categories for content classification
enum TopicType {
  aiTech, // AI, Machine Learning, Technology
  development, // Programming, Software Development, Coding
  productUX, // Product Design, UX/UI, User Experience
  design, // Graphic Design, Creative, Branding
  business, // Business, Marketing, Finance, Startup
  science, // Science, Research, Education, Academic
  entertainment, // Movies, Music, Gaming, Sports
  other; // Miscellaneous or unclassified

  String get displayName {
    switch (this) {
      case TopicType.aiTech:
        return 'AI & Tech';
      case TopicType.development:
        return 'Development';
      case TopicType.productUX:
        return 'Product & UX';
      case TopicType.design:
        return 'Design';
      case TopicType.business:
        return 'Business';
      case TopicType.science:
        return 'Science';
      case TopicType.entertainment:
        return 'Entertainment';
      case TopicType.other:
        return 'Other';
    }
  }
}
