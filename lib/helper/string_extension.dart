extension StringExtension on String {
  String toCapitalized() {
    // Handle empty string
    if (isEmpty) {
      return this;
    }
    // Convert first letter to uppercase and join with rest of the string
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  // Optional: Add a method to capitalize first letter of each word
  String toTitleCase() {
    // Handle empty string
    if (isEmpty) {
      return this;
    }
    // Split string into words and capitalize each word
    return split('_')
        .map((word) => word.toCapitalized())
        .join(' ');
  }

  /// Safe substring that truncates to maxLength if string is longer
  /// Returns the original string if shorter than maxLength
  /// [maxLength] - Maximum length to truncate to
  /// [ellipsis] - Optional ellipsis suffix (default: '...')
  /// Returns safely truncated string
  String safeSubstring(int maxLength, {String ellipsis = '...'}) {
    if (maxLength < 0) return this;
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }
}