import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:projet_app/scale_layer_plugin_option.dart';
//import '../widgets/drawer.dart';
  
class HomePage extends StatefulWidget {
  //static const String route = '/live_location';
  //static const String route = '/';

  @override
  _HomePageState createState() => _HomePageState();
}

class ZoomButtonsPluginOption extends LayerOptions {
  final int minZoom;
  final int maxZoom;
  final bool mini;
  final double padding;
  final Alignment alignment;
  final Color? zoomInColor;
  final Color? zoomInColorIcon;
  final Color? zoomOutColor;
  final Color? zoomOutColorIcon;
  final IconData zoomInIcon;
  final IconData zoomOutIcon;

  ZoomButtonsPluginOption({
    Key? key,
    this.minZoom = 1,
    this.maxZoom = 18,
    this.mini = true,
    this.padding = 2.0,
    this.alignment = Alignment.topRight,
    this.zoomInColor,
    this.zoomInColorIcon,
    this.zoomInIcon = Icons.zoom_in,
    this.zoomOutColor,
    this.zoomOutColorIcon,
    this.zoomOutIcon = Icons.zoom_out,
    Stream<Null>? rebuild,
  }) : super(key: key, rebuild: rebuild);
}

class ZoomButtonsPlugin implements MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    if (options is ZoomButtonsPluginOption) {
      return ZoomButtons(options, mapState, stream);
    }
    throw Exception('Unknown options type for ZoomButtonsPlugin: $options');
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is ZoomButtonsPluginOption;
  }
}
class ZoomButtons extends StatelessWidget {
  final ZoomButtonsPluginOption zoomButtonsOpts;
  final MapState map;
  final Stream<Null> stream;
  final FitBoundsOptions options =
  const FitBoundsOptions(padding: EdgeInsets.all(12.0));

  ZoomButtons(this.zoomButtonsOpts, this.map, this.stream)
      : super(key: zoomButtonsOpts.key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: zoomButtonsOpts.alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
                left: zoomButtonsOpts.padding,
                top: zoomButtonsOpts.padding,
                right: zoomButtonsOpts.padding),
            child: FloatingActionButton(
              heroTag: 'zoomInButton',
              mini: zoomButtonsOpts.mini,
              backgroundColor:
              zoomButtonsOpts.zoomInColor ?? Theme.of(context).primaryColor,
              onPressed: () {
                var bounds = map.getBounds();
                var centerZoom = map.getBoundsCenterZoom(bounds, options);
                var zoom = centerZoom.zoom + 1;
                if (zoom < zoomButtonsOpts.minZoom) {
                  zoom = zoomButtonsOpts.minZoom as double;
                } else {
                  map.move(centerZoom.center, zoom,
                      source: MapEventSource.custom);
                }
              },
              child: Icon(zoomButtonsOpts.zoomInIcon,
                  color: zoomButtonsOpts.zoomInColorIcon ??
                      IconTheme.of(context).color),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(zoomButtonsOpts.padding),
            child: FloatingActionButton(
              heroTag: 'zoomOutButton',
              mini: zoomButtonsOpts.mini,
              backgroundColor: zoomButtonsOpts.zoomOutColor ??
                  Theme.of(context).primaryColor,
              onPressed: () {
                var bounds = map.getBounds();
                var centerZoom = map.getBoundsCenterZoom(bounds, options);
                var zoom = centerZoom.zoom - 1;
                if (zoom > zoomButtonsOpts.maxZoom) {
                  zoom = zoomButtonsOpts.maxZoom as double;
                } else {
                  map.move(centerZoom.center, zoom,
                      source: MapEventSource.custom);
                }
              },
              child: Icon(zoomButtonsOpts.zoomOutIcon,
                  color: zoomButtonsOpts.zoomOutColorIcon ??
                      IconTheme.of(context).color),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePageState extends State<HomePage> {
  LocationData? _currentLocation;
  late final MapController _mapController;
  bool _liveUpdate = false;
  bool _permission = false;
  String? _serviceError = '';
  var interActiveFlags = InteractiveFlag.all;
  final Location _locationService = Location();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    initLocationService();
  }

  void initLocationService() async {
    await _locationService.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
    );

    LocationData? location;
    bool serviceEnabled;
    bool serviceRequestResult;

    try {
      serviceEnabled = await _locationService.serviceEnabled();

      if (serviceEnabled) {
        var permission = await _locationService.requestPermission();
        _permission = permission == PermissionStatus.granted;

        if (_permission) {
          location = await _locationService.getLocation();
          _currentLocation = location;
          _locationService.onLocationChanged
              .listen((LocationData result) async {
            if (mounted) {
              setState(() {
                _currentLocation = result;

                // If Live Update is enabled, move map center
                if (_liveUpdate) {
                  _mapController.move(
                      LatLng(_currentLocation!.latitude!,
                          _currentLocation!.longitude!),
                      _mapController.zoom);
                }
              });
            }
          });
        }
      } else {
        serviceRequestResult = await _locationService.requestService();
        if (serviceRequestResult) {
          initLocationService();
          return;
        }
      }
    } on PlatformException catch (e) {
      print(e);
      if (e.code == 'PERMISSION_NON_ACCORDEE') {
        _serviceError = e.message;
      } else if (e.code == 'ERREUR_D_ETAT_DU_SERVICE') {
        _serviceError = e.message;
      }
      location = null;
    }
  }

  @override
  Widget build(BuildContext context) {
	LatLng currentLatLng;

    // Until currentLocation is initially updated, Widget can locate to 0, 0
    // by default or store previous location value to show.
    if (_currentLocation != null) {
      currentLatLng =
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
    } else {
      currentLatLng = LatLng(0, 0);
    }
	
	var points = <LatLng>[
      LatLng(16.061851,-16.422973),//(51.5, -0.09),
      LatLng(16.061371,-16.422888),//(53.3498, -6.2603),
      LatLng(16.062684,-16.420974),//(48.8566, 2.3522),
    ];
	var pointsGradient = <LatLng>[
      LatLng(20.061643,-16.422973),//(55.5, -0.09),ugb
      LatLng(20.061371,-16.422888),//(54.3498, -6.2603),bu
      LatLng(20.062684,-16.420974),//(52.8566, 2.3522),rectorat
    ];
	
  StreamController<Null> resetController = StreamController.broadcast();

  String layer1 = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  String layer2 = 'http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
  bool layerToggle = true;

  @override
  void initState() {
    super.initState();
  }

  void _resetTiles() {
    setState(() {
      layerToggle = !layerToggle;
    });
    resetController.add(null);
  }
	
    var markers = <Marker>[
	  Marker(
        width: 80.0,
        height: 80.0,
        point: currentLatLng,
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('Voici votre position actuelle'),
            ));
          },
          child: Icon(
		  Icons.my_location,
		  color: Colors.lightBlue.shade600,
		  ),
        ),
      ),
	  ),
      Marker(
        width: 100.0,
        height: 100.0,
        point: LatLng(16.061851,-16.422973),//(51.5, -0.09),UGB
        builder: (ctx) => Container(
          child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text("Vous avez tapé sur l'Université Gaston Berger de Saint-Louis"),
            ));
          },
          child: Icon(
		  Icons.school,
		  color: HexColor("#ffffff"),
		  ),
        )
        ),
      ),
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.061371,-16.422888),//(53.3498, -6.2603),BU
        builder: (ctx) => Container(
			child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('Vous avez tapé sur la bibliothèque universitaire'),
            ));
          },
          child: Icon(
		  Icons.local_library,
		  color: Colors.blueGrey.shade600,
		  ),
		  ),
        ),
      ),

      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.062684,-16.420974),//(48.8566, 2.3522),RECTORAT
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('Vous avez tapé sur le rectorat'),
            ));
          },
          child: Icon(
		  Icons.location_on,
		  color: Colors.blueGrey.shade600,
		  ),
        ),
      ),
	  ),
	  Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.061643,-16.420515),//(48.8566, 2.3522),Scolarite
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('Vous avez tapé sur la scolarité'),
            ));
          },
          child: Icon(
		  Icons.location_on,
		  color: Colors.blueGrey.shade600,
		  ),
        ),
      ),
	  ),
	  Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.062381,-16.419078),//(48.8566, 2.3522),Incubateur
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text("Vous avez tapé sur le centre d'incubation"),
            ));
          },
          child: Icon(
		  Icons.location_on,
		  color: Colors.blueGrey.shade600,
		  ),
        ),
      ),
	  ),
	  Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.060047,-16.425168),//(48.8566, 2.3522),UGB2
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('Vous avez tapé sur UGB2'),
            ));
          },
          child: Icon(
		  Icons.school,
		  color: Colors.blueGrey.shade600,
		  ),
        ),
      ),
	  ),
	  Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.067587,-16.422046),//(48.8566, 2.3522),Resto2
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('Vous avez tapé sur le restaurant universitaire N°2'),
            ));
          },
          child: Icon(
		  Icons.restaurant_menu,
		  color: Colors.deepOrange,
		  ),
        ),
      ),
	  ),
	  Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.065635,-16.426189),//(48.8566, 2.3522),resto1
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('Vous avez tapé sur le restaurant universitaire N°1'),
            ));
          },
          child: Icon(
		  Icons.restaurant_menu,
		  color: Colors.deepOrange,
		  ),
        ),
      ),
	  ),
	  Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.066680,-16.426366),//(48.8566, 2.3522),Centre Medical
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('Vous avez tapé sur le Centre Médical'),
            ));
          },
          child: Icon(
		  Icons.medical_services_sharp,
		  color: Colors.red.shade900,
		  ),
        ),
      ),
	  ),
	  Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.065637,-16.422865),//(48.8566, 2.3522),Tour de l'oeuf
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text("Vous avez tapé sur le tour de l'oeuf"),
            ));
          },
          child: Icon(
		  Icons.location_on,
		  color: Colors.blueGrey.shade600,
		  ),
        ),
      ),
	  ),
	  Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.061461,-16.423046),//(48.8566, 2.3522),Amphi A
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text("Vous avez tapé sur l'amphithéâtre A"),
            ));
          },
          child: Icon(
		  Icons.school,
		  color: Colors.blueGrey.shade600,
		  ),
        ),
      ),
	  ),
	  Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.061906,-16.422784),//(48.8566, 2.3522),Amphi B
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text("Vous avez tapé sur l'amphithéâtre B"),
            ));
          },
          child: Icon(
		  Icons.school,
		  color: Colors.blueGrey.shade600,
		  ),
        ),
      ),
	  ),
	  Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.061190,-16.423627),//(48.8566, 2.3522),Amphi C
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text("Vous avez tapé sur l'amphithéâtre C"),
            ));
          },
          child: Icon(
		  Icons.school,
		  color: Colors.blueGrey.shade600,
		  ),
        ),
      ),
	  ),
	  Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.061247,-16.424133),//(48.8566, 2.3522),Ccos
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('Vous avez tapé sur le Ccos'),
            ));
          },
          child: Icon(
		  Icons.location_on,
		  color: Colors.blueGrey.shade600,
		  ),
        ),
      ),
	  ),
	  Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.064288,-16.420681),//(48.8566, 2.3522),piscine
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('Vous avez tapé sur la piscine'),
            ));
          },
          child: Icon(
		  Icons.location_on,
		  color: Colors.blueGrey.shade600,
		  ),
        ),
      ),),
	  Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.063595,-16.419968),//(48.8566, 2.3522),sefs
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text("Vous avez tapé sur l'UFR SEFS"),
            ));
          },
          child: Icon(
		  Icons.school,
		  color: Colors.blueGrey.shade600,
		  ),
        ),
      ),),
	  Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.060426,-16.425268),//(48.8566, 2.3522),cea mitic
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('Vous avez tapé sur CEA MITIC'),
            ));
          },
          child: Icon(
		  Icons.location_on,
		  color: Colors.blueGrey.shade600,
		  ),
        ),
      ),),
	  Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(16.060865,-16.423448),//(48.8566, 2.3522),Amphi CRAC
        builder: (ctx) => Container(
		  child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text("Vous avez tapé sur l'amphithéâtre CRAC"),
            ));
          },
          child: Icon(
		  Icons.school,
		  color: Colors.blueGrey.shade600,
		  ),
        ),
      ),),
    ];

    return Scaffold(
        appBar: AppBar(
          title:Text('Université Gaston Berger',
              style: TextStyle(
                fontSize: 20.0,
                color: HexColor("#ffffff"),
              ),
            ),
        ),
        //drawer: buildDrawer(context, HomePage.route),
	    body: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
              Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                //child: Text('This is a map that is showing (51.5, -0.9).'),
                child: _serviceError!.isEmpty
                  ? Text('This is a map that is showing '
                    '(${currentLatLng.latitude}, ${currentLatLng.longitude}).')
                  : Text(
                    'Error occured while acquiring location. Error Message : '
                    '$_serviceError'),
              ),
			  Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Wrap(
                children: <Widget>[
                  MaterialButton(
                    onPressed: _resetTiles,
                    child: Text('Reset'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: LatLng(16.061851,-16.422973),//(51.5, -0.09),
                  //LatLng(currentLatLng.latitude, currentLatLng.longitude),
                zoom: 17.0,
                interactiveFlags: interActiveFlags,
				plugins: [
                    ScaleLayerPlugin(),
                ],
              ),
			  nonRotatedLayers: [
                  ScaleLayerPluginOption(
                    lineColor: Colors.blue,
                    lineWidth: 2,
                    textStyle: TextStyle(color: Colors.blue, fontSize: 12),
                    padding: EdgeInsets.all(10),
                  ),
              ],
              layers: [
                TileLayerOptions(
					reset: resetController.stream,
                    urlTemplate: layerToggle ? layer1 : layer2,
					/*urlTemplate:
					  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',*/
					subdomains: ['a', 'b', 'c'],
					// For example purposes. It is recommended to use
					// TileProvider with a caching and retry strategy, like
					// NetworkTileProvider or CachedNetworkTileProvider
					tileProvider: NonCachingNetworkTileProvider(),
                ),
                MarkerLayerOptions(markers: markers),
				PolylineLayerOptions(
                    polylines: [
                      Polyline(
                          points: points,
                          strokeWidth: 4.0,
                          color: Colors.purple),
                    ],
                ),
				PolylineLayerOptions(
                    polylines: [
                      Polyline(
                        points: pointsGradient,
                        strokeWidth: 4.0,
                        gradientColors: [
                          Color(0xffE40203),
                          Color(0xffFEED00),
                          Color(0xff007E2D),
                        ],
                      ),
                    ],
                ),
              ],
              ),
            ),
				  ],
				),
			  ),
    );
  }
}





