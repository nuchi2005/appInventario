import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:exif/exif.dart';

class PhotoScreen extends StatefulWidget {
  final int equipmentId;

  PhotoScreen({required this.equipmentId});

  @override
  _PhotoScreenState createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  List<File> _images = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final directoryPath = Directory('$path/${widget.equipmentId}');
    if (directoryPath.existsSync()) {
      setState(() {
        _images =
            directoryPath.listSync().map((item) => File(item.path)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final directoryPath = Directory('$path/${widget.equipmentId}');

      if (!directoryPath.existsSync()) {
        directoryPath.createSync(recursive: true);
      }

      final fileName = basename(pickedFile.path);
      final File localImage =
          await File(pickedFile.path).copy('${directoryPath.path}/$fileName');

      setState(() {
        _images.add(localImage);
      });
    }
  }

  void _openPhotoViewGallery(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewGalleryScreen(
          images: _images,
          initialIndex: index,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<String?> _getImageCreationDate(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final tags = await readExifFromBytes(bytes);
      if (tags!.containsKey('Image DateTime')) {
        final dateTime = tags['Image DateTime']?.printable;
        if (dateTime != null) {
          final parsedDate = DateTime.parse(
              dateTime.replaceFirst(':', '-').replaceFirst(':', '-'));
          final formattedDate =
              '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
          return formattedDate;
        }
      }
    } catch (e) {
      print('Error reading EXIF data: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fotos del Equipo'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _images.isEmpty
                    ? Center(child: Text('No hay fotos disponibles.'))
                    : Container(
                        padding: EdgeInsets.all(8.0),
                        color:
                            Colors.grey[200], // Fondo elegante para la galería
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                          ),
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () =>
                                  _openPhotoViewGallery(context, index),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4.0,
                                          offset: Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: Image.file(
                                        _images[index],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8.0,
                                    right: 8.0,
                                    child: Container(
                                      padding: EdgeInsets.all(4.0),
                                      color: Colors.black54,
                                      child: FutureBuilder<String?>(
                                        future: _getImageCreationDate(
                                            _images[index]),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return CircularProgressIndicator();
                                          } else if (snapshot.hasError ||
                                              !snapshot.hasData) {
                                            return Text(
                                              'Fecha desconocida',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          } else {
                                            return Text(
                                              snapshot.data!,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8.0,
                                    right: 8.0,
                                    child: IconButton(
                                      icon: Icon(Icons.share,
                                          color: Colors.white),
                                      onPressed: () {
                                        Share.shareFiles([_images[index].path],
                                            text: 'Mira esta foto!');
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.camera_alt),
              label: Text('Tomar Foto'),
            ),
          ),
        ],
      ),
    );
  }
}

class PhotoViewGalleryScreen extends StatelessWidget {
  final List<File> images;
  final int initialIndex;

  PhotoViewGalleryScreen({required this.images, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Galería de Fotos'),
      ),
      body: PhotoViewGallery.builder(
        itemCount: images.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: FileImage(images[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        scrollPhysics: BouncingScrollPhysics(),
        backgroundDecoration: BoxDecoration(color: Colors.black),
        pageController: PageController(initialPage: initialIndex),
      ),
    );
  }
}
