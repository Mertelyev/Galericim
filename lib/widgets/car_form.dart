import 'package:flutter/material.dart';
import '../car.dart';
import 'package:intl/intl.dart';

class CarForm extends StatefulWidget {
  final Car? car;
  final bool isCustomerForm;
  final Function(Map<String, String>) onSave;
  final GlobalKey<FormState> formKey;

  const CarForm({
    super.key,
    this.car,
    this.isCustomerForm = false,
    required this.onSave,
    required this.formKey,
  });

  @override
  State<CarForm> createState() => _CarFormState();
}

class _CarFormState extends State<CarForm> {
  final Map<String, String> _formData = {};
  final Map<String, TextEditingController> controllers = {};
  DateTime selectedDate = DateTime.now(); // Varsayılan olarak günün tarihi

  @override
  void initState() {
    super.initState();
    // Var olan araç düzenleniyorsa o tarihi, yoksa günün tarihini kullan
    if (widget.car != null) {
      selectedDate = widget.car!.addedDate;
    }
    // ...existing controller initialization code...
  }

  // Tarih seçici dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      // Seçilen tarihi form verilerine ekle
      widget.onSave.call({'addedDate': selectedDate.toIso8601String()});
    }
  }

  Widget _buildDateField({
    required String label,
    required String fieldKey,
    required IconData icon,
    DateTime? initialValue,
    bool allowFutureDate = false,
    String? Function(String?)? validator,
  }) {
    final dateStr = initialValue != null
        ? DateFormat('dd.MM.yyyy').format(initialValue)
        : null;

    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        hintText: 'GG.AA.YYYY',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      initialValue: dateStr,
      keyboardType: TextInputType.datetime,
      validator: (value) {
        if (validator != null) {
          final validatorResult = validator(value);
          if (validatorResult != null) return validatorResult;
        }

        if (value != null && value.isNotEmpty) {
          try {
            final parts = value.split('.');
            if (parts.length != 3) return 'GG.AA.YYYY formatında giriniz';

            final day = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            final year = int.tryParse(parts[2]);

            if (day == null || month == null || year == null) {
              return 'Geçerli bir tarih giriniz';
            }

            final date = DateTime(year, month, day);

            if (date.isAfter(DateTime.now()) && !allowFutureDate) {
              return 'Gelecek tarih girilemez';
            }

            if (year < 2000 || year > DateTime.now().year) {
              return '2000-${DateTime.now().year} arası bir yıl giriniz';
            }
          } catch (e) {
            return 'Geçerli bir tarih giriniz';
          }
        }
        return null;
      },
      onSaved: (value) {
        if (value != null && value.isNotEmpty) {
          try {
            final parts = value.split('.');
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            final date = DateTime(year, month, day);
            _formData[fieldKey] = date.toIso8601String();
          } catch (e) {
            debugPrint('Tarih dönüştürme hatası: $e');
          }
        }
        widget.onSave(_formData);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isCustomerForm) ...[
              _buildTextField(
                label: 'Marka',
                fieldKey: 'brand',
                icon: Icons.branding_watermark,
                initialValue: widget.car?.brand,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Marka gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Model',
                fieldKey: 'model',
                icon: Icons.model_training,
                initialValue: widget.car?.model,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Model gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Paket (Opsiyonel)',
                fieldKey: 'package',
                icon: Icons.style,
                initialValue: widget.car?.package,
                hintText: 'Örn: Premium, Elegance, Urban...',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Yıl',
                fieldKey: 'year',
                icon: Icons.calendar_today,
                initialValue: widget.car?.year,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Yıl gereklidir';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Geçerli bir yıl giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Kilometre',
                fieldKey: 'kilometers',
                icon: Icons.speed,
                initialValue: widget.car?.kilometers,
                keyboardType: TextInputType.number,
                hintText: 'Örn: 125000',
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (int.tryParse(value) == null) {
                      return 'Geçerli bir kilometre giriniz';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Fiyat (TL)',
                fieldKey: 'price',
                icon: Icons.attach_money,
                initialValue: widget.car?.price,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Fiyat gereklidir';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçerli bir fiyat giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Hasar Kaydı (TL)',
                fieldKey: 'damageRecord',
                icon: Icons.warning_amber,
                initialValue: widget.car?.damageRecord ?? '0',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Hasar kaydı gereklidir';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçerli bir değer giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Yakıt Tipi',
                fieldKey: 'fuelType',
                icon: Icons.local_gas_station,
                initialValue: widget.car?.fuelType,
                items: const [
                  'Benzin',
                  'Dizel',
                  'LPG',
                  'Benzin & LPG',
                  'Elektrik',
                  'Hibrit',
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Açıklama',
                fieldKey: 'description',
                icon: Icons.description,
                initialValue: widget.car?.description,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Eklenme Tarihi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd.MM.yyyy').format(selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              if (widget.car?.isSold ?? false) ...[
                const SizedBox(height: 16),
                _buildDateField(
                  label: 'Satış Tarihi',
                  fieldKey: 'soldDate',
                  icon: Icons.sell,
                  initialValue: widget.car?.soldDate,
                ),
              ],
            ] else ...[
              _buildTextField(
                label: 'Müşteri Adı',
                fieldKey: 'customerName',
                icon: Icons.person,
              ),
              const SizedBox(height: 8),
              _buildTextField(
                label: 'Şehir',
                fieldKey: 'customerCity',
                icon: Icons.location_city,
              ),
              const SizedBox(height: 8),
              _buildTextField(
                label: 'Telefon',
                fieldKey: 'customerPhone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              _buildTextField(
                label: 'TC Kimlik No',
                fieldKey: 'customerTcNo',
                icon: Icons.badge,
                keyboardType: TextInputType.number,
                maxLength: 11,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String fieldKey,
    required IconData icon,
    String? initialValue,
    String? hintText,
    int? maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      initialValue: initialValue,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      onSaved: (value) {
        _formData[fieldKey] = value?.trim() ?? '';
        widget.onSave(_formData);
      },
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String fieldKey,
    required IconData icon,
    String? initialValue,
    required List<String> items,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
      value: initialValue,
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Seçiniz'),
        ),
        ...items.map((item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            )),
      ],
      onChanged: (value) {
        _formData[fieldKey] = value ?? '';
        widget.onSave(_formData);
      },
      onSaved: (value) {
        _formData[fieldKey] = value ?? '';
        widget.onSave(_formData);
      },
    );
  }
}
