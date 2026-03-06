import 'package:flutter/material.dart';
import 'dart:io';
import '../models/movie.dart';
import '../services/database_helper.dart';
import 'add_edit_movie_screen.dart';

class MovieListScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const MovieListScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Movie> _movies = [];

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    final movies = await _dbHelper.getMovies();
    setState(() {
      _movies = movies;
    });
  }

  Future<void> _deleteMovie(int id) async {
    await _dbHelper.deleteMovie(id);
    _loadMovies();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Фильм удален')),
      );
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return Colors.green;
    if (rating >= 6.0) return Colors.orange;
    if (rating >= 4.0) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои любимые фильмы'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onThemeToggle,
            tooltip: 'Сменить тему',
          ),
        ],
      ),
      body: _movies.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.movie_filter, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Фильмов пока нет',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text('Нажмите + чтобы добавить первый фильм!'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _movies.length,
              itemBuilder: (context, index) {
                final movie = _movies[index];
                final ratingColor = _getRatingColor(movie.rating);
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 50,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          image: movie.imagePath != null && File(movie.imagePath!).existsSync()
                              ? DecorationImage(
                                  image: FileImage(File(movie.imagePath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: movie.imagePath == null || !File(movie.imagePath!).existsSync()
                            ? const Icon(Icons.movie, size: 30)
                            : null,
                      ),
                    ),
                    title: Text(
                      movie.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          movie.director,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          movie.formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                movie.genre,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: ratingColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  movie.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ratingColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditMovieScreen(movie: movie),
                              ),
                            );
                            if (result == true) _loadMovies();
                          },
                          tooltip: 'Редактировать',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => _showDeleteDialog(movie.id!),
                          tooltip: 'Удалить',
                        ),
                      ],
                    ),
                    onTap: () => _showMovieDetails(movie),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditMovieScreen()),
          );
          if (result == true) _loadMovies();
        },
        tooltip: 'Добавить фильм',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление фильма'),
        content: const Text('Вы уверены, что хотите удалить этот фильм?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteMovie(id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showMovieDetails(Movie movie) {
    final ratingColor = _getRatingColor(movie.rating);
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        movie.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                      tooltip: 'Закрыть',
                    ),
                  ],
                ),
                const Divider(),
                if (movie.imagePath != null && File(movie.imagePath!).existsSync())
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(movie.imagePath!),
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildDetailRow('Режиссер:', movie.director),
                _buildDetailRow('Дата выхода:', movie.formattedDate),
                _buildDetailRow('Жанр:', movie.genre),
                _buildDetailRow('Рейтинг:', '${movie.rating.toStringAsFixed(1)}/10', 
                  icon: Icon(Icons.star, color: ratingColor, size: 18),
                  textColor: ratingColor,
                ),
                if (movie.notes != null && movie.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Заметки:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(movie.notes!),
                ],
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Закрыть'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Widget? icon, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: icon != null 
              ? Row(children: [icon, const SizedBox(width: 4), Text(value, style: TextStyle(color: textColor))])
              : Text(value),
          ),
        ],
      ),
    );
  }
}