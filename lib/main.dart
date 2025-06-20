import 'package:flutter/material.dart'; // Paket UI utama Flutter
import 'package:http/http.dart' as http; // Paket HTTP untuk fetch API
import 'package:google_fonts/google_fonts.dart'; // Paket Google Fonts
import 'dart:convert'; // Untuk decoding JSON

void main() {
  runApp(MyApp()); // Menjalankan aplikasi
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Root aplikasi dengan MaterialApp
    return MaterialApp(
      title: 'PokemonApp', // Judul aplikasi
      debugShowCheckedModeBanner: false, // Hilangkan banner debug
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
        ), // Tema warna
        useMaterial3: true, // Menggunakan Material 3
        textTheme: GoogleFonts.poppinsTextTheme(), // Font Poppins
      ),
      home: PokemonPage(), // Halaman utama
    );
  }
}

class PokemonPage extends StatefulWidget {
  @override
  _PokemonPageState createState() => _PokemonPageState(); // State untuk PokemonPage
}

class _PokemonPageState extends State<PokemonPage> {
  List<Pokemon> _pokemons = []; // List semua pokemon
  List<Pokemon> _filteredPokemons = []; // List pokemon hasil filter
  bool _isLoading = false; // Status loading
  String _error = ''; // Pesan error
  final TextEditingController _searchController =
      TextEditingController(); // Controller input pencarian

  Future<void> fetchPokemons() async {
    // Fetch data pokemon dari API
    setState(() {
      _isLoading = true;
      _error = '';
      _pokemons = [];
      _filteredPokemons = [];
    });

    final uri = Uri.https('pokeapi.co', '/api/v2/pokemon', {
      'limit': '100',
    }); // API endpoint

    try {
      final response = await http.get(uri); // Request GET

      if (response.statusCode != 200) {
        throw HttpException(
          'Gagal mengambil data. Status: ${response.statusCode}', // Jika gagal, lempar error
        );
      }

      final jsonResponse = json.decode(response.body); // Decode JSON response
      final List results = jsonResponse['results']; // Ambil list pokemon
      final pokemons =
          results.asMap().entries.map((entry) {
            // Map ke model Pokemon
            final index = entry.key;
            final json = entry.value;
            final id = index + 1; // Hitung ID berdasarkan index (1-based)
            final imageUrl =
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png'; // URL gambar
            return Pokemon(
              name: json['name'], // Nama pokemon
              url: json['url'], // URL detail
              imageUrl: imageUrl, // URL gambar
            );
          }).toList();

      pokemons.sort((a, b) => a.name.compareTo(b.name)); // Urutkan alfabet

      setState(() {
        _pokemons = List<Pokemon>.from(pokemons);
        _filteredPokemons = _pokemons;
      });
    } catch (e) {
      // Tangkap error
      setState(() {
        _error = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false; // Selesai loading
      });
    }
  }

  void _filterPokemons(String query) {
    // Filter list pokemon berdasarkan query
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
    fetchPokemons(); // Fetch pokemon saat pertama load
  }

  Widget _buildPokemonCard(Pokemon poke) {
    // Widget kartu pokemon
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      elevation: 3,
      shadowColor: Colors.redAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Image.network(
          poke.imageUrl, // Tampilkan gambar
          width: 50,
          height: 50,
          errorBuilder:
              (context, error, stackTrace) =>
                  Icon(Icons.image_not_supported), // Jika gagal load gambar
        ),
        title: Text(
          poke.name.toUpperCase(), // Tampilkan nama
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        trailing: Icon(
          Icons.catching_pokemon,
          color: Colors.redAccent,
        ), // Icon pokeball
        onTap: () {
          // Navigate ke detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PokemonDetailPage(pokemon: poke),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build UI halaman utama
    return Scaffold(
      appBar: AppBar(
        title: Text('PokemonApp'), // Judul appbar
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
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              onChanged: _filterPokemons, // Panggil filter saat input berubah
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
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(),
                    ) // Tampilkan loading
                    : _error.isNotEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _error, // Tampilkan error
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : _filteredPokemons.isEmpty
                    ? Center(
                      child: Text('Tidak ada Pokémon ditemukan.'),
                    ) // Tidak ada data
                    : ListView.builder(
                      itemCount: _filteredPokemons.length,
                      itemBuilder: (context, index) {
                        final poke = _filteredPokemons[index];
                        return _buildPokemonCard(poke); // Tampilkan list
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class Pokemon {
  final String name; // Nama pokemon
  final String url; // URL API detail
  final String imageUrl; // URL gambar

  Pokemon({required this.name, required this.url, required this.imageUrl});
}

class PokemonDetailPage extends StatefulWidget {
  final Pokemon pokemon; // Data pokemon dikirim

  PokemonDetailPage({required this.pokemon});

  @override
  _PokemonDetailPageState createState() => _PokemonDetailPageState();
}

class _PokemonDetailPageState extends State<PokemonDetailPage> {
  Map<String, dynamic>? _detail; // Data detail
  bool _isLoading = false; // Status loading
  String _error = ''; // Pesan error

  Future<void> fetchDetail() async {
    // Fetch detail pokemon
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final uri = Uri.parse(widget.pokemon.url); // URL detail

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw HttpException(
          'Gagal mengambil detail. Status: ${response.statusCode}', // Error status
        );
      }

      final jsonResponse = json.decode(response.body); // Decode JSON

      setState(() {
        _detail = jsonResponse;
      });
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: ${e.toString()}'; // Tampilkan error
      });
    } finally {
      setState(() {
        _isLoading = false; // Selesai loading
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDetail(); // Fetch detail saat masuk halaman
  }

  @override
  Widget build(BuildContext context) {
    // UI detail pokemon
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pokemon.name.toUpperCase()),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? Center(child: Text(_error, style: TextStyle(color: Colors.red)))
              : _detail == null
              ? Center(child: Text('Tidak ada detail.'))
              : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Image.network(
                          _detail!['sprites']['front_default'] ??
                              '', // Gambar detail
                          height: 150,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'ID: ${_detail!['id']}',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Height: ${_detail!['height']}',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Weight: ${_detail!['weight']}',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Types: ${(_detail!['types'] as List).map((t) => t['type']['name']).join(', ')}',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}

class HttpException implements Exception {
  final String message; // Pesan error custom
  HttpException(this.message);
  @override
  String toString() => 'HttpException: $message';
}
