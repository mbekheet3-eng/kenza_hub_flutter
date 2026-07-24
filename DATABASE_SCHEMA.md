# Kenza Hub - Database Schema

## نظرة عامة

تطبيق كينزا هب يستخدم **Supabase** (PostgreSQL) كـ backend مع التكامل الكامل.

## 📊 الجداول الرئيسية

### 1. Users (المستخدمون)

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email VARCHAR(255) UNIQUE NOT NULL,
  display_name VARCHAR(255),
  phone VARCHAR(20),
  avatar_url TEXT,
  bio TEXT,
  location VARCHAR(255),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  rating DECIMAL(3, 2) DEFAULT 0,
  total_reviews INT DEFAULT 0,
  products_count INT DEFAULT 0,
  followers_count INT DEFAULT 0,
  is_verified BOOLEAN DEFAULT false,
  is_phone_verified BOOLEAN DEFAULT false,
  preferred_language VARCHAR(5) DEFAULT 'ar',
  notifications_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_seen_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_display_name ON users(display_name);
```

### 2. Products (المنتجات)

```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  category VARCHAR(50) NOT NULL, -- clothes, shoes, kids, home
  subcategory VARCHAR(100),
  condition VARCHAR(50) NOT NULL, -- Like New, Good, Fair, For Repair
  color VARCHAR(50),
  size VARCHAR(50),
  brand VARCHAR(100),
  views INT DEFAULT 0,
  likes INT DEFAULT 0,
  rating DECIMAL(3, 2),
  is_active BOOLEAN DEFAULT true,
  is_sold BOOLEAN DEFAULT false,
  location VARCHAR(255),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_products_user_id ON products(user_id);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_created_at ON products(created_at);
CREATE INDEX idx_products_title_search ON products USING GIN(to_tsvector('arabic', title));
```

### 3. Product Images (صور المنتجات)

```sql
CREATE TABLE product_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  local_path TEXT,
  order_index INT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_product_images_product_id ON product_images(product_id);
```

### 4. Orders (الطلبات)

```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  buyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount DECIMAL(10, 2) NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  -- pending, accepted, shipped, delivered, completed, cancelled, disputed
  tracking_number VARCHAR(100),
  shipping_address TEXT,
  rating DECIMAL(3, 2),
  review TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  shipped_at TIMESTAMP WITH TIME ZONE,
  delivered_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_orders_buyer_id ON orders(buyer_id);
CREATE INDEX idx_orders_seller_id ON orders(seller_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
```

### 5. Favorites (المفضلة)

```sql
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id, product_id)
);

CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_product_id ON favorites(product_id);
```

### 6. Order Timeline (سجل الطلب)

```sql
CREATE TABLE order_timeline (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  status VARCHAR(50) NOT NULL,
  message TEXT NOT NULL,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_order_timeline_order_id ON order_timeline(order_id);
```

### 7. Reviews (التقييمات)

```sql
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  reviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reviewee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating DECIMAL(3, 2) NOT NULL,
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CHECK (rating >= 1 AND rating <= 5)
);

CREATE INDEX idx_reviews_reviewee_id ON reviews(reviewee_id);
```

### 8. Messages (الرسائل)

```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
```

## 📦 Supabase Storage Buckets

### `product-images` Bucket

```
bucket_name: product-images
public: true
file_size_limit: 52428800 (50MB)
allowed_mime_types:
  - image/jpeg
  - image/png
  - image/gif
  - image/webp
```

Structure:
```
/product-images/
  ├── {uuid}_{timestamp}.jpg
  ├── {uuid}_{timestamp}.png
  └── ...
```

### `avatars` Bucket (للصور الشخصية)

```
bucket_name: avatars
public: true
file_size_limit: 5242880 (5MB)
```

## 🔐 Row Level Security (RLS)

### Products RLS

```sql
-- Users can view all active products
CREATE POLICY "Products are viewable by everyone" ON products
  FOR SELECT USING (true);

-- Users can insert their own products
CREATE POLICY "Users can create products" ON products
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own products
CREATE POLICY "Users can update their own products" ON products
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own products
CREATE POLICY "Users can delete their own products" ON products
  FOR DELETE USING (auth.uid() = user_id);
```

### Orders RLS

```sql
-- Users can view their own orders
CREATE POLICY "Users can view their orders" ON orders
  FOR SELECT USING (
    auth.uid() = buyer_id OR auth.uid() = seller_id
  );

-- Users can create orders as buyer
CREATE POLICY "Users can create orders" ON orders
  FOR INSERT WITH CHECK (auth.uid() = buyer_id);
```

### Messages RLS

```sql
CREATE POLICY "Users can view their messages" ON messages
  FOR SELECT USING (
    auth.uid() = sender_id OR auth.uid() = receiver_id
  );

CREATE POLICY "Users can send messages" ON messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);
```

## 📝 Functions & Triggers

### Function: increment_product_views

```sql
CREATE OR REPLACE FUNCTION increment_product_views(product_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE products
  SET views = views + 1
  WHERE id = product_id;
END;
$$ LANGUAGE plpgsql;
```

### Trigger: Update product updated_at

```sql
CREATE TRIGGER update_products_timestamp
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();
```

## 🔄 Relationships Diagram

```
Users (1) ──→ (N) Products
        ↓
        ├─→ (N) Orders (buyer)
        ├─→ (N) Orders (seller)
        ├─→ (N) Favorites
        ├─→ (N) Messages (sender)
        ├─→ (N) Messages (receiver)
        └─→ (N) Reviews

Products (1) ──→ (N) Product_Images
         ↓
         ├─→ (N) Orders
         └─→ (N) Favorites

Orders (1) ──→ (N) Order_Timeline
       ├─→ (1) Review
       └─→ (N) Messages
```

## 🛠️ Migrations

جميع الجداول يمكن إنشاؤها عبر Supabase Dashboard أو باستخدام الـ SQL scripts أعلاه.

## 📊 القوائم المرجعية

### Status Values (Orders)

- `pending` - قيد الانتظار
- `accepted` - مقبول
- `shipped` - تم الشحن
- `delivered` - تم التسليم
- `completed` - مكتمل
- `cancelled` - ملغى
- `disputed` - قيد النزاع

### Category Values (Products)

- `clothes` - ملابس
- `shoes` - أحذية
- `kids` - ملابس أطفال
- `home` - منزل وأثاث

### Condition Values

- `Like New` - مستخدم نادراً
- `Good` - مستخدم بحالة جيدة
- `Fair` - مستخدم
- `For Repair` - للإصلاح

---

**Last Updated:** July 2026
