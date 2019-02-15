import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter/services.dart' show TextInputFormatter;

/// A [FormField<DateTime>] that uses a [TextField] to manage input.
class DateTimePickerFormField extends FormField<DateTime> {
  /// Whether to show the time picker after a date has been chosen.
  /// To show the time picker only, use [TimePickerFormField].
  final bool dateOnly;

  /// Allow manual editing of the date/time. Defaults to true. If false, the
  /// picker(s) will be shown every time the field gains focus.
  final bool editable;

  /// For representing the date as a string e.g.
  /// `DateFormat("EEEE, MMMM d, yyyy 'at' h:mma")`
  /// (Sunday, June 3, 2018 at 9:24pm)
  final DateFormat format;

  /// Where the calendar will start when shown. Defaults to the current date.
  final DateTime initialDate;

  /// The earliest choosable date. Defaults to 1900.
  final DateTime firstDate;

  /// The latest choosable date. Defaults to 2100.
  final DateTime lastDate;

  /// The initial time prefilled in the picker dialog when it is shown. Defaults
  /// to noon. Explicitly set this to `null` to use the current time.
  final TimeOfDay initialTime;

  /// If defined the TextField [decoration]'s [suffixIcon] will be
  /// overridden to reset the input using the icon defined here.
  /// Set this to `null` to stop that behavior. Defaults to [Icons.close].
  final IconData resetIcon;

  /// For validating the [DateTime]. The value passed will be `null` if
  /// [format] fails to parse the text.
  final FormFieldValidator<DateTime> validator;

  /// Called when an enclosing form is saved. The value passed will be `null`
  /// if [format] fails to parse the text.
  final FormFieldSetter<DateTime> onSaved;

  /// Corresponds to the [showDatePicker()] parameter. Defaults to
  /// [DatePickerMode.day].
  final DatePickerMode initialDatePickerMode;

  /// Corresponds to the [showDatePicker()] parameter.
  final Locale locale;

  /// Corresponds to the [showDatePicker()] parameter.
  final bool Function(DateTime) selectableDayPredicate;

  /// Corresponds to the [showDatePicker()] parameter.
  final TextDirection textDirection;

  /// Called when an enclosing form is submitted. The value passed will be
  /// `null` if [format] fails to parse the text.
  final ValueChanged<DateTime> onFieldSubmitted;
  final TextEditingController controller;
  final FocusNode focusNode;
  final InputDecoration decoration;

  final TextInputType keyboardType;
  final TextStyle style;
  final TextAlign textAlign;
  final DateTime initialValue;
  final bool autofocus;
  final bool obscureText;
  final bool autocorrect;
  final bool maxLengthEnforced;
  final int maxLines;
  final int maxLength;
  final List<TextInputFormatter> inputFormatters;
  final bool enabled;

  /// Called whenever the state's value changes, e.g. after picker value(s)
  /// have been selected or when the field loses focus. To listen for all text
  /// changes, use the [controller] and [focusNode].
  final ValueChanged<DateTime> onChanged;

  DateTimePickerFormField({
    Key key,
    @required this.format,
    this.dateOnly: false,
    this.editable: true,
    this.onChanged,
    this.resetIcon: Icons.close,
    DateTime initialDate,
    DateTime firstDate,
    DateTime lastDate,
    this.initialTime: const TimeOfDay(hour: 12, minute: 0),
    this.validator,
    this.onSaved,
    this.onFieldSubmitted,
    bool autovalidate: false,
    DatePickerMode initialDatePickerMode,
    this.locale,
    this.selectableDayPredicate,
    this.textDirection,

    // TextField properties
    TextEditingController controller,
    FocusNode focusNode,
    this.initialValue,
    this.decoration: const InputDecoration(),
    this.keyboardType: TextInputType.text,
    this.style,
    this.textAlign: TextAlign.start,
    this.autofocus: false,
    this.obscureText: false,
    this.autocorrect: true,
    this.maxLengthEnforced: true,
    this.enabled,
    this.maxLines: 1,
    this.maxLength,
    this.inputFormatters,
  })  : controller = controller ??
            TextEditingController(text: _toString(initialValue, format)),
        focusNode = focusNode ?? FocusNode(),
        initialDate = initialDate ?? DateTime.now(),
        firstDate = firstDate ?? DateTime(1900),
        lastDate = lastDate ?? DateTime(2100),
        initialDatePickerMode = initialDatePickerMode ?? DatePickerMode.day,
        super(
            key: key,
            autovalidate: autovalidate,
            validator: validator,
            onSaved: onSaved,
            builder: (FormFieldState<DateTime> field) {
              // final _DateTimePickerTextFormFieldState state = field;
            });

  @override
  _DateTimePickerTextFormFieldState createState() =>
      _DateTimePickerTextFormFieldState(this);
}

class _DateTimePickerTextFormFieldState extends FormFieldState<DateTime> {
  final DateTimePickerFormField parent;
  bool showResetIcon = false;
  String _previousValue = '';

  _DateTimePickerTextFormFieldState(this.parent);

  @override
  void setValue(DateTime value) {
    super.setValue(value);
    if (parent.onChanged != null) parent.onChanged(value);
  }

  @override
  void initState() {
    super.initState();
    parent.focusNode.addListener(inputChanged);
    parent.controller.addListener(inputChanged);
  }

  @override
  void dispose() {
    parent.controller.removeListener(inputChanged);
    parent.focusNode.removeListener(inputChanged);
    super.dispose();
  }

  void inputChanged() {
    final bool requiresInput = 
        parent.focusNode.hasFocus;

    if (requiresInput) {
      getDateTimeInput(context, parent.initialDate, parent.initialTime)
          .then(_setValue);
    } else if (parent.resetIcon != null &&
        parent.controller.text.isEmpty == showResetIcon) {
      setState(() => showResetIcon = !showResetIcon);
      // parent.focusNode.unfocus();
    }
    
  }

  void _setValue(DateTime date) {
    parent.focusNode.unfocus();
    // When Cancel is tapped, retain the previous value if present.
    if (date == null && _previousValue.isNotEmpty) {
      date = _toDate(_previousValue, parent.format);
    }
    setState(() {
      parent.controller.text = _toString(date, parent.format);
      setValue(date);
    });
  }

  Future<DateTime> getDateTimeInput(
      BuildContext context, DateTime initialDate, TimeOfDay initialTime) async {
    var date = await showDatePicker(
        context: context,
        firstDate: parent.firstDate,
        lastDate: parent.lastDate,
        initialDate: initialDate,
        initialDatePickerMode: parent.initialDatePickerMode,
        locale: parent.locale,
        selectableDayPredicate: parent.selectableDayPredicate,
        textDirection: parent.textDirection);
    if (date != null) {
      date = startOfDay(date);
      if (!parent.dateOnly) {
        final time = await showTimePicker(
          context: context,
          initialTime: initialTime ?? TimeOfDay.now(),
        );
        if (time != null) {
          date = date.add(Duration(hours: time.hour, minutes: time.minute));
        }
      }
    }

    return date;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: parent.controller,
      focusNode: parent.focusNode,
      decoration: parent.resetIcon == null
          ? parent.decoration
          : parent.decoration.copyWith(
              suffixIcon: showResetIcon
                  ? IconButton(
                      icon: Icon(parent.resetIcon),
                      onPressed: () {
                        parent.focusNode.unfocus();
                        _previousValue = '';
                        parent.controller.clear();
                      },
                    )
                  : Container(width: 0.0, height: 0.0),
            ),
      keyboardType: parent.keyboardType,
      style: parent.style,
      textAlign: parent.textAlign,
      autofocus: parent.autofocus,
      obscureText: parent.obscureText,
      autocorrect: parent.autocorrect,
      maxLengthEnforced: parent.maxLengthEnforced,
      maxLines: parent.maxLines,
      maxLength: parent.maxLength,
      inputFormatters: parent.inputFormatters,
      enabled: widget.enabled,
      onFieldSubmitted: (value) {
        if (parent.onFieldSubmitted != null) {
          return parent.onFieldSubmitted(_toDate(value, parent.format));
        }
      },
      validator: (value) {
        if (parent.validator != null) {
          return parent.validator(_toDate(value, parent.format));
        }
      },
      autovalidate: parent.autovalidate,
      onSaved: (value) {
        if (parent.onSaved != null) {
          return parent.onSaved(_toDate(value, parent.format));
        }
      },
    );
  }
}

String _toString(DateTime date, DateFormat formatter) {
  if (date != null) {
    try {
      return formatter.format(date);
    } catch (e) {
      debugPrint('Error formatting date: $e');
    }
  }
  return '';
}

DateTime _toDate(String string, DateFormat formatter) {
  if (string != null && string.isNotEmpty) {
    try {
      return formatter.parse(string);
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
  }
  return null;
}

/// null-safe version of [TimeOfDay.fromDateTime(time)].
TimeOfDay _toTime(DateTime date) {
  if (date == null) return null;
  return TimeOfDay.fromDateTime(date);
}

DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);
