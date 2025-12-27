class TextFormat {
  static String clean(String input) {
    var s = input.trim();
    s = s.replaceAll(RegExp(r'^\s*[*\-•]+\s+', multiLine: true), '');
    s = s.replaceAll(RegExp(r'^\s*#{1,6}\s*', multiLine: true), '');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }
}
