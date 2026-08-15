const _byteOrderMark = '\u{FEFF}';

/// Parses the CSV dialect used by the standing-data files: fields may be
/// delimited by double quotes, a doubled quote inside such a field is a literal
/// quote, and blank lines carry no row.
List<List<String>> parseCsvRows(String content) {
  final text = content.startsWith(_byteOrderMark)
      ? content.substring(_byteOrderMark.length)
      : content;

  final rows = <List<String>>[];
  final fields = <String>[];
  final field = StringBuffer();
  var insideQuotes = false;

  void endField() {
    fields.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    if (fields.length > 1 || fields.single.isNotEmpty) {
      rows.add(List.of(fields));
    }
    fields.clear();
  }

  var index = 0;
  while (index < text.length) {
    final character = text[index];
    if (insideQuotes) {
      if (character != '"') {
        field.write(character);
      } else if (index + 1 < text.length && text[index + 1] == '"') {
        field.write('"');
        index++;
      } else {
        insideQuotes = false;
      }
    } else if (character == '"') {
      insideQuotes = true;
    } else if (character == ',') {
      endField();
    } else if (character == '\n') {
      endRow();
    } else if (character != '\r') {
      field.write(character);
    }
    index++;
  }
  if (fields.isNotEmpty || field.isNotEmpty) {
    endRow();
  }
  return rows;
}
