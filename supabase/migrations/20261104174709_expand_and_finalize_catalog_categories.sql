
with additions(parent_slug, name_ar, name_en, slug, seq) as (
  values
  ('home-furniture','كنب وأرائك','Sofas & Couches','home-furniture-sofas',1),
  ('home-furniture','كراسي ومقاعد','Chairs & Seating','home-furniture-chairs',2),
  ('home-furniture','ترابيزات وطاولات جانبية','Coffee & Side Tables','home-furniture-tables',3),
  ('home-furniture','وحدات تلفزيون','TV Stands & Media Units','home-furniture-tv-units',4),
  ('home-furniture','جزامات ووحدات أحذية','Shoe Cabinets & Racks','home-furniture-shoe-racks',5),
  ('home-furniture','مراتب','Mattresses','home-furniture-mattresses',6),

  ('home-decor','ساعات حائط','Wall Clocks','home-decor-clocks',1),
  ('home-decor','شموع وحوامل شموع','Candles & Holders','home-decor-candles',2),
  ('home-decor','نباتات صناعية','Artificial Plants','home-decor-artificial-plants',3),

  ('home-kitchen','أدوات المطبخ اليدوية','Kitchen Utensils','home-kitchen-utensils',1),
  ('home-kitchen','أدوات القهوة والشاي','Coffee & Tea Accessories','home-kitchen-coffee-tea',2),
  ('home-kitchen','علب وحافظات الطعام','Food Storage Containers','home-kitchen-food-storage',3),
  ('home-kitchen','أطقم السكاكين وألواح التقطيع','Knife Sets & Cutting Boards','home-kitchen-knives',4),
  ('home-kitchen','زجاجيات وأكواب','Glassware & Cups','home-kitchen-glassware',5),

  ('home-appliances','ثلاجات وفريزر','Refrigerators & Freezers','home-appliances-fridges',1),
  ('home-appliances','غسالات ومجففات','Washing Machines & Dryers','home-appliances-washers',2),
  ('home-appliances','غسالات أطباق','Dishwashers','home-appliances-dishwashers',3),
  ('home-appliances','بوتاجازات وأفران','Cookers & Ovens','home-appliances-ovens',4),
  ('home-appliances','ميكروويف','Microwaves','home-appliances-microwaves',5),
  ('home-appliances','مكانس كهربائية','Vacuum Cleaners','home-appliances-vacuums',6),

  ('home-textiles','مفارش وكسوات','Throws & Covers','home-textiles-throws',1),
  ('home-textiles','خداديات وأغطية وسائد','Cushions & Pillow Covers','home-textiles-cushions',2),
  ('home-textiles','مفروشات الحمام','Bathroom Textiles','home-textiles-bath',3),

  ('home-lighting','أباجورات أرضية','Floor Lamps','home-lighting-floor',1),
  ('home-lighting','إضاءة ذكية وشرائط LED','Smart Lights & LED Strips','home-lighting-smart',2),

  ('home-storage','جزامات ورفوف أحذية','Shoe Racks','home-storage-shoes',1),
  ('home-storage','سلال غسيل','Laundry Baskets','home-storage-laundry',2),

  ('home-cleaning','مماسح ومستلزمات المسح','Mops & Floor Cleaning','home-cleaning-mops',1),
  ('home-cleaning','أدوات تنظيف الزجاج','Window & Glass Cleaning Tools','home-cleaning-glass',2),

  ('home-bathroom','ستائر وأرضيات الحمام','Shower Curtains & Bath Mats','home-bathroom-curtains-mats',1),
  ('home-bathroom','حاملات ومناشف الحمام','Towel Rails & Holders','home-bathroom-towel-holders',2),

  ('home-garden','أدوات ومعدات الحدائق','Garden Tools & Equipment','home-garden-tools',1),
  ('home-garden','مظلات وشماسي خارجية','Outdoor Umbrellas & Shades','home-garden-umbrellas',2),

  ('kids-strollers','عربات متعددة الاستخدام','Convertible & Travel System Strollers','kids-strollers-travel-systems',1),
  ('kids-strollers','إكسسوارات الحماية والطقس للعربات','Stroller Weather & Safety Accessories','kids-strollers-weather-accessories',2),

  ('kids-car-seats','قواعد وتثبيت كراسي السيارات','Car Seat Bases & Installation','kids-car-seats-bases',1),
  ('kids-car-seats','أغطية وإكسسوارات كراسي السيارات','Car Seat Covers & Accessories','kids-car-seats-accessories',2),

  ('kids-furniture','طاولات تغيير الحفاضات','Changing Tables','kids-furniture-changing-tables',1),
  ('kids-furniture','أسوار وساحات اللعب','Playpens & Play Yards','kids-furniture-playpens',2),

  ('kids-feeding','شفاطات ومستلزمات الرضاعة','Breast Pumps & Nursing Accessories','kids-feeding-nursing',1),
  ('kids-feeding','أجهزة تعقيم وتسخين الرضّاعات','Bottle Sterilizers & Warmers','kids-feeding-sterilizers',2),
  ('kids-feeding','أكواب وأدوات الشرب','Sippy Cups & Drinkware','kids-feeding-cups',3),
  ('kids-feeding','مرايل وملحقات الطعام','Bibs & Feeding Accessories','kids-feeding-bibs',4),

  ('kids-toys','بازل وألعاب تركيب ذهني','Puzzles & Brain Games','kids-toys-puzzles',1),
  ('kids-toys','ألعاب تمثيل وأدوار','Pretend Play Toys','kids-toys-pretend-play',2),
  ('kids-toys','ألعاب موسيقية','Musical Toys','kids-toys-musical',3),
  ('kids-toys','دراجات وسكوتر وألعاب ركوب','Ride-on Toys, Bikes & Scooters','kids-toys-ride-on',4),

  ('kids-school','كتب وقصص أطفال','Children Books & Stories','kids-school-books',1),
  ('kids-school','وسائل تعليمية ومجسمات','Educational Aids & Models','kids-school-learning-aids',2),

  ('kids-bathing','نونية ومقاعد تدريب الحمام','Potty Training','kids-bathing-potty',1),
  ('kids-bathing','مستلزمات تغيير الحفاض','Diaper Changing Supplies','kids-bathing-diaper-changing',2),

  ('kids-safety','حمايات زوايا وأدراج','Corner & Drawer Safety Guards','kids-safety-corner-guards',1),
  ('kids-safety','أقفال أمان إضافية','Childproof Locks','kids-safety-childproof-locks',2),

  ('kids-carriers','أسرّة سفر ومستلزمات التنقل','Travel Cots & Travel Gear','kids-carriers-travel-cots',1),

  ('kids-bedding','ناموسيات ومفارش حماية','Mosquito Nets & Mattress Protectors','kids-bedding-protectors',1),

  ('clothes-men','شورتات','Shorts','clothes-men-shorts',1),
  ('clothes-men','سويت شيرت وهوديز','Sweatshirts & Hoodies','clothes-men-hoodies',2),
  ('clothes-men','بلوفرات وكارديجان','Sweaters & Cardigans','clothes-men-knitwear',3),
  ('clothes-men','ملابس سباحة','Swimwear','clothes-men-swimwear',4),

  ('clothes-women','شورتات','Shorts','clothes-women-shorts',1),
  ('clothes-women','سويت شيرت وهوديز','Sweatshirts & Hoodies','clothes-women-hoodies',2),
  ('clothes-women','بلوفرات وكارديجان','Sweaters & Cardigans','clothes-women-knitwear',3),
  ('clothes-women','ملابس سباحة','Swimwear','clothes-women-swimwear',4),

  ('clothes-kids','ملابس داخلية','Underwear','clothes-kids-underwear',1),
  ('clothes-kids','ملابس سباحة','Swimwear','clothes-kids-swimwear',2),
  ('clothes-kids','جوارب وملابس أساسية','Socks & Basics','clothes-kids-socks-basics',3),
  ('clothes-kids','ملابس مناسبات','Occasion Wear','clothes-kids-occasion-wear',4),

  ('shoes-men','لوفر وأحذية كاجوال','Loafers & Casual Shoes','shoes-men-loafers',1),
  ('shoes-men','أحذية جري','Running Shoes','shoes-men-running',2),

  ('shoes-women','مولز وأحذية مفتوحة','Mules & Open Shoes','shoes-women-mules',1),
  ('shoes-women','أحذية بلاتفورم','Platform Shoes','shoes-women-platform',2),

  ('shoes-kids','أحذية أطفال للبيت','Indoor Kids Shoes','shoes-kids-indoor',1),
  ('shoes-kids','أحذية أطفال للرضع','Baby Shoes','shoes-kids-baby',2)
),
prepared as (
  select p.id as parent_id, a.*, 
         coalesce((select max(c.display_order) from public.categories c where c.parent_id=p.id and c.slug not like '%-other'),0) as base_order
  from additions a
  join public.categories p on p.slug=a.parent_slug and p.is_active
),
inserted as (
  insert into public.categories(parent_id,name_ar,name_en,slug,is_active,display_order)
  select parent_id,name_ar,name_en,slug,true,
         base_order + seq
  from prepared
  on conflict (slug) do nothing
  returning parent_id
)
update public.categories o
set display_order = (
  select coalesce(max(c.display_order),0)+1
  from public.categories c
  where c.parent_id=o.parent_id and c.id<>o.id
)
where o.is_active and o.name_ar='أخرى'
  and exists (select 1 from inserted i where i.parent_id=o.parent_id);
