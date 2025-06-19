import 'package:flutter/material.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({Key? key}) : super(key: key);

  @override
  _TrendsPageState createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update arrow button states
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trendler'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _tabController.index > 0
                ? () => _tabController.animateTo(_tabController.index - 1)
                : null,
            tooltip: 'Önceki Kategori',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: _tabController.index < 6
                ? () => _tabController.animateTo(_tabController.index + 1)
                : null,
            tooltip: 'Sonraki Kategori',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Popüler Araçlar'),
            Tab(text: 'Fiyat Artışları'),
            Tab(text: 'Yakıt Trendleri'),
            Tab(text: 'Karşılaştırılan'),
            Tab(text: 'Renkler'),
            Tab(text: 'Segmentler'),
            Tab(text: 'Akıllı Özellikler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPopularCarsTab(),
          _buildPriceIncreasesTab(),
          _buildFuelTrendsTab(),
          _buildComparedModelsTab(),
          _buildPopularColorsTab(),
          _buildSegmentTrendsTab(),
          _buildSmartFeaturesTab(),
        ],
      ),
    );
  }

  Widget _buildPopularCarsTab() {
    final popularCars = [
      {
        'name': 'Toyota Corolla',
        'views': 45230,
        'growth': '+15%',
        'icon': '🚗'
      },
      {
        'name': 'Volkswagen Golf',
        'views': 38940,
        'growth': '+22%',
        'icon': '🚙'
      },
      {'name': 'Honda Civic', 'views': 32180, 'growth': '+8%', 'icon': '🚗'},
      {'name': 'Renault Clio', 'views': 28750, 'growth': '+18%', 'icon': '🚙'},
      {'name': 'Ford Focus', 'views': 25640, 'growth': '+12%', 'icon': '🚗'},
      {'name': 'Peugeot 301', 'views': 22380, 'growth': '+25%', 'icon': '🚙'},
      {'name': 'Hyundai i20', 'views': 19850, 'growth': '+14%', 'icon': '🚗'},
      {'name': 'Skoda Octavia', 'views': 18420, 'growth': '+9%', 'icon': '🚙'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'En Çok Görüntülenen Araçlar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Son 30 gün içerisinde en çok ilgi gören araç modelleri',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...popularCars.asMap().entries.map((entry) {
          final index = entry.key;
          final car = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getRankColor(index),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Row(
                children: [
                  Text(car['icon'] as String,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      car['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              subtitle: Text('${car['views']} görüntülenme'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  car['growth'] as String,
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPriceIncreasesTab() {
    final priceIncreases = [
      {
        'name': 'Mercedes C-Class',
        'oldPrice': 1250000,
        'newPrice': 1480000,
        'increase': 18.4
      },
      {
        'name': 'BMW 3 Serisi',
        'oldPrice': 1180000,
        'newPrice': 1380000,
        'increase': 16.9
      },
      {
        'name': 'Audi A4',
        'oldPrice': 1320000,
        'newPrice': 1540000,
        'increase': 16.7
      },
      {
        'name': 'Volvo XC60',
        'oldPrice': 1850000,
        'newPrice': 2150000,
        'increase': 16.2
      },
      {
        'name': 'Lexus IS',
        'oldPrice': 1650000,
        'newPrice': 1900000,
        'increase': 15.2
      },
      {
        'name': 'Tesla Model 3',
        'oldPrice': 1450000,
        'newPrice': 1650000,
        'increase': 13.8
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fiyatı En Çok Artan Araçlar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Son 6 ay içerisinde en yüksek fiyat artışı yaşayan modeller',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...priceIncreases.map((car) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          car['name'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+${car['increase']}%',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Eski Fiyat',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            '₺${_formatPrice(car['oldPrice'] as int)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.grey),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Yeni Fiyat',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            '₺${_formatPrice(car['newPrice'] as int)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFuelTrendsTab() {
    final fuelTrends = [
      {
        'type': 'Elektrikli',
        'share': 28.5,
        'growth': '+45%',
        'color': Colors.green,
        'icon': '🔋'
      },
      {
        'type': 'Hibrit',
        'share': 22.3,
        'growth': '+32%',
        'color': Colors.blue,
        'icon': '⚡'
      },
      {
        'type': 'Benzin',
        'share': 35.2,
        'growth': '-8%',
        'color': Colors.orange,
        'icon': '⛽'
      },
      {
        'type': 'Dizel',
        'share': 12.8,
        'growth': '-15%',
        'color': Colors.grey,
        'icon': '🛢️'
      },
      {
        'type': 'LPG',
        'share': 1.2,
        'growth': '-25%',
        'color': Colors.purple,
        'icon': '🚗'
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yakıt Türüne Göre Araç Trendleri',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Türkiye otomotiv pazarında yakıt türü tercihleri',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...fuelTrends.map((fuel) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(fuel['icon'] as String,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fuel['type'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            Text(
                              'Pazar payı: %${fuel['share']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (fuel['growth'] as String).startsWith('+')
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          fuel['growth'] as String,
                          style: TextStyle(
                            color: (fuel['growth'] as String).startsWith('+')
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (fuel['share'] as double) / 100,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(fuel['color'] as Color),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildComparedModelsTab() {
    final comparedModels = [
      {
        'model1': 'Toyota Corolla',
        'model2': 'Honda Civic',
        'comparisons': 12450,
        'winner': 'Toyota Corolla',
        'icon1': '🚗',
        'icon2': '🚙'
      },
      {
        'model1': 'BMW 3 Serisi',
        'model2': 'Mercedes C-Class',
        'comparisons': 8930,
        'winner': 'BMW 3 Serisi',
        'icon1': '🏎️',
        'icon2': '🚘'
      },
      {
        'model1': 'Volkswagen Golf',
        'model2': 'Ford Focus',
        'comparisons': 7680,
        'winner': 'Volkswagen Golf',
        'icon1': '🚙',
        'icon2': '🚗'
      },
      {
        'model1': 'Tesla Model 3',
        'model2': 'BMW i4',
        'comparisons': 5420,
        'winner': 'Tesla Model 3',
        'icon1': '⚡',
        'icon2': '🔋'
      },
      {
        'model1': 'Audi A4',
        'model2': 'Volvo S60',
        'comparisons': 4280,
        'winner': 'Audi A4',
        'icon1': '🚘',
        'icon2': '🚗'
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'En Çok Karşılaştırılan Modeller',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Kullanıcıların en çok karşılaştırdığı araç modelleri',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...comparedModels.map((comparison) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(comparison['icon1'] as String,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                comparison['model1'] as String,
                                style: TextStyle(
                                  fontWeight: comparison['winner'] ==
                                          comparison['model1']
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: comparison['winner'] ==
                                          comparison['model1']
                                      ? Colors.green
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(' VS ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Row(
                          children: [
                            Text(comparison['icon2'] as String,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                comparison['model2'] as String,
                                style: TextStyle(
                                  fontWeight: comparison['winner'] ==
                                          comparison['model2']
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: comparison['winner'] ==
                                          comparison['model2']
                                      ? Colors.green
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${comparison['comparisons']} karşılaştırma',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.emoji_events,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Kazanan: ${comparison['winner']}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPopularColorsTab() {
    final popularColors = [
      {
        'name': 'Beyaz',
        'percentage': 32.5,
        'color': Colors.white,
        'border': Colors.grey
      },
      {
        'name': 'Siyah',
        'percentage': 24.8,
        'color': Colors.black,
        'border': Colors.black
      },
      {
        'name': 'Gri',
        'percentage': 18.2,
        'color': Colors.grey,
        'border': Colors.grey
      },
      {
        'name': 'Gümüş',
        'percentage': 12.4,
        'color': Colors.grey[400]!,
        'border': Colors.grey[400]!
      },
      {
        'name': 'Mavi',
        'percentage': 6.8,
        'color': Colors.blue,
        'border': Colors.blue
      },
      {
        'name': 'Kırmızı',
        'percentage': 3.2,
        'color': Colors.red,
        'border': Colors.red
      },
      {
        'name': 'Yeşil',
        'percentage': 1.5,
        'color': Colors.green,
        'border': Colors.green
      },
      {
        'name': 'Diğer',
        'percentage': 0.6,
        'color': Colors.orange,
        'border': Colors.orange
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'En Çok Beğenilen Araç Renkleri',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Türkiye\'de en çok tercih edilen araç renkleri',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...popularColors.map((colorData) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorData['color'] as Color,
                      border: Border.all(
                          color: colorData['border'] as Color, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          colorData['name'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (colorData['percentage'] as double) / 100,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorData['color'] as Color),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '%${colorData['percentage']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSegmentTrendsTab() {
    final segmentTrends = [
      {
        'name': 'SUV',
        'percentage': 42.3,
        'growth': '+18%',
        'icon': '🚙',
        'color': Colors.blue
      },
      {
        'name': 'Sedan',
        'percentage': 28.5,
        'growth': '-5%',
        'icon': '🚗',
        'color': Colors.orange
      },
      {
        'name': 'Hatchback',
        'percentage': 15.8,
        'growth': '+3%',
        'icon': '🚘',
        'color': Colors.green
      },
      {
        'name': 'Coupe',
        'percentage': 6.2,
        'growth': '+12%',
        'icon': '🏎️',
        'color': Colors.red
      },
      {
        'name': 'Station Wagon',
        'percentage': 4.1,
        'growth': '-8%',
        'icon': '🚐',
        'color': Colors.purple
      },
      {
        'name': 'Pickup',
        'percentage': 2.5,
        'growth': '+25%',
        'icon': '🛻',
        'color': Colors.brown
      },
      {
        'name': 'Cabrio',
        'percentage': 0.6,
        'growth': '+5%',
        'icon': '🏁',
        'color': Colors.pink
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Türkiye\'de En Çok Tercih Edilen Segmentler',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Araç segmentlerine göre pazar dağılımı ve büyüme oranları',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...segmentTrends.map((segment) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(segment['icon'] as String,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              segment['name'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            Text(
                              'Pazar payı: %${segment['percentage']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (segment['growth'] as String).startsWith('+')
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          segment['growth'] as String,
                          style: TextStyle(
                            color: (segment['growth'] as String).startsWith('+')
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (segment['percentage'] as double) / 100,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        segment['color'] as Color),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSmartFeaturesTab() {
    final smartFeatures = [
      {
        'name': 'Otopilot / Otonom Sürüş',
        'adoption': 78.5,
        'brands': ['Tesla', 'Mercedes', 'BMW', 'Audi'],
        'icon': '🤖',
        'description': 'Seviye 2-3 otonom sürüş özellikleri'
      },
      {
        'name': 'Kablosuz Şarj',
        'adoption': 65.2,
        'brands': ['Apple CarPlay', 'Android Auto', 'Samsung'],
        'icon': '📱',
        'description': 'Kablosuz telefon şarjı ve bağlantı'
      },
      {
        'name': 'Ses Tanıma Asistanı',
        'adoption': 58.9,
        'brands': ['Alexa', 'Google', 'Siri', 'Bixby'],
        'icon': '🎤',
        'description': 'AI destekli ses komutları'
      },
      {
        'name': 'OTA Güncellemeler',
        'adoption': 52.3,
        'brands': ['Tesla', 'Polestar', 'Lucid', 'Rivian'],
        'icon': '📡',
        'description': 'Hava üzerinden yazılım güncellemeleri'
      },
      {
        'name': 'Digital Kokpit',
        'adoption': 89.7,
        'brands': ['Audi', 'Mercedes', 'BMW', 'Porsche'],
        'icon': '📺',
        'description': 'Tamamen dijital gösterge paneli'
      },
      {
        'name': 'Artırılmış Gerçeklik HUD',
        'adoption': 34.8,
        'brands': ['Mercedes', 'BMW', 'Genesis', 'Cadillac'],
        'icon': '👁️',
        'description': 'AR destekli head-up display'
      },
      {
        'name': 'Biyometrik Giriş',
        'adoption': 28.4,
        'brands': ['Genesis', 'Cadillac', 'Lincoln', 'Volvo'],
        'icon': '👆',
        'description': 'Parmak izi ve yüz tanıma'
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Akıllı Özelliklerle Gelen Yeni Modeller',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '2024-2025 model araçlarda en popüler teknoloji özellikleri',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...smartFeatures.map((feature) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(feature['icon'] as String,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature['name'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            Text(
                              feature['description'] as String,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '%${feature['adoption']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (feature['adoption'] as double) / 100,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: (feature['brands'] as List<String>).map((brand) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          brand,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Gold
      case 1:
        return Colors.grey; // Silver
      case 2:
        return Colors.brown; // Bronze
      default:
        return Colors.blue;
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
