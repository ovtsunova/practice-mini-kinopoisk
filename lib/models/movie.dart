class Movie {
  int? id;
  String title;
  String director;
  DateTime releaseDate;
  String genre;
  double rating;
  String? imagePath;
  String? notes;

  Movie({
    this.id,
    required this.title,
    required this.director,
    required this.releaseDate,
    required this.genre,
    required this.rating,
    this.imagePath,
    this.notes,
  });

  int get year => releaseDate.year;
  
  String get formattedDate {
    final months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${releaseDate.day} ${months[releaseDate.month - 1]} ${releaseDate.year}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'director': director,
      'releaseDate': releaseDate.toIso8601String(),
      'genre': genre,
      'rating': rating,
      'imagePath': imagePath,
      'notes': notes,
    };
  }

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'],
      title: map['title'],
      director: map['director'],
      releaseDate: DateTime.parse(map['releaseDate']),
      genre: map['genre'],
      rating: map['rating'],
      imagePath: map['imagePath'],
      notes: map['notes'],
    );
  }
}