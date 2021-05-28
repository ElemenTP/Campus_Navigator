import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:amap_flutter_base/amap_flutter_base.dart'; //LatLng 类型在这里面

LatLng lfromJson(Map<String, dynamic> json) {
  return LatLng(json["latitude"] as double, json["longitude"] as double);
}

class MapVertex {
  List<LatLng> listVertex = [];
  List<String> detail = [];
  MapVertex({required this.listVertex, required this.detail});
  factory MapVertex.fromJson(Map<String, dynamic> json) =>
      _$MapVertexFromJson(json);
  Map<String, dynamic> toJson() => _$MapVertexToJson(this);
  LatLng getLatLng(int id) {
    return listVertex[id];
  }
}

MapVertex _$MapVertexFromJson(Map<String, dynamic> json) {
  var listVertexJson = json['listVertex'] as List;
  List<LatLng> latlngList = [];
  List<String> detaillist = [];
  listVertexJson.map((i) => lfromJson(i)).toList();
  listVertexJson.forEach((e) {
    latlngList.add(lfromJson(e));
    detaillist.add(e["detail"] as String);
  });
  return MapVertex(listVertex: latlngList, detail: detaillist);
}

Map<String, dynamic> _$MapVertexToJson(MapVertex instance) {
  //List<Map<String, double>> json = [];
  List<Map<String, dynamic>> json = [];
  int i = 0;
  instance.listVertex.forEach((e) {
    json.add(<String, dynamic>{
      "latitude": e.latitude as double,
      "longitude": e.longitude as double,
      "detail": instance.detail[i] as String
    });
    i = (i + 1) % instance.detail.length;
  });
  return <String, dynamic>{"listVertex": json};
}

class Edge {
  double length = double.infinity;
  int availmthod = -1;
  double crowding = 1;
  late int startid, endid;
  Edge(int start, int end, int availmthod) {
    this.startid = start;
    this.endid = end;
    this.availmthod = availmthod;
  }

  set_length(MapVertex mapvertex) {
    var p = 0.017453292519943295;
    var c = cos;
    this.length = 0.5 -
        c((mapvertex.listVertex[this.endid].latitude -
                    mapvertex.listVertex[this.startid].latitude) *
                p) /
            2 +
        c(mapvertex.listVertex[this.startid].latitude * p) *
            c(mapvertex.listVertex[this.endid].latitude * p) *
            (1 -
                c((mapvertex.listVertex[this.endid].longitude -
                        mapvertex.listVertex[this.startid].longitude) *
                    p)) /
            2;
  }

  randomCrowding() {
    this.crowding = Random().nextDouble();
  }

  factory Edge.fromJson(Map<String, dynamic> json) => _$EdgeFromJson(json);
  Map<String, dynamic> toJson() => _$EdgetoJson(this);
}

Map<String, dynamic> _$EdgetoJson(Edge instance) => <String, dynamic>{
      'startid': instance.startid,
      'endid': instance.endid,
      'availmthod': instance.availmthod,
    };

Edge _$EdgeFromJson(Map<String, dynamic> json) {
  return Edge(
    json['startid'] as int,
    json['endid'] as int,
    json['availmthod'] as int,
  );
}

class MapData {
  List<MapVertex> mapvertex;
  List<List<Edge>> mapedge;
  MapData({required this.mapvertex, required this.mapedge});
  factory MapData.fromJson(Map<String, dynamic> json) =>
      _$MapDataFromJson(json);
  Map<String, dynamic> toJson() => _$MapdataToJson(this);
}

MapData _$MapDataFromJson(Map<String, dynamic> json) {
  List<dynamic> vertexJson = json['mapvertex'];
  //print(vertexJson);

  List<MapVertex> vertex = [];
  vertexJson.forEach((e) {
    vertex.add(MapVertex.fromJson(e));
  });

  List<dynamic> edgeJson = json['mapedge'];
  List<List<Edge>> edge = [];
  edgeJson.forEach((e1) {
    List<Edge> tmp = List.from(e1.map((e2) => Edge.fromJson(e2)).toList());
    edge.add(tmp);
  });
  return MapData(
    mapvertex: vertex,
    mapedge: edge,
  );
}

Map<String, dynamic> _$MapdataToJson(MapData instance) => <String, dynamic>{
      'mapvertex': instance.mapvertex,
      'mapedge': instance.mapedge,
    };
