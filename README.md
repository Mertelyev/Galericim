# 🚗 Galericim - Araç Galeri Yönetim Sistemi

**Galericim**, Flutter ile geliştirilmiş modern bir araç galeri envanter yönetimi ve iş analitiği uygulamasıdır. Material Design 3 tasarım dili, SQLite veritabanı ve kapsamlı analitik dashboard ile galeri işletmeciliğini dijitalleştirir.

> **Final Projesi** - Bu uygulama, mobil uygulama geliştirme, veritabanı yönetimi, UI/UX tasarımı ve yazılım mühendisliği prensiplerini demonstre eden bir final projesidir.

## ✨ Temel Özellikler

### 🏪 Envanter Yönetimi
- **Kapsamlı Araç Kaydı**: 20+ field ile detaylı araç bilgi sistemi
- **Gelişmiş Arama & Filtreleme**: Marka, model, yıl, fiyat bazlı filtreleme
- **CRUD İşlemleri**: Araç ekleme, düzenleme, silme ve görüntüleme
- **Sayfalama Sistemi**: Büyük envanter listeleri için optimize edilmiş UI

### 📊 İş Analitiği Dashboard
- **6 Kartlı KPI Paneli**: Toplam araç, satış, gelir, ortalama süre analizleri
- **İnteraktif Grafikler**: Aylık trend, marka dağılımı, fiyat segmentasyonu
- **Zaman Filtresi**: Bu ay, 3-6-12 ay bazlı dinamik analiz
- **Business Intelligence**: Satış performansı ve trend analizi

### 🎨 Modern UI/UX
- **Material Design 3**: Google'ın güncel tasarım standartları  
- **Dark/Light Theme**: Dinamik tema desteği
- **Responsive Design**: Tablet, telefon, desktop uyumlu
- **Animasyonlar**: Smooth geçişler ve interaktif feedback

## 📱 Uygulama Ekranları

- **Ana Sayfa**: Envanter listesi, arama, filtreleme ve sayfalama
- **Araç Formu**: 20+ field ile kapsamlı araç kayıt sistemi  
- **İstatistik Sayfası**: KPI dashboard, interaktif grafikler ve trend analizi
- **Ayarlar**: Tema seçimi ve uygulama tercihleri

## 🛠 Kurulum ve Çalıştırma

### Sistem Gereksinimleri
- Flutter SDK 3.5.4+
- Dart SDK 3.5.4+
- Android Studio / VS Code (Flutter eklentileri)

### Hızlı Başlangıç
```bash
# Projeyi klonlayın
git clone https://github.com/mertelyev/galericim.git
cd galericim

# Bağımlılıkları yükleyin
flutter pub get

# Uygulamayı çalıştırın
flutter run
```

### Platform Seçenekleri
```bash
# Android
flutter run

# Windows Desktop  
flutter run -d windows

# Web Browser
flutter run -d chrome

# APK Build
flutter build apk --release
```

## 💻 Teknik Detaylar

### Kullanılan Teknolojiler
- **Framework**: Flutter 3.5.4
- **Language**: Dart 3.5.4  
- **Database**: SQLite (sqflite)
- **Charts**: fl_chart
- **State Management**: Built-in StatefulWidget
- **Storage**: shared_preferences
- **Architecture**: Service-oriented, modular design

### Proje Yapısı
```
lib/
├── main.dart              # Ana uygulama entry point
├── car.dart               # Araç model sınıfı
├── carlist.dart           # Ana sayfa - araç listesi
├── statistic.dart         # İstatistik dashboard 
├── db_helper.dart         # SQLite veritabanı helper
├── theme.dart             # Tema yönetimi
├── services/              # Servis katmanı
│   ├── backup_service.dart
│   ├── search_service.dart
│   └── settings_service.dart
├── utils/                 # Yardımcı fonksiyonlar
│   ├── validation_utils.dart
│   └── error_handler.dart
└── widgets/               # Özel widget'lar
    ├── car_form.dart
    └── paginated_list_view.dart
```

## 🎯 Proje Hedefleri

Bu final projesi aşağıdaki yazılım geliştirme konseptlerini demonstre eder:

- **Mobile Development**: Cross-platform Flutter uygulaması
- **Database Management**: SQLite ile CRUD operasyonları
- **UI/UX Design**: Material Design 3 ve responsive tasarım
- **Data Visualization**: İnteraktif grafik ve dashboard
- **Software Architecture**: Clean code ve modüler yapı
- **Error Handling**: Kapsamlı hata yönetimi
- **State Management**: Efficient UI state handling

## 📈 Proje İstatistikleri

- **Toplam Kod Satırı**: ~3,000+ lines
- **Dosya Sayısı**: 25+ Dart files
- **Platform Desteği**: Android, iOS, Windows, Web
- **Test Coverage**: Unit testler dahil
- **Database**: 20+ field'lı car tablosu

## 📝 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. 

---

## 👨‍💻 Geliştirici Bilgileri

**Final Projesi**  
*Mert Kuruali tarafından geliştirilmiştir.*

