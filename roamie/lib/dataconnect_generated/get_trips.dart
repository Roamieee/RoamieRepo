part of 'generated.dart';

class GetTripsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetTripsVariablesBuilder(this._dataConnect, );
  Deserializer<GetTripsData> dataDeserializer = (dynamic json)  => GetTripsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetTripsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetTripsData, void> ref() {
    
    return _dataConnect.query("GetTrips", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetTripsTrips {
  final String id;
  final String name;
  GetTripsTrips.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTripsTrips otherTyped = other as GetTripsTrips;
    return id == otherTyped.id && 
    name == otherTyped.name;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  GetTripsTrips({
    required this.id,
    required this.name,
  });
}

@immutable
class GetTripsData {
  final List<GetTripsTrips> trips;
  GetTripsData.fromJson(dynamic json):
  
  trips = (json['trips'] as List<dynamic>)
        .map((e) => GetTripsTrips.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTripsData otherTyped = other as GetTripsData;
    return trips == otherTyped.trips;
    
  }
  @override
  int get hashCode => trips.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['trips'] = trips.map((e) => e.toJson()).toList();
    return json;
  }

  GetTripsData({
    required this.trips,
  });
}

