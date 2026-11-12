/// Small number helpers shared by the logic files.
library;

/// The values that are present, without the missing (null) ones.
List<int> presentValues(Iterable<int?> values) =>
    values.whereType<int>().toList();

/// Average of [values]. They must not be empty.
double mean(Iterable<num> values) {
  final list = values.toList();
  return list.fold<double>(0, (sum, v) => sum + v) / list.length;
}

/// How far values are from their average, on average. Used for
/// "how much does your bedtime move around".
double meanAbsoluteDeviation(Iterable<num> values) {
  final list = values.toList();
  final average = mean(list);
  return mean(list.map((v) => (v - average).abs()));
}
