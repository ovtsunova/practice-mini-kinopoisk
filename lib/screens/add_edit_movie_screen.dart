import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/movie.dart';
import '../services/database_helper.dart';

class AddEditMovieScreen extends StatefulWidget {
  final Movie? movie;

  const AddEditMovieScreen({super.key, this.movie});

  @override
  State<AddEditMovieScreen> createState() => _AddEditMovieScreenState();
}

class _AddEditMovieScreenState extends State<AddEditMovieScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _directorController = TextEditingController();
  final _dateController = TextEditingController();
  final _genreController = TextEditingController();
  final _ratingController = TextEditingController();
  final _notesController = TextEditingController();
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  final List<String> _genres = [
    'Боевик',
    'Вестерн',
    'Детектив',
    'Документальный',
    'Драма',
    'Исторический',
    'Комедия',
    'Криминал',
    'Мелодрама',
    'Мистика',
    'Приключения',
    'Семейный',
    'Спорт',
    'Триллер',
    'Ужасы',
    'Фантастика',
    'Фэнтези',
  ];
  
  String? _selectedGenre;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.movie != null) {
      _titleController.text = widget.movie!.title;
      _directorController.text = widget.movie!.director;
      _selectedDate = widget.movie!.releaseDate;
      _dateController.text = _formatDate(widget.movie!.releaseDate);
      _selectedGenre = widget.movie!.genre;
      _genreController.text = widget.movie!.genre;
      _ratingController.text = widget.movie!.rating.toString();
      _notesController.text = widget.movie!.notes ?? '';
      if (widget.movie!.imagePath != null) {
        _imageFile = File(widget.movie!.imagePath!);
      }
    } else {
      _selectedDate = DateTime.now();
      _dateController.text = _formatDate(DateTime.now());
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1888),
      lastDate: DateTime.now(),
      locale: const Locale('ru', 'RU'),
      helpText: 'Выберите дату выхода',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выборе изображения: $e')),
        );
      }
    }
  }

  String? _validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите название фильма';
    }
    if (value.length < 2) {
      return 'Название должно содержать минимум 2 символа';
    }
    if (value.length > 100) {
      return 'Название не может быть длиннее 100 символов';
    }
    return null;
  }

  String? _validateDirector(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите имя режиссера';
    }
    if (value.length < 3) {
      return 'Имя режиссера должно содержать минимум 3 символа';
    }
    final RegExp nameRegExp = RegExp(r'^[a-zA-Zа-яА-Я\s\.\-]+$');
    if (!nameRegExp.hasMatch(value)) {
      return 'Имя может содержать только буквы, пробелы, точки и дефисы';
    }
    return null;
  }

  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Выберите дату выхода';
    }
    return null;
  }

  String? _validateGenre(String? value) {
    if (value == null || value.isEmpty) {
      return 'Выберите или введите жанр';
    }
    if (value.length < 3) {
      return 'Жанр должен содержать минимум 3 символа';
    }
    return null;
  }

  String? _validateRating(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите рейтинг';
    }
    
    String processedValue = value.replaceAll(',', '.');
    
    final rating = double.tryParse(processedValue);
    if (rating == null) {
      return 'Введите корректное число (используйте . или ,)';
    }
    
    if (rating < 0 || rating > 10) {
      return 'Рейтинг должен быть от 0 до 10';
    }
    
    final parts = processedValue.split('.');
    if (parts.length > 1 && parts[1].length > 1) {
      return 'Используйте не более одного знака после запятой';
    }
    
    return null;
  }

  Future<void> _saveMovie() async {
    if (_formKey.currentState!.validate()) {
      String ratingValue = _ratingController.text.replaceAll(',', '.');
      
      final movie = Movie(
        id: widget.movie?.id,
        title: _titleController.text.trim(),
        director: _directorController.text.trim(),
        releaseDate: _selectedDate!,
        genre: _selectedGenre ?? _genreController.text.trim(),
        rating: double.parse(ratingValue),
        imagePath: _imageFile?.path,
        notes: _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
      );

      final dbHelper = DatabaseHelper();
      
      try {
        if (widget.movie == null) {
          await dbHelper.insertMovie(movie);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Фильм успешно добавлен!')),
            );
          }
        } else {
          await dbHelper.updateMovie(movie);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Фильм успешно обновлен!')),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при сохранении: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie == null ? 'Добавить фильм' : 'Редактировать фильм'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 50,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Нажмите чтобы добавить постер',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          if (widget.movie != null && widget.movie!.imagePath == null)
                            const Text('(необязательно)'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название фильма *',
                border: OutlineInputBorder(),
                hintText: 'Например: Начало',
                prefixIcon: Icon(Icons.movie),
              ),
              validator: _validateTitle,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _directorController,
              decoration: const InputDecoration(
                labelText: 'Режиссер *',
                border: OutlineInputBorder(),
                hintText: 'Например: Кристофер Нолан',
                prefixIcon: Icon(Icons.person),
              ),
              validator: _validateDirector,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Дата выхода *',
                border: const OutlineInputBorder(),
                hintText: 'Выберите дату',
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () => _selectDate(context),
                  tooltip: 'Выбрать дату',
                ),
              ),
              validator: _validateDate,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<String>(
              value: _selectedGenre,
              decoration: const InputDecoration(
                labelText: 'Жанр *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              hint: const Text('Выберите жанр'),
              validator: _validateGenre,
              items: [
                ..._genres.map((genre) => DropdownMenuItem(
                  value: genre,
                  child: Text(genre),
                )),
                const DropdownMenuItem(
                  value: 'Другой',
                  child: Text('Другой (ввести вручную)'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGenre = value;
                  if (value == 'Другой') {
                    _genreController.clear();
                  } else if (value != null) {
                    _genreController.text = value;
                  }
                });
              },
            ),
            
            if (_selectedGenre == 'Другой') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _genreController,
                decoration: const InputDecoration(
                  labelText: 'Введите жанр *',
                  border: OutlineInputBorder(),
                  hintText: 'Например: Постапокалипсис',
                ),
                validator: _validateGenre,
                textCapitalization: TextCapitalization.words,
              ),
            ],
            
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _ratingController,
              decoration: const InputDecoration(
                labelText: 'Рейтинг (0-10) *',
                border: OutlineInputBorder(),
                hintText: 'Например: 8.5',
                prefixIcon: Icon(Icons.star),
                helperText: 'Используйте точку или запятую',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _validateRating,
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Заметки (необязательно)',
                border: OutlineInputBorder(),
                hintText: 'Ваши личные заметки о фильме...',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              maxLength: 500,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                return Text('$currentLength/$maxLength');
              },
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _saveMovie,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                widget.movie == null ? 'Добавить фильм' : 'Сохранить изменения',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _directorController.dispose();
    _dateController.dispose();
    _genreController.dispose();
    _ratingController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}