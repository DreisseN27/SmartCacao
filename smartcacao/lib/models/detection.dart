class Detection {
  final String label;
  final double confidence;
  final double x;
  final double y;
  final double width;
  final double height;

  Detection({
    required this.label,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Convert Detection to JSON for transmission or storage
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'confidence': confidence,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'boundingBox': {
        'left': x - width / 2,
        'top': y - height / 2,
        'right': x + width / 2,
        'bottom': y + height / 2,
      },
    };
  }

  /// Create Detection from JSON
  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  /// Get fermentation status description
  String get statusDescription {
    switch (label) {
      case 'under_fermented':
        return 'Under Fermented';
      case 'properly_fermented':
        return 'Properly Fermented';
      case 'over_fermented':
        return 'Over Fermented';
      default:
        return 'Unknown';
    }
  }

  /// Get fermentation status color (ARGB format)
  int get statusColor {
    switch (label) {
      case 'under_fermented':
        return 0xFFFF6B6B; // Red
      case 'properly_fermented':
        return 0xFF51CF66; // Green
      case 'over_fermented':
        return 0xFFFFD43B; // Yellow
      default:
        return 0xFF808080; // Gray
    }
  }

  /// Get detailed description for the fermentation status
  String get detailedDescription {
    switch (label) {
      case 'under_fermented':
        return 'This bean requires more fermentation time. Continue fermentation for 2-3 more days.';
      case 'properly_fermented':
        return 'This bean is perfectly fermented! Ready for drying and processing.';
      case 'over_fermented':
        return 'This bean has been over-fermented. Quality may be compromised.';
      default:
        return 'Unable to determine fermentation status.';
    }
  }

  @override
  String toString() => 'Detection(label: $label, confidence: $confidence, '
      'x: $x, y: $y, w: $width, h: $height)';
}