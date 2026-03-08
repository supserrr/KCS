import 'package:latlong2/latlong.dart';

final _distance = Distance(roundResult: false);

// distance via latlong2 (Vincenty) - returns km
double distanceInKm(double lat1, double lon1, double lat2, double lon2) {
  return _distance.as(
    LengthUnit.Kilometer,
    LatLng(lat1, lon1),
    LatLng(lat2, lon2),
  );
}

String formatDistance(double km) {
  // under 1m just show < 1 m; meters for short, km for longer
  if (km < 0.001) {
    return '< 1 m';
  }
  if (km < 1) {
    return '${(km * 1000).round()} m';
  }
  return '${km.toStringAsFixed(1)} km';
}
