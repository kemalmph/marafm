import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station_metadata.dart';

class MetadataService {
  Future<StationMetadata> fetchMetadata(String metadataUrl) async {
    final response = await http.get(Uri.parse(metadataUrl));
    if (response.statusCode == 200) {
      return StationMetadata.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load metadata');
    }
  }
}
