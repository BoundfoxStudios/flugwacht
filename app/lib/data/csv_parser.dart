import 'package:csv/csv.dart';

// The delimiter is pinned instead of left to the package's auto-detection:
// the standing-data files are always comma separated.
const _decoder = CsvDecoder(fieldDelimiter: ',');

List<List<String>> parseCsvRows(String content) =>
    _decoder.convert(content).map((row) => row.cast<String>()).toList();
