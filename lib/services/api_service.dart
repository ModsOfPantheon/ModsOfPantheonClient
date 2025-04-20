import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mod.dart';
import '../models/mod_version.dart';
import '../models/mod_file.dart';

class ApiService {
  static const String _baseUrl = 'https://soiloifwlbccjvpchthr.supabase.co/rest/v1';
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNvaWxvaWZ3bGJjY2p2cGNodGhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ0OTE5MzksImV4cCI6MjA2MDA2NzkzOX0.Q_ErGrB3YmRBINuB12t1Qs-xDAyuqH0W30R2ssH3CxI';

  static Future<List<Mod>> getMods() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/Mods'),
      headers: {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((mod) => Mod.fromJson(mod)).toList();
    } else {
      throw Exception('Failed to load mods: ${response.statusCode}');
    }
  }

  static Future<Mod> getModById(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/Mods?id=eq.$id'),
      headers: {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isEmpty) {
        throw Exception('Mod not found');
      }
      return Mod.fromJson(data.first);
    } else {
      throw Exception('Failed to load mod: ${response.statusCode}');
    }
  }

  static Future<List<ModVersion>> getModVersions(int modId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/ModVersions?ModId=eq.$modId'),
      headers: {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final versions = data.map((version) => ModVersion.fromJson(version)).toList();
      // Sort versions by creation date, most recent first
      versions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return versions;
    } else {
      throw Exception('Failed to load mod versions: ${response.statusCode}');
    }
  }

  static Future<ModFile> getModFile(int fileId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/ModFiles?Id=eq.$fileId'),
      headers: {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isEmpty) {
        throw Exception('Mod file not found');
      }
      return ModFile.fromJson(data.first);
    } else {
      throw Exception('Failed to load mod file: ${response.statusCode}');
    }
  }
} 