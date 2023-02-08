library custom_map;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_open_street_map/widgets/custom_button.dart';
import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../constants/consstante.dart';
import '../../../constants/size_config.dart';

class FlutterOpenStreetMapp extends StatefulWidget {
  final LatLong center;
  final void Function(PickedData pickedData) onPicked;
  final Color? primaryColor;
  final bool? showZoomButtons;

  const FlutterOpenStreetMapp(
      {Key? key,
      required this.center,
      required this.onPicked,
      this.primaryColor,
      this.showZoomButtons})
      : super(key: key);

  @override
  State<FlutterOpenStreetMapp> createState() => _FlutterOpenStreetMappState();
}

class _FlutterOpenStreetMappState extends State<FlutterOpenStreetMapp> {
  MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<OSMdata> _options = <OSMdata>[];
  Timer? _debounce;

  void setNameCurrentPos() async {
    var client = http.Client();
    double latitude = _mapController.center.latitude;
    double longitude = _mapController.center.longitude;
    if (kDebugMode) {
      print(latitude);
    }
    if (kDebugMode) {
      print(longitude);
    }
    String url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1';

    var response = await client.post(Uri.parse(url));
    var decodedResponse =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<dynamic, dynamic>;

    _searchController.text =
        decodedResponse['display_name'] ?? "MOVE TO CURRENT POSITION";
    setState(() {});
  }

  void setNameCurrentPosAtInit() async {
    var client = http.Client();
    double latitude = widget.center.latitude;
    double longitude = widget.center.longitude;
    if (kDebugMode) {
      print(latitude);
    }
    if (kDebugMode) {
      print(longitude);
    }
    String url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1';

    var response = await client.post(Uri.parse(url));
    var decodedResponse =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<dynamic, dynamic>;

    _searchController.text =
        decodedResponse['display_name'] ?? "MOVE TO CURRENT POSITION";
    setState(() {});
  }

  @override
  void initState() {
    _mapController = MapController();

    _mapController.onReady.then((_) {
      setNameCurrentPosAtInit();
    });

    _mapController.mapEventStream.listen((event) async {
      if (event is MapEventMoveEnd) {
        var client = http.Client();
        String url =
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=${event.center.latitude}&lon=${event.center.longitude}&zoom=18&addressdetails=1';

        var response = await client.post(Uri.parse(url));
        var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<dynamic, dynamic>;

        _searchController.text = decodedResponse['display_name'];
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
              child: FlutterMap(
            options: MapOptions(
                center: LatLng(widget.center.latitude, widget.center.longitude),
                zoom: 15.0,
                maxZoom: 18,
                minZoom: 6),
            mapController: _mapController,
            layers: [
              TileLayerOptions(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
                // attributionBuilder: (_) {
                //   return Text("© OpenStreetMap contributors");
                // },
              ),
            ],
          )),
          Positioned(
              top: MediaQuery.of(context).size.height * 0.5,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: StatefulBuilder(builder: (context, setState) {
                    return const Text(
                      '',
                      //_searchController.text,
                      textAlign: TextAlign.center,
                    );
                  }),
                ),
              )),
          const Positioned.fill(
              child: IgnorePointer(
            child: Center(
              child: Icon(
                Icons.location_pin,
                color: Colors.green,
                size: 40,
              ),
            ),
          )),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      TextFormField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: HexColor('#9CA3AF')),
                              //  borderRadius: const BorderRadius.all(Radius.circular(20)),
                            ),
                            errorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: redcolor),
                              //   borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            focusedErrorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: redcolor),
                              //  borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: HexColor('#9CA3AF')),
                              // borderRadius: const BorderRadius.all(Radius.circular(20)),
                            ),
                            //  hintText: (hintText != null) ? hintText?.tr : hintText,
                            // hintText: '',
                            contentPadding: EdgeInsets.only(
                                right:
                                    SizeConfig.getProportionateScreenWidth(10),
                                left:
                                    SizeConfig.getProportionateScreenWidth(15),
                                top:
                                    SizeConfig.getProportionateScreenWidth(32)),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          onChanged: (String value) {
                            if (_debounce?.isActive ?? false)
                              _debounce?.cancel();

                            _debounce = Timer(
                                const Duration(milliseconds: 2000), () async {
                              if (kDebugMode) {
                                print(value);
                              }
                              var client = http.Client();
                              try {
                                String url =
                                    'https://nominatim.openstreetmap.org/search?q=$value&format=json&polygon_geojson=1&addressdetails=1';
                                if (kDebugMode) {
                                  print(url);
                                }
                                var response =
                                    await client.post(Uri.parse(url));
                                var decodedResponse =
                                    jsonDecode(utf8.decode(response.bodyBytes))
                                        as List<dynamic>;
                                if (kDebugMode) {
                                  print(decodedResponse);
                                }
                                _options = decodedResponse
                                    .map((e) => OSMdata(
                                        displayname: e['display_name'],
                                        lat: double.parse(e['lat']),
                                        lon: double.parse(e['lon'])))
                                    .toList();
                                setState(() {});
                              } finally {
                                client.close();
                              }

                              setState(() {});
                            });
                          }),
                      IconButton(
                        padding: EdgeInsets.all(2),
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                        ),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  StatefulBuilder(builder: ((context, setState) {
                    return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _options.length > 5 ? 5 : _options.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_options[index].displayname),
                            subtitle: Text(
                                '${_options[index].lat},${_options[index].lon}'),
                            onTap: () {
                              _mapController.move(
                                  LatLng(
                                      _options[index].lat, _options[index].lon),
                                  15.0);

                              _focusNode.unfocus();
                              _options.clear();
                              setState(() {});
                            },
                          );
                        });
                  })),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomButton('confirm'.tr, onPressed: () async {
                  pickData().then((value) {
                    widget.onPicked(value);
                  });
                }, backgroundcolor: HexColor('#1C9E54')),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<PickedData> pickData() async {
    LatLong center = LatLong(
        _mapController.center.latitude, _mapController.center.longitude);
    var client = http.Client();
    String url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${_mapController.center.latitude}&lon=${_mapController.center.longitude}&zoom=18&addressdetails=1';

    var response = await client.post(Uri.parse(url));
    var decodedResponse =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<dynamic, dynamic>;
    String displayName = decodedResponse['display_name'];
    return PickedData(latLong: center, address: displayName);
  }
}

class OSMdata {
  final String displayname;
  final double lat;
  final double lon;

  OSMdata({required this.displayname, required this.lat, required this.lon});

  @override
  String toString() {
    return '$displayname, $lat, $lon';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is OSMdata && other.displayname == displayname;
  }

  @override
  int get hashCode => Object.hash(displayname, lat, lon);
}

class LatLong {
  final double latitude;
  final double longitude;

  LatLong(this.latitude, this.longitude);
}

class PickedData {
  final LatLong latLong;
  final String address;

//<editor-fold desc="Data Methods">

  const PickedData({
    required this.latLong,
    required this.address,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PickedData &&
          runtimeType == other.runtimeType &&
          latLong == other.latLong &&
          address == other.address);

  @override
  int get hashCode => latLong.hashCode ^ address.hashCode;

  @override
  String toString() {
    return 'PickedData{' + ' latLong: $latLong,' + ' address: $address,' + '}';
  }

  PickedData copyWith({
    LatLong? latLong,
    String? address,
  }) {
    return PickedData(
      latLong: latLong ?? this.latLong,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latLong': this.latLong,
      'address': this.address,
    };
  }

  factory PickedData.fromMap(Map<String, dynamic> map) {
    return PickedData(
      latLong: map['latLong'] as LatLong,
      address: map['address'] as String,
    );
  }

//</editor-fold>
}
