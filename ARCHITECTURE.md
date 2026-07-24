# 🏗️ Kenza Hub - Architecture Documentation

## نظرة عامة على المعمارية

```
┌─────────────────────────────────────┐
│         Flutter UI Layer             │
│  (Screens, Widgets, Navigation)     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Services Layer                  │
│  - Supabase Service                 │
│  - Upload Service                   │
│  - Auth Service                     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│       Data Layer (Models)            │
│  - Product, User, Order             │
│  - JSON Serialization               │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Backend (Supabase)              │
│  - PostgreSQL Database              │
│  - Storage (Cloud)                  │
│  - Real-time Subscriptions          │
│  - Authentication                   │
└─────────────────────────────────────┘
```

## 📱 Layers

### 1. UI Layer

**الملفات:**
```
lib/screens/
├── home/
├── sell/
│   ├── steps/
│   │   ├── step_images.dart
│   │   ├── step_category.dart
│   │   ├── step_details.dart
│   │   ├── step_brand.dart
│   │   └── step_price.dart
│   └── sell_wizard_screen.dart
├── search/
├── product/
├── profile/
├── orders/
└── auth/
```

**المسؤوليات:**
- عرض البيانات
- التعامل مع إدخال المستخدم
- إدارة الحالة المحلية
- التنقل

**مثال:**
```dart
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabaseService = SupabaseService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('الرئيسية')),
      body: // UI widgets
    );
  }
}
```

### 2. Services Layer

**الملفات:**
```
lib/services/
├── supabase_service.dart    # عمليات قاعدة البيانات
└── upload_service.dart       # رفع الصور
```

#### Supabase Service

**المسؤوليات:**
- CRUD operations للـ Products
- إدارة Users
- إدارة Orders
- Search و Filter

**مثال:**
```dart
class SupabaseService {
  Future<List<Product>> searchProducts({
    required String query,
    String? category,
    double? minPrice,
    double? maxPrice,
  }) async {
    // Query builder pattern
    var request = _client
        .from('products')
        .select()
        .ilike('title', '%$query%');
    
    if (category != null) {
      request = request.eq('category', category);
    }
    
    final response = await request;
    return (response as List)
        .map((json) => Product.fromJson(json))
        .toList();
  }
}
```

#### Upload Service

**المسؤوليات:**
- اختيار الصور
- معالجة الملفات
- رفع إلى Supabase Storage
- تنظيف الـ cache

**الميزات الخاصة:**
```dart
// ✅ معالجة صحيحة لـ Android URIs
// ✅ كشف نوع الملف من headers
// ✅ ذاكرة التخزين المؤقت
// ✅ معالجة الأخطاء الشاملة

Future<String> uploadImage(File imageFile) async {
  // 1. الحصول على metadata
  final fileBytes = await imageFile.readAsBytes();
  final mimeType = _getMimeType(imageFile.path);
  
  // 2. التحقق من الملف
  if (fileBytes.isEmpty) throw Exception('File is empty');
  
  // 3. تحميل الملف
  await _client.storage.from(bucketName).uploadBinary(
    remoteFileName,
    fileBytes,
    fileOptions: FileOptions(contentType: mimeType),
  );
  
  // 4. الحصول على رابط عام
  return _client.storage.from(bucketName).getPublicUrl(remoteFileName);
}
```

### 3. Models Layer

**الملفات:**
```
lib/models/
├── product.dart
├── user.dart
└── order.dart
```

**مثال Product Model:**
```dart
@JsonSerializable()
class Product {
  final String id;
  final String userId;
  final String title;
  final double price;
  final String category;
  final List<String> imageUrls;
  
  // ✨ Helper methods
  bool get isHomeCategory => category.toLowerCase() == 'home';
  String get primaryImage => imageUrls.isNotEmpty ? imageUrls[0] : '';
  
  factory Product.fromJson(Map<String, dynamic> json) => 
    _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
```

### 4. Config Layer

**الملفات:**
```
lib/config/
├── theme.dart    # الألوان والـ fonts
└── routes.dart   # Navigation
```

**مثال Theme:**
```dart
class AppTheme {
  static const Color primaryColor = Color(0xFF6366F1);
  
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(primary: primaryColor),
    textTheme: _buildTextTheme(),
  );
}
```

## 🔄 Data Flow

### مثال: Publish Product Flow

```
User fills form
        ↓
Sell Wizard collects data
        ↓
[Step 1-6: Collect Images, Category, Details, Brand, Price]
        ↓
Review Step shows all data
        ↓
User taps "Publish"
        ↓
UploadService.uploadImages()
        ↓
SupabaseService.addProduct()
        ↓
SupabaseService.addProductImages()
        ↓
Success! Navigate to Home
```

**الكود:**
```dart
Future<void> _publishProduct() async {
  try {
    // 1️⃣ Upload images
    final imageUrls = await _uploadService.uploadImages(_selectedImages);
    
    // 2️⃣ Create product model
    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser.id,
      title: _title,
      description: _description,
      price: _price,
      category: _category!,
      imageUrls: imageUrls,
      // ... other fields
    );
    
    // 3️⃣ Save to database
    final productId = await _supabaseService.addProduct(product);
    await _supabaseService.addProductImages(productId, imageUrls);
    
    // 4️⃣ Navigate away
    context.pushReplacement('/');
  } catch (e) {
    _showError('Failed: $e');
  }
}
```

## 🗄️ Database Schema

### Relations Diagram

```
┌─────────────────────────────────┐
│          users                  │
│ (auth.uid, email, display_name) │
└──────────┬──────────────────────┘
           │ (one-to-many)
           ├─────────────────────→ products
           ├─────────────────────→ orders (buyer)
           ├─────────────────────→ orders (seller)
           └─────────────────────→ favorites

┌─────────────────────────────────┐
│       products                  │
│ (id, user_id, title, price)     │
└──────────┬──────────────────────┘
           │ (one-to-many)
           └─────────────────────→ product_images

┌─────────────────────────────────┐
│       orders                    │
│ (id, product_id, buyer, seller) │
└──────────┬──────────────────────┘
           │ (one-to-many)
           └─────────────────────→ order_timeline
```

## 🧩 Design Patterns

### 1. Singleton Pattern (Services)

```dart
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  factory SupabaseService() => _instance;
  SupabaseService._internal();
}
```

### 2. Builder Pattern (Routes)

```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => HomeScreen()),
    GoRoute(path: '/sell', builder: (_, __) => SellWizardScreen()),
  ],
);
```

### 3. Factory Pattern (Models)

```dart
Product.fromJson(Map<String, dynamic> json) => Product(
  id: json['id'],
  title: json['title'],
  // ...
);
```

### 4. Observer Pattern (State Management)

```dart
// Using Provider/Riverpod for state
final productProvider = FutureProvider((ref) async {
  return supabaseService.getTrendingProducts();
});
```

## 🔐 Security

### Authentication Flow

```
User Login
    ↓
Supabase Auth
    ↓
JWT Token
    ↓
All API requests
    ↓
Row Level Security (RLS)
```

### RLS Policies

```sql
-- Only authenticated users can see products
CREATE POLICY "Products are viewable by everyone" ON products
  FOR SELECT USING (is_active = true);

-- Users can only update their own products  
CREATE POLICY "Users can update their products" ON products
  FOR UPDATE USING (auth.uid() = user_id);
```

## 🎯 Best Practices

### ✅ Do's

```dart
// ✅ استخدم async/await
Future<void> fetchData() async {
  try {
    final data = await service.getData();
    setState(() => _data = data);
  } catch (e) {
    _showError(e.toString());
  }
}

// ✅ تحقق من الـ null
if (user?.id != null) {
  // proceed
}

// ✅ استخدم const constructors
const Text('Hello')

// ✅ أغلق resources
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

### ❌ Don'ts

```dart
// ❌ لا تستخدم bare except
try {
  // ...
} catch (e) { // نوع e غير معروف
}

// ❌ لا تعدل state خارج setState
_data = newData; // ❌

// ❌ لا تستخدم Future.delayed بدلاً من التحديث الفعلي
Future.delayed(Duration(seconds: 1), () => refresh());

// ❌ لا تنسَ dispose
StreamSubscription sub = stream.listen((_) {});
// لا تغلق sub
```

## 📈 Performance

### Image Optimization

```dart
// ✅ استخدم compressed sizes
ImagePicker(
  imageQuality: 80,  // 0-100
  maxHeight: 1920,
  maxWidth: 1080,
)

// ✅ استخدم cached_network_image
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => LoadingWidget(),
  cacheManager: customCacheManager,
)
```

### Database Queries

```dart
// ❌ لا تسحب كل البيانات
products = await service.getAllProducts();

// ✅ استخدم pagination
products = await service.getProducts(limit: 20, offset: 0);

// ✅ استخدم indexes
CREATE INDEX idx_products_created_at ON products(created_at);
```

---

**Last Updated:** July 2026
