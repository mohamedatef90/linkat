/// Represents the type of content for a link
enum ContentType {
  video,
  reel,
  short,
  post,
  article,
  image,
  story,
  thread,
  podcast,
  music,
  profile,
  other;

  String get displayName {
    switch (this) {
      case ContentType.video:
        return 'Video';
      case ContentType.reel:
        return 'Reel';
      case ContentType.short:
        return 'Short';
      case ContentType.post:
        return 'Post';
      case ContentType.article:
        return 'Article';
      case ContentType.image:
        return 'Image';
      case ContentType.story:
        return 'Story';
      case ContentType.thread:
        return 'Thread';
      case ContentType.podcast:
        return 'Podcast';
      case ContentType.music:
        return 'Music';
      case ContentType.profile:
        return 'Profile';
      case ContentType.other:
        return 'Link';
    }
  }

  String get emoji {
    switch (this) {
      case ContentType.video:
        return '🎬';
      case ContentType.reel:
        return '🎞️';
      case ContentType.short:
        return '⚡';
      case ContentType.post:
        return '📝';
      case ContentType.article:
        return '📰';
      case ContentType.image:
        return '🖼️';
      case ContentType.story:
        return '📖';
      case ContentType.thread:
        return '🧵';
      case ContentType.podcast:
        return '🎙️';
      case ContentType.music:
        return '🎵';
      case ContentType.profile:
        return '👤';
      case ContentType.other:
        return '🔗';
    }
  }
}
