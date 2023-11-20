import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MaterialApp(
    home: ClockApp(),
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
}

class ClockApp extends StatefulWidget {
  @override
  _ClockAppState createState() => _ClockAppState();
}

class _ClockAppState extends State<ClockApp>
    with SingleTickerProviderStateMixin {
  String _selectedOrientation = 'Auto';
  String _dateSeparator = '-';
  int _offset = 0;
  bool _autoSave = false;
  bool _dateSep = true;
  String _timeFormat = "HH:mm:ss";
  bool __offsetOnMain = true;
  bool _showDate = true;
  bool _showAmPm = true;
  bool _twelveHour = false;
  bool _isRGBEnabled = true;
  bool _useImageBackground = false;
  String _backgroundImage = '';
  Color _backgroundColor = Colors.black;
  Color _customColor = Colors.white;
  double _fontSize = 50.0;
  FontWeight _selectedFontWeight = FontWeight.normal;
  String _selectedDateFormat = 'dd/MM/yyyy';

  final takeInput = TextEditingController();
  late Timer _timer;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final randomGen = Random();
  late AnimationController _controller;
  bool _isFabVisible = false;

  void _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('useImageBackground', _useImageBackground);
    prefs.setInt('backgroundColor', _backgroundColor.value);
    prefs.setString('bg', _backgroundImage);
    prefs.setString('_timeFormat', _timeFormat);
    prefs.setBool('showDate', _showDate);
    prefs.setBool('showAmPm', _showAmPm);
    prefs.setBool('twelveHour', _twelveHour);
    prefs.setBool('rgb', _isRGBEnabled);
    prefs.setString('_dateSeparator', _dateSeparator);

    prefs.setDouble('fontSize', _fontSize);
    prefs.setInt('fontColor', _customColor.value);
    prefs.setInt(
        'fontWeightIndex', FontWeight.values.indexOf(_selectedFontWeight));
    prefs.setString('_selectedDateFormat', _selectedDateFormat);
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _useImageBackground =
          prefs.getBool('useImageBackground') ?? _useImageBackground;
      _customColor = Color(prefs.getInt('fontColor') ?? _customColor.value);
      _backgroundColor =
          Color(prefs.getInt('backgroundColor') ?? _backgroundColor.value);
      _dateSeparator = prefs.getString('_dateSeparator') ?? _dateSeparator;
      _timeFormat = prefs.getString('_timeFormat') ?? "HH:mm:ss";
      _showDate = prefs.getBool('showDate') ?? _showDate;
      _showAmPm = prefs.getBool('showAmPm') ?? _showAmPm;
      _twelveHour = prefs.getBool('twelveHour') ?? _twelveHour;
      _isRGBEnabled = prefs.getBool('rgb') ?? _isRGBEnabled;
      _fontSize = prefs.getDouble('fontSize') ?? _fontSize;
      _customColor = Color(prefs.getInt('fontColor') ?? _customColor.value);
      _backgroundImage = prefs.getString('bg') ?? _backgroundImage;
      _backgroundImage = prefs.getString('bg') ?? _backgroundImage;
      _selectedDateFormat = prefs.getString('_selectedDateFormat') ??
          'dd' + _dateSeparator + 'MM' + _dateSeparator + 'yyyy';
      int fontWeightIndex = prefs.getInt('fontWeightIndex') ?? 0;
      _selectedFontWeight = FontWeight.values[fontWeightIndex];
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _startTimer();
    if (_isRGBEnabled) {
      _controller = AnimationController(
        duration: const Duration(seconds: 5),
        vsync: this,
      )..repeat();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    if (_autoSave) _saveSettings();
    _controller.dispose();
    takeInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFabVisible = !_isFabVisible;
        });
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        key: _scaffoldKey,
        backgroundColor:
            _useImageBackground ? Colors.transparent : _backgroundColor,
        floatingActionButton: _isFabVisible
            ? getFAB(const Icon(Icons.settings), () => openDrawer(_scaffoldKey))
            : null,
        drawer: Drawer(
          backgroundColor: Colors.transparent.withOpacity(0.4),
          child: ListView(
            children: [
              getDrawerOption('Pick Accent Color', () {
                _pickCustomColor(_customColor, (Color newColor) {
                  setState(() {
                    _customColor = newColor;
                  });
                });
              }),
              getDrawerOption('Toggle Background Type', () {
                _toggleBackgroundType();
              }),
              getDrawerOption(
                  _useImageBackground
                      ? 'Pick Background Image'
                      : 'Pick Background Color', () {
                _useImageBackground
                    ? _pickBackgroundImage()
                    : _pickCustomColor(_backgroundColor, (Color newColor) {
                        setState(() {
                          _backgroundColor = newColor;
                        });
                      });
              }),
              getDrawerOption('Adjust Font Size', () {
                _adjustFontSize();
              }),
              getDrawerOption('General Settings', () {
                _generalSettingsDialog();
              }),
              getDrawerOption('Time Settings', () {
                _toggleComponentsDialog();
              }),
              getDrawerOption('Timezone/offset Settings', () {
                __offsetSettingsDialog();
              }),
              getDrawerOption('Save Settings', () {
                _saveSettings();
              }),
            ],
          ),
        ),
        body: Stack(
          children: [
            if (_useImageBackground)
              Image.file(
                File(_backgroundImage),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _isRGBEnabled
                      ? AnimatedBuilder(
                          animation: _controller,
                          builder: (BuildContext context, Widget? child) {
                            return _buildTimeStringWidget();
                          },
                        )
                      : _buildTimeStringWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeStringWidget() {
    return Text(
      _getTimeString(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: _fontSize,
        fontWeight: _selectedFontWeight,
        color: _isRGBEnabled ? getRGB() : _customColor,
      ),
    );
  }

  void openDrawer(GlobalKey<ScaffoldState> scaffoldKey) {
    scaffoldKey.currentState?.openDrawer();
  }

  FloatingActionButton getFAB(Icon icon, VoidCallback toDoOnTap) {
    return FloatingActionButton(
      foregroundColor: _customColor,
      backgroundColor: Colors.transparent,
      onPressed: () {
        toDoOnTap();
      },
      shape: RoundedRectangleBorder(
        side: BorderSide(width: 2, color: _customColor),
        borderRadius: BorderRadius.circular(100),
      ),
      child: icon,
    );
  }

  ListTile getDrawerOption(String text, VoidCallback toDoOnTap) {
    return ListTile(
      title: Text(
        text,
        style: TextStyle(color: _customColor),
      ),
      onTap: () {
        toDoOnTap();
      },
    );
  }

  void _toggleBackgroundType() {
    setState(() {
      _useImageBackground = !_useImageBackground;
    });
  }

  Color getRGB() {
    int r = (sin(_controller.value * 2 * pi) * 127.5 + 127.5).toInt();
    int g =
        (sin(_controller.value * 2 * pi + 2 / 3 * pi) * 127.5 + 127.5).toInt();
    int b =
        (sin(_controller.value * 2 * pi + 4 / 3 * pi) * 127.5 + 127.5).toInt();
    return Color.fromARGB(255, r, g, b);
  }

  void _pickBackgroundImage() async {
    Navigator.pop(context);
    try {
      final pickedImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _backgroundImage = pickedImage.path;
        });
      }
    } catch (e) {
      print('Error picking background image: $e');
    }
  }

  void _pickCustomColor(Color colorFiSet, void Function(Color) setColor) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color selectedColor = colorFiSet;
        return AlertDialog(
          backgroundColor: Colors.transparent,
          title: Text('Pick Custom Color'),
          titleTextStyle: TextStyle(
            color: _customColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0)),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              labelTextStyle: TextStyle(
                color: _customColor,
              ),
              onColorChanged: (Color color) {
                setState(() {
                  selectedColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setColor(selectedColor);
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _adjustFontSize() {
    Navigator.pop(context);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          double selectedFontSize = _fontSize;
          final double screenWidth = MediaQuery.of(context).size.width;
          final double screenHeight = MediaQuery.of(context).size.height;
          double maxSliderValue =
              MediaQuery.of(context).orientation == Orientation.portrait
                  ? screenWidth
                  : screenHeight;
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(32.0))),
                insetPadding: EdgeInsets.only(bottom: screenHeight / 2.0),
                title: const Text('Adjust Font Size'),
                titleTextStyle: TextStyle(
                  color: _customColor,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Current Font Size: ${(selectedFontSize)})',
                        style: TextStyle(color: _customColor)),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _customColor,
                        inactiveTrackColor: Colors.grey,
                        trackShape: RectangularSliderTrackShape(),
                        trackHeight: 4.0,
                        thumbColor: _customColor,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 12.0),
                        overlayColor: Colors.blue.withAlpha(32),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 28.0),
                      ),
                      child: Slider.adaptive(
                        value: _fontSize,
                        min: 10,
                        max: maxSliderValue,
                        onChanged: (double value) {
                          setState(() {
                            _fontSize = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      /* setState(() {
                        _fontSize = _fontSize;
                      });*/

                      Navigator.of(context).pop(); //maybe set temp variable
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        });
  }

  String _getTimeString() {
    final DateTime now = _offset == 0
        ? DateTime.now()
        : DateTime.now().add(Duration(hours: _offset));
    final StringBuffer timeString = StringBuffer();

    timeString.write(DateFormat(_timeFormat).format(now));

    if (_showAmPm) {
      timeString.write(' ${DateFormat('a').format(now)}');
    }

    if (_showDate) {
      timeString.writeln('\n${DateFormat(_selectedDateFormat).format(now)}');
    }

    return timeString.toString();
  }

  void __offsetSettingsDialog() {
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('_offset Settings'),
          titleTextStyle: TextStyle(
            color: _customColor,
          ),
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleSwitch('Show AM/PM', __offsetOnMain, () {
                  setState(() {
                    __offsetOnMain = !__offsetOnMain;
                  });
                }),
                TextField(
                  controller: takeInput,
                  style: TextStyle(color: _customColor),
                  decoration: InputDecoration(
                      labelStyle: TextStyle(
                        color: _customColor,
                      ),
                      labelText: 'UTC _offset (Current UTC: ' +
                          DateTime.now().toUtc().toString() +
                          ')'),
                  keyboardType: TextInputType.number,
                  onChanged: (text) {
                    _offset = int.parse(text);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _generalSettingsDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Time Settings'),
          titleTextStyle: TextStyle(
            color: _customColor,
          ),
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleSwitch('Auto Save', _showDate, () {
                  setState(() {
                    _autoSave = !_autoSave;
                  });
                }),
                StatefulBuilder(
                  builder: (context, setState) => DropdownButton<String>(
                    dropdownColor: Colors.transparent.withOpacity(0.5),
                    value: _selectedOrientation,
                    items: [
                      createDropdownMenuItem('Auto', 'Auto'),
                      createDropdownMenuItem('Portrait', 'Portrait'),
                      createDropdownMenuItem('Landscape', 'Landscape'),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedOrientation = value;
                          switch (value) {
                            case 'Portrait':
                              SystemChrome.setPreferredOrientations([
                                DeviceOrientation.portraitUp,
                                DeviceOrientation.portraitDown,
                              ]);
                              break;
                            case 'Landscape':
                              SystemChrome.setPreferredOrientations([
                                DeviceOrientation.landscapeLeft,
                                DeviceOrientation.landscapeRight,
                              ]);
                              break;
                            default:
                              SystemChrome.setPreferredOrientations([
                                DeviceOrientation.landscapeRight,
                                DeviceOrientation.landscapeLeft,
                                DeviceOrientation.portraitUp,
                                DeviceOrientation.portraitDown,
                              ]);
                          }
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleComponentsDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Time Settings'),
          titleTextStyle: TextStyle(
            color: _customColor,
          ),
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleSwitch('RGB Effect', _isRGBEnabled, () {
                  setState(() {
                    _isRGBEnabled = !_isRGBEnabled;
                  });
                }),
                StatefulBuilder(
                  builder: (context, setState) => DropdownButton<String>(
                    dropdownColor: Colors.transparent.withOpacity(0.5),
                    value: _timeFormat,
                    items: [
                      createDropdownMenuItem("HH:mm", 'HH:MM'),
                      createDropdownMenuItem("mm:ss", 'MM:SS'),
                      createDropdownMenuItem('HH:mm:ss', 'HH:MM:SS'),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _timeFormat = value;
                          if (value == "mm:ss") {
                            _showAmPm = false;
                          }
                        });
                      }
                    },
                  ),
                ),
                _buildToggleSwitch('Show Date', _showDate, () {
                  setState(() {
                    _showDate = !_showDate;
                  });
                }),
                Text(
                  'Date Format:',
                  style: TextStyle(color: _customColor),
                ),
                StatefulBuilder(
                  builder: (context, setState) => DropdownButton<String>(
                    dropdownColor: Colors.transparent.withOpacity(0.5),
                    value: _selectedDateFormat,
                    items: [
                      createDropdownMenuItem(
                          'yyyy' +
                              _dateSeparator +
                              'MM' +
                              _dateSeparator +
                              'dd',
                          'yyyy-MM-dd'),
                      createDropdownMenuItem(
                          'MM' +
                              _dateSeparator +
                              'dd' +
                              _dateSeparator +
                              'yyyy',
                          'MM/dd/yyyy'),
                      createDropdownMenuItem(
                          'dd' +
                              _dateSeparator +
                              'MM' +
                              _dateSeparator +
                              'yyyy',
                          'dd/MM/yyyy'),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedDateFormat = value;
                        });
                      }
                    },
                  ),
                ),
                _buildToggleSwitch('Date Separator (/ or -)', _dateSep, () {
                  setState(() {
                    _dateSep = !_dateSep;
                    _dateSeparator = _dateSep ? '-' : '/';
                    _selectedDateFormat =
                        _selectedDateFormat.replaceAll('-', _dateSeparator);
                    _selectedDateFormat =
                        _selectedDateFormat.replaceAll('/', _dateSeparator);
                  });
                }),
                _buildToggleSwitch('24/12 Hour', _twelveHour, () {
                  setState(() {
                    _twelveHour = !_twelveHour;
                    _timeFormat = _timeFormat.replaceFirst(
                        _twelveHour ? "HH" : "h", _twelveHour ? "h" : "HH");
                  });
                }),
                _buildToggleSwitch('Show AM/PM', _showAmPm, () {
                  setState(() {
                    _showAmPm = !_showAmPm;
                  });
                }),
                Text(
                  'Font Weight:',
                  style: TextStyle(color: _customColor),
                ),
                StatefulBuilder(
                  builder: (context, setState) => DropdownButton<FontWeight>(
                    dropdownColor: Colors.transparent.withOpacity(0.5),
                    value: _selectedFontWeight,
                    items: [
                      createDropdownMenuItem(FontWeight.bold, 'Bold'),
                      createDropdownMenuItem(
                        FontWeight.normal,
                        'Normal',
                      ),
                      createDropdownMenuItem(
                          FontWeight.w100, // minimum font weight
                          'Thin'),
                    ],
                    onChanged: (FontWeight? value) {
                      if (value != null) {
                        setState(() {
                          _selectedFontWeight = value;
                        });
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  DropdownMenuItem<T> createDropdownMenuItem<T>(T value, String label) {
    return DropdownMenuItem(
      value: value,
      child: Text(
        label,
        style: TextStyle(color: _customColor),
      ),
    );
  }

  Widget _buildToggleSwitch(String label, bool value, Function() onTap) {
    return StatefulBuilder(builder: (context, setState) {
      return ListTile(
        title: Text(
          label,
          style: TextStyle(color: _customColor),
        ),
        trailing: Switch(
          value: value,
          onChanged: (bool newValue) {
            onTap();
            setState(() {
              value = newValue;
            });
          },
          activeColor: _customColor,
        ),
      );
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat(_twelveHour ? 'h:mm:ss' : 'HH:mm:ss').format(dateTime);
  }
}
