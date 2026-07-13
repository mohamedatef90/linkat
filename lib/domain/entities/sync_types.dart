/// Local write operation queued for push to the server.
enum PendingOp {
  none,
  create,
  update,
  delete,
}

/// Server-side enrichment status of a content item.
enum ItemStatus {
  pending,
  parsing,
  enriching,
  ready,
  degraded,
  failed;

  static ItemStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return ItemStatus.pending;
      case 'parsing':
        return ItemStatus.parsing;
      case 'enriching':
        return ItemStatus.enriching;
      case 'degraded':
        return ItemStatus.degraded;
      case 'failed':
        return ItemStatus.failed;
      case 'ready':
      default:
        return ItemStatus.ready;
    }
  }

  bool get isProcessing =>
      this == ItemStatus.pending ||
      this == ItemStatus.parsing ||
      this == ItemStatus.enriching;
}
