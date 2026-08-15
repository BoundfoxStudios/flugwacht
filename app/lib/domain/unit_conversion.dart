const _metersPerFoot = 0.3048;
const _kilometersPerHourPerKnot = 1.852;

int? metersFromFeet(double? feet) =>
    feet == null ? null : (feet * _metersPerFoot).round();

int? kilometersPerHourFromKnots(double? knots) =>
    knots == null ? null : (knots * _kilometersPerHourPerKnot).round();
