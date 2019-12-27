import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class QiblaPage extends StatefulWidget {
  @override
  _QiblaState createState() => new _QiblaState();
}

class _QiblaState extends State<QiblaPage> {
  double _direction;
  LocationData _startLocation;
  LocationData _currentLocation;

  StreamSubscription<LocationData> _locationSubscription;

  Location _locationService = new Location();
  bool _permission = false;
  String error;
  double _meccaLat = 21.422487;
  double _meccaLong = 39.826206;
  double _mLat;
  double _mLong;
  double _result;
  String _qDirection;
  int _degree;
  bool _isLocationFetchingDone = true;

  Completer<GoogleMapController> _controller = Completer();
  static final CameraPosition _initialCamera = CameraPosition(
    target: LatLng(0, 0),
    zoom: 4,
  );

  CameraPosition _currentCameraPosition;

  initPlatformState() async {
    await _locationService.changeSettings(
        accuracy: LocationAccuracy.HIGH, interval: 1000);

    LocationData location;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      bool serviceStatus = await _locationService.serviceEnabled();
      print("Service status: $serviceStatus");
      if (serviceStatus) {
        _permission = await _locationService.requestPermission();
        print("Permission: $_permission");
        if (_permission) {
          location = await _locationService.getLocation();

          _locationSubscription = _locationService
              .onLocationChanged()
              .listen((LocationData result) async {
            _currentCameraPosition = CameraPosition(
                target: LatLng(result.latitude, result.longitude), zoom: 16);

            final GoogleMapController controller = await _controller.future;
            controller.animateCamera(
                CameraUpdate.newCameraPosition(_currentCameraPosition));

            if (mounted) {
              setState(() {
                _currentLocation = result;
              });
            }
          });
        }
      } else {
        bool serviceStatusResult = await _locationService.requestService();
        print("Service status activated after request: $serviceStatusResult");
        if (serviceStatusResult) {
          initPlatformState();
        }
      }
    } on PlatformException catch (e) {
      print(e);
      if (e.code == 'PERMISSION_DENIED') {
        error = e.message;
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        error = e.message;
      }
      location = null;
    }

    setState(() {
      _startLocation = location;
    });
  }

  double degToRad(double deg) => deg * (math.pi / 180.0);

  double radToDeg(double rad) => rad * (180.0 / math.pi);

  Future<void> calculateQiblaAngle() async {
    await initPlatformState();
    _mLat = _startLocation.latitude;
    _mLong = _startLocation.longitude;

    double _mLatRad = degToRad(_mLat);
    double _mLongRad = degToRad(_mLong);
    double _meccaLatRad = degToRad(_meccaLat);

    double _longDiff = degToRad(_meccaLong - _mLong);
    double y = math.sin(_longDiff) * math.cos(_meccaLatRad);
    double x = math.cos(_mLatRad) * math.sin(_meccaLatRad) -
        math.sin(_mLatRad) * math.cos(_meccaLatRad) * math.cos(_longDiff);

    _result = (radToDeg(math.atan2(y, x)) + 360) % 360;
    _degree = _result.toInt();
    setState(() {
      _isLocationFetchingDone = false;
    });
  }

  String getDirectionString(double degree) {
    String where = "NW";

    if (degree >= 350 || degree <= 10) where = "N";
    if (degree < 350 && degree > 280) where = "NW";
    if (degree <= 280 && degree > 260) where = "W";
    if (degree <= 260 && degree > 190) where = "SW";
    if (degree <= 190 && degree > 170) where = "S";
    if (degree <= 170 && degree > 100) where = "SE";
    if (degree <= 100 && degree > 80) where = "E";
    if (degree <= 80 && degree > 10) where = "NE";

    return where;
  }

  @override
  void initState() {
    super.initState();
    FlutterCompass.events.listen((double direction) {
      setState(() {
        _direction = direction;
      });
    });
  }

  @override
  void didChangeDependencies() async {
    await calculateQiblaAngle();
    _qDirection = getDirectionString(_result);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          backgroundColor: Colors.grey[300],
          body: ModalProgressHUD(
            inAsyncCall: _isLocationFetchingDone,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Align(
                  alignment: AlignmentDirectional.topCenter,
                  child: Container(
                    margin: EdgeInsetsDirectional.only(top: 40.0),
                    width: 300.0,
                    height: 300.0,
                    color: Colors.grey[300],
                    child: Transform.rotate(
                      angle: ((_direction ?? 0) * (math.pi / 180) * -1),
                      child: Container(
                          child: Stack(
                        children: <Widget>[
                          Center(
                            child: Container(
                              width: 190.0,
                              height: 190.0,
                              child: Image.asset('assets/dial.png'),
                            ),
                          ),
                          Container(
                              width: 300.0,
                              height: 300.0,
                              child: Transform.rotate(
                                angle: _result == null ? 0 : degToRad(_result),
                                child: Image.asset('assets/qibla.png'),
                              )),
                        ],
                      )),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsetsDirectional.only(top: 30.0),
                  child: Text(
                    _result == null ? '0' : '$_degree' + '° $_qDirection',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                        color: Colors.white),
                  ),
                ),
                Align(
                  child: Container(
                      margin: EdgeInsetsDirectional.only(top: 10.0),
                      child: Image.asset('assets/footer.png')),
                )
              ],
            ),
          )),
    );
  }
}
