import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

void main() {
  runApp(MyApp()); // Menjalankan aplikasi utama
}

// Widget utama aplikasi
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokemonApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
        ), // Warna utama tema
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(), // Gunakan font Poppins
      ),
      home: PokemonPage(), // Halaman utama
    );
  }
}

// Halaman utama: daftar Pokemon
class PokemonPage extends StatefulWidget {
  @override
  _PokemonPageState createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage> {
  List<Pokemon> _pokemons = []; // Semua data Pokemon
  List<Pokemon> _filteredPokemons = []; // Data yang difilter
  bool _isLoading = false; // Status loading
  String _error = ''; // Menyimpan pesan error
  final TextEditingController _searchController =
      TextEditingController(); // Untuk input pencarian

  // Fungsi untuk mengambil data dari API PokeAPI
  Future<void> fetchPokemons() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _pokemons = [];
      _filteredPokemons = [];
    });

    final uri = Uri.https('pokeapi.co', '/api/v2/pokemon', {'limit': '100'});

    try {
      final response = await http.get(uri); // Ambil data dari API

      if (response.statusCode != 200) {
        throw HttpException(
          'Gagal mengambil data. Status: ${response.statusCode}',
        );
      }

      final jsonResponse = json.decode(response.body);
      final List results = jsonResponse['results'];

      final pokemons =
          results.asMap().entries.map((entry) {
            final index = entry.key;
            final json = entry.value;
            final id = index + 1;
            final imageUrl =
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';

            return Pokemon(
              name: json['name'],
              url: json['url'],
              imageUrl: imageUrl,
            );
          }).toList();

      pokemons.sort(
        (a, b) => a.name.compareTo(b.name),
      ); // Urutkan berdasarkan nama

      setState(() {
        _pokemons = List<Pokemon>.from(pokemons);
        _filteredPokemons = _pokemons;
      });
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false; // Selesai loading
      });
    }
  }

  // Filter pencarian
  void _filterPokemons(String query) {
    final filtered =
        _pokemons
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
    setState(() {
      _filteredPokemons = filtered;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchPokemons(); // Ambil data saat halaman dibuka
  }

  // Widget untuk kartu tampilan setiap Pokemon
  Widget _buildPokemonCard(Pokemon poke) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      elevation: 3,
      shadowColor: Colors.redAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Image.network(
          poke.imageUrl,
          width: 50,
          height: 50,
          errorBuilder:
              (context, error, stackTrace) => Icon(Icons.image_not_supported),
        ),
        title: Text(
          poke.name.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        trailing: Icon(Icons.catching_pokemon, color: Colors.redAccent),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PokemonDetailPage(
                    pokemon: poke,
                  ), // Navigasi ke halaman detail
            ),
          );
        },
      ),
    );
  }

  // UI utama halaman PokemonPage
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PokemonApp'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchPokemons,
          ), // Tombol refresh
        ],
      ),
      body: Column(
        children: [
          // Pencarian
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              onChanged: _filterPokemons,
              decoration: InputDecoration(
                hintText: 'Cari nama Pokémon',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Daftar Pokémon
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(),
                    ) // Loading indikator
                    : _error.isNotEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _error,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                    : _filteredPokemons.isEmpty
                    ? Center(child: Text('Tidak ada Pokémon ditemukan.'))
                    : ListView.builder(
                      itemCount: _filteredPokemons.length,
                      itemBuilder: (context, index) {
                        final poke = _filteredPokemons[index];
                        return _buildPokemonCard(poke); // Tampilkan item
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// Model data Pokémon
class Pokemon {
  final String name;
  final String url;
  final String imageUrl;

  Pokemon({required this.name, required this.url, required this.imageUrl});
}

// Halaman detail Pokémon
class PokemonDetailPage extends StatefulWidget {
  final Pokemon pokemon;

  PokemonDetailPage({required this.pokemon});

  @override
  _PokemonDetailPageState createState() => _PokemonDetailPageState();
}

class _PokemonDetailPageState extends State<PokemonDetailPage> {
  Map<String, dynamic>? _detail; // Menyimpan detail dari API
  bool _isLoading = false;
  String _error = '';

  // Ambil data detail dari API
  Future<void> fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final uri = Uri.parse(widget.pokemon.url);

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw HttpException(
          'Gagal mengambil detail. Status: ${response.statusCode}',
        );
      }
      final jsonResponse = json.decode(response.body);
      setState(() {
        _detail = jsonResponse;
      });
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Kapitalisasi string
  String _capitalize(String text) => text[0].toUpperCase() + text.substring(1);

  // Widget untuk menampilkan stat bar
  Widget _buildStatBar(String name, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$name: $value'),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 150,
            minHeight: 8,
            color: Colors.redAccent,
            backgroundColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan tipe Pokémon
  Widget _buildTypes(List types) {
    return Wrap(
      spacing: 8,
      children:
          types.map<Widget>((type) {
            return Chip(
              label: Text(
                _capitalize(type['type']['name']),
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
            );
          }).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchDetail(); // Ambil data detail saat pertama kali dibuka
  }

  // UI Halaman Detail
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pokemon.name.toUpperCase()),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(),
              ) // Tampilkan loading saat mengambil data
              : _error.isNotEmpty
              ? Center(child: Text(_error, style: TextStyle(color: Colors.red)))
              : _detail == null
              ? Center(child: Text('Tidak ada detail.'))
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Gambar Pokémon
                    Image.network(
                      _detail!['sprites']['other']['official-artwork']['front_default'],
                      height: 180,
                    ),
                    SizedBox(height: 12),
                    // Nama dan ID
                    Text(
                      '#${_detail!['id']}  ${_capitalize(_detail!['name'])}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildTypes(_detail!['types']),
                    SizedBox(height: 16),
                    // Tinggi dan Berat
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.height),
                            SizedBox(height: 4),
                            Text('${_detail!['height'] / 10} m'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.monitor_weight),
                            SizedBox(height: 4),
                            Text('${_detail!['weight'] / 10} kg'),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    // Statistik
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Stats',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    // Tampilkan semua stat
                    ..._detail!['stats'].map<Widget>((stat) {
                      return _buildStatBar(
                        _capitalize(stat['stat']['name']),
                        stat['base_stat'],
                      );
                    }).toList(),
                  ],
                ),
              ),
    );
  }
}

// Kelas custom exception untuk error HTTP
class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => 'HttpException: $message';
}
