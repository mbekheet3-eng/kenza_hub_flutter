-- Expand the existing self-referencing category tree without changing existing root IDs or labels.
-- Display translations are resolved in Flutter by stable category slug.
create index if not exists categories_parent_sort_order_idx
  on public.categories(parent_id, sort_order) where is_active;

create temporary table category_french_labels (
  slug text primary key,
  name_fr text not null check (btrim(name_fr) <> '')
) on commit drop;

insert into category_french_labels (slug, name_fr)
values
('clothes', 'Vêtements'),
    ('shoes', 'Chaussures'),
    ('children-supplies', 'Articles pour enfants'),
    ('home-supplies', 'Articles pour la maison'),
    ('kids-strollers', 'Poussettes'),
    ('kids-car-seats', 'Sièges auto pour enfants'),
    ('kids-furniture', 'Mobilier pour enfants'),
    ('kids-feeding', 'Alimentation et allaitement'),
    ('kids-toys', 'Jouets'),
    ('kids-school', 'Fournitures scolaires'),
    ('kids-bathing', 'Bain et soins'),
    ('kids-safety', 'Sécurité et protection'),
    ('kids-carriers', 'Portage et voyage'),
    ('kids-bedding', 'Literie pour enfants'),
    ('home-furniture', 'Mobilier'),
    ('home-decor', 'Décoration et accessoires'),
    ('home-kitchen', 'Ustensiles de cuisine'),
    ('home-appliances', 'Appareils électroménagers'),
    ('home-textiles', 'Linge de maison'),
    ('home-lighting', 'Éclairage'),
    ('home-storage', 'Rangement et organisation'),
    ('home-cleaning', 'Produits de nettoyage'),
    ('home-bathroom', 'Articles de salle de bain'),
    ('home-garden', 'Jardin et balcon'),
    ('clothes-men', 'Hommes'),
    ('clothes-women', 'Femmes'),
    ('clothes-kids', 'Enfants'),
    ('shoes-men', 'Hommes'),
    ('shoes-women', 'Femmes'),
    ('shoes-kids', 'Enfants'),
    ('clothes-men-shirts', 'Chemises'),
    ('clothes-men-tshirts', 'T-shirts'),
    ('clothes-men-trousers', 'Pantalons'),
    ('clothes-men-jeans', 'Jeans'),
    ('clothes-men-jackets', 'Vestes et manteaux'),
    ('clothes-men-suits', 'Costumes et tenues habillées'),
    ('clothes-men-sportswear', 'Vêtements de sport'),
    ('clothes-men-sleepwear', 'Vêtements de nuit'),
    ('clothes-men-underwear', 'Sous-vêtements'),
    ('clothes-women-dresses', 'Robes'),
    ('clothes-women-evening-dresses', 'Robes de soirée'),
    ('clothes-women-blouses', 'Chemisiers'),
    ('clothes-women-tops', 'Hauts et t-shirts'),
    ('clothes-women-trousers', 'Pantalons'),
    ('clothes-women-jeans', 'Jeans'),
    ('clothes-women-skirts', 'Jupes'),
    ('clothes-women-abayas', 'Abayas'),
    ('clothes-women-outerwear', 'Vestes et manteaux'),
    ('clothes-women-sportswear', 'Vêtements de sport'),
    ('clothes-women-sleepwear', 'Vêtements de nuit'),
    ('clothes-women-underwear', 'Sous-vêtements'),
    ('clothes-kids-sets', 'Ensembles'),
    ('clothes-kids-tops', 'Hauts'),
    ('clothes-kids-bottoms', 'Bas et shorts'),
    ('clothes-kids-dresses', 'Robes'),
    ('clothes-kids-outerwear', 'Vestes et manteaux'),
    ('clothes-kids-sleepwear', 'Vêtements de nuit'),
    ('shoes-men-sneakers', 'Baskets'),
    ('shoes-men-formal', 'Chaussures habillées'),
    ('shoes-men-sandals', 'Sandales'),
    ('shoes-men-boots', 'Bottes'),
    ('shoes-men-slippers', 'Pantoufles'),
    ('shoes-men-sports', 'Chaussures de sport'),
    ('shoes-women-sneakers', 'Baskets'),
    ('shoes-women-heels', 'Talons hauts'),
    ('shoes-women-flats', 'Chaussures plates et ballerines'),
    ('shoes-women-sandals', 'Sandales'),
    ('shoes-women-boots', 'Bottes'),
    ('shoes-women-slippers', 'Pantoufles'),
    ('shoes-kids-sneakers', 'Baskets pour enfants'),
    ('shoes-kids-school', 'Chaussures d''école'),
    ('shoes-kids-sandals', 'Sandales pour enfants'),
    ('shoes-kids-boots', 'Bottes pour enfants'),
    ('home-furniture-sofas', 'Canapés et sofas'),
    ('home-furniture-chairs', 'Chaises et sièges'),
    ('home-furniture-tables', 'Tables basses et d''appoint'),
    ('home-furniture-tv-units', 'Meubles TV'),
    ('home-furniture-shoe-racks', 'Meubles et étagères à chaussures'),
    ('home-furniture-mattresses', 'Matelas'),
    ('home-decor-clocks', 'Horloges murales'),
    ('home-decor-candles', 'Bougies et bougeoirs'),
    ('home-decor-artificial-plants', 'Plantes artificielles'),
    ('home-kitchen-utensils', 'Ustensiles de cuisine'),
    ('home-kitchen-coffee-tea', 'Accessoires café et thé'),
    ('home-kitchen-food-storage', 'Boîtes de conservation alimentaire'),
    ('home-kitchen-knives', 'Ensembles de couteaux et planches à découper'),
    ('home-kitchen-glassware', 'Verres et tasses'),
    ('home-appliances-fridges', 'Réfrigérateurs et congélateurs'),
    ('home-appliances-washers', 'Lave-linge et sèche-linge'),
    ('home-appliances-dishwashers', 'Lave-vaisselle'),
    ('home-appliances-ovens', 'Cuisinières et fours'),
    ('home-appliances-microwaves', 'Micro-ondes'),
    ('home-appliances-vacuums', 'Aspirateurs'),
    ('home-textiles-throws', 'Plaids et couvre-lits'),
    ('home-textiles-cushions', 'Coussins et housses de coussin'),
    ('home-textiles-bath', 'Linge de bain'),
    ('home-lighting-floor', 'Lampadaires'),
    ('home-lighting-smart', 'Éclairage intelligent et bandes LED'),
    ('home-storage-shoes', 'Étagères à chaussures'),
    ('home-storage-laundry', 'Paniers à linge'),
    ('home-cleaning-mops', 'Balais et nettoyage des sols'),
    ('home-cleaning-glass', 'Outils de nettoyage des vitres'),
    ('home-bathroom-curtains-mats', 'Rideaux de douche et tapis de bain'),
    ('home-bathroom-towel-holders', 'Porte-serviettes et supports'),
    ('home-garden-tools', 'Outils et équipements de jardin'),
    ('home-garden-umbrellas', 'Parasols et stores d''extérieur'),
    ('kids-strollers-travel-systems', 'Poussettes convertibles et combinées'),
    ('kids-strollers-weather-accessories', 'Accessoires de sécurité et météo pour poussettes'),
    ('kids-car-seats-bases', 'Bases et fixation de sièges auto'),
    ('kids-car-seats-accessories', 'Housses et accessoires de sièges auto'),
    ('kids-furniture-changing-tables', 'Tables à langer'),
    ('kids-furniture-playpens', 'Parcs et aires de jeu'),
    ('kids-feeding-nursing', 'Tire-lait et accessoires d''allaitement'),
    ('kids-feeding-sterilizers', 'Stérilisateurs et chauffe-biberons'),
    ('kids-feeding-cups', 'Gobelets et accessoires de boisson'),
    ('kids-feeding-bibs', 'Bavoirs et accessoires d''alimentation'),
    ('kids-toys-puzzles', 'Puzzles et jeux de réflexion'),
    ('kids-toys-pretend-play', 'Jouets d''imitation'),
    ('kids-toys-musical', 'Jouets musicaux'),
    ('kids-toys-ride-on', 'Jouets à enfourcher, vélos et trottinettes'),
    ('kids-school-books', 'Livres et histoires pour enfants'),
    ('kids-school-learning-aids', 'Supports pédagogiques et maquettes'),
    ('kids-bathing-potty', 'Apprentissage de la propreté'),
    ('kids-bathing-diaper-changing', 'Articles pour le change'),
    ('kids-safety-corner-guards', 'Protections d''angles et de tiroirs'),
    ('kids-safety-childproof-locks', 'Verrous de sécurité enfant'),
    ('kids-carriers-travel-cots', 'Lits parapluie et accessoires de voyage'),
    ('kids-bedding-protectors', 'Moustiquaires et protège-matelas'),
    ('clothes-men-shorts', 'Shorts'),
    ('clothes-men-hoodies', 'Sweats et sweats à capuche'),
    ('clothes-men-knitwear', 'Pulls et cardigans'),
    ('clothes-men-swimwear', 'Maillots de bain'),
    ('clothes-women-shorts', 'Shorts'),
    ('clothes-women-hoodies', 'Sweats et sweats à capuche'),
    ('clothes-women-knitwear', 'Pulls et cardigans'),
    ('clothes-women-swimwear', 'Maillots de bain'),
    ('clothes-kids-underwear', 'Sous-vêtements'),
    ('clothes-kids-swimwear', 'Maillots de bain'),
    ('clothes-kids-socks-basics', 'Chaussettes et essentiels'),
    ('clothes-kids-occasion-wear', 'Tenues de cérémonie'),
    ('shoes-men-loafers', 'Mocassins et chaussures décontractées'),
    ('shoes-men-running', 'Chaussures de running'),
    ('shoes-women-mules', 'Mules et chaussures ouvertes'),
    ('shoes-women-platform', 'Chaussures à plateforme'),
    ('shoes-kids-indoor', 'Chaussures d''intérieur pour enfants'),
    ('shoes-kids-baby', 'Chaussures pour bébés'),
    ('children-supplies-other', 'Autres'),
    ('home-supplies-other', 'Autres'),
    ('clothes-other', 'Autres'),
    ('shoes-other', 'Autres'),
    ('clothes-men-other', 'Autres'),
    ('clothes-women-other', 'Autres'),
    ('clothes-kids-other', 'Autres'),
    ('shoes-men-other', 'Autres'),
    ('shoes-women-other', 'Autres'),
    ('shoes-kids-other', 'Autres'),
    ('home-furniture-other', 'Autres'),
    ('home-decor-other', 'Autres'),
    ('home-kitchen-other', 'Autres'),
    ('home-appliances-other', 'Autres'),
    ('home-textiles-other', 'Autres'),
    ('home-lighting-other', 'Autres'),
    ('home-storage-other', 'Autres'),
    ('home-cleaning-other', 'Autres'),
    ('home-bathroom-other', 'Autres'),
    ('home-garden-other', 'Autres'),
    ('kids-strollers-other', 'Autres'),
    ('kids-car-seats-other', 'Autres'),
    ('kids-furniture-other', 'Autres'),
    ('kids-feeding-other', 'Autres'),
    ('kids-toys-other', 'Autres'),
    ('kids-school-other', 'Autres'),
    ('kids-bathing-other', 'Autres'),
    ('kids-safety-other', 'Autres'),
    ('kids-carriers-other', 'Autres'),
    ('kids-bedding-other', 'Autres'),
    ('clothes-other-uniforms', 'Uniformes'),
    ('clothes-other-workwear', 'Vêtements de travail'),
    ('clothes-other-costumes', 'Déguisements'),
    ('clothes-other-special-occasion', 'Tenues pour occasions spéciales');

with additions(slug,parent_slug,name_ar,name_en,sort_order) as (
  values
('kids-strollers','children-supplies','عربات أطفال','Strollers',1),
('kids-car-seats','children-supplies','كراسي سيارات للأطفال','Child Car Seats',2),
('kids-furniture','children-supplies','أثاث الأطفال وغرفهم','Kids Furniture',3),
('kids-feeding','children-supplies','الرضاعة والأكل','Feeding & Nursing',4),
('kids-toys','children-supplies','ألعاب الأطفال','Toys',5),
('kids-school','children-supplies','مستلزمات المدرسة','School Supplies',6),
('kids-bathing','children-supplies','الاستحمام والعناية','Bath & Care',7),
('kids-safety','children-supplies','السلامة والحماية','Safety & Protection',8),
('kids-carriers','children-supplies','حمالات ومستلزمات التنقل','Carriers & Travel',9),
('kids-bedding','children-supplies','مفروشات الأطفال','Kids Bedding',10),
('home-furniture','home-supplies','الأثاث','Furniture',1),
('home-decor','home-supplies','الديكور والتحف','Decor & Accessories',2),
('home-kitchen','home-supplies','أدوات ومستلزمات المطبخ','Kitchenware',3),
('home-appliances','home-supplies','الأجهزة المنزلية','Home Appliances',4),
('home-textiles','home-supplies','المفروشات والمنسوجات','Home Textiles',5),
('home-lighting','home-supplies','الإضاءة','Lighting',6),
('home-storage','home-supplies','التخزين والتنظيم','Storage & Organization',7),
('home-cleaning','home-supplies','أدوات النظافة','Cleaning Supplies',8),
('home-bathroom','home-supplies','مستلزمات الحمام','Bathroom Supplies',9),
('home-garden','home-supplies','الحدائق والبلكونات','Garden & Balcony',10),
('clothes-men','clothes','رجالي','Men',1),
('clothes-women','clothes','حريمي','Women',2),
('clothes-kids','clothes','أطفال','Kids',3),
('shoes-men','shoes','رجالي','Men',1),
('shoes-women','shoes','حريمي','Women',2),
('shoes-kids','shoes','أطفال','Kids',3)
)
insert into public.categories(parent_id,name_ar,name_en,name_fr,slug,sort_order,is_active)
select p.id,a.name_ar,a.name_en,f.name_fr,a.slug,a.sort_order,true
from additions a
join public.categories p on p.slug=a.parent_slug
join category_french_labels f on f.slug=a.slug
on conflict (slug) do nothing;

with additions(slug,parent_slug,name_ar,name_en,sort_order) as (
  values
('kids-strollers','children-supplies','عربات أطفال','Strollers',1),
('kids-car-seats','children-supplies','كراسي سيارات للأطفال','Child Car Seats',2),
('kids-furniture','children-supplies','أثاث الأطفال وغرفهم','Kids Furniture',3),
('kids-feeding','children-supplies','الرضاعة والأكل','Feeding & Nursing',4),
('kids-toys','children-supplies','ألعاب الأطفال','Toys',5),
('kids-school','children-supplies','مستلزمات المدرسة','School Supplies',6),
('kids-bathing','children-supplies','الاستحمام والعناية','Bath & Care',7),
('kids-safety','children-supplies','السلامة والحماية','Safety & Protection',8),
('kids-carriers','children-supplies','حمالات ومستلزمات التنقل','Carriers & Travel',9),
('kids-bedding','children-supplies','مفروشات الأطفال','Kids Bedding',10),
('home-furniture','home-supplies','الأثاث','Furniture',1),
('home-decor','home-supplies','الديكور والتحف','Decor & Accessories',2),
('home-kitchen','home-supplies','أدوات ومستلزمات المطبخ','Kitchenware',3),
('home-appliances','home-supplies','الأجهزة المنزلية','Home Appliances',4),
('home-textiles','home-supplies','المفروشات والمنسوجات','Home Textiles',5),
('home-lighting','home-supplies','الإضاءة','Lighting',6),
('home-storage','home-supplies','التخزين والتنظيم','Storage & Organization',7),
('home-cleaning','home-supplies','أدوات النظافة','Cleaning Supplies',8),
('home-bathroom','home-supplies','مستلزمات الحمام','Bathroom Supplies',9),
('home-garden','home-supplies','الحدائق والبلكونات','Garden & Balcony',10),
('clothes-men-shirts','clothes-men','قمصان','Shirts',1),
('clothes-men-tshirts','clothes-men','تيشيرتات','T-Shirts',2),
('clothes-men-trousers','clothes-men','بناطيل','Trousers',3),
('clothes-men-jeans','clothes-men','جينز','Jeans',4),
('clothes-men-jackets','clothes-men','جاكيتات ومعاطف','Jackets & Coats',5),
('clothes-men-suits','clothes-men','بدل وملابس رسمية','Suits & Formalwear',6),
('clothes-men-sportswear','clothes-men','ملابس رياضية','Sportswear',7),
('clothes-men-sleepwear','clothes-men','ملابس نوم','Sleepwear',8),
('clothes-men-underwear','clothes-men','ملابس داخلية','Underwear',9),
('clothes-women-dresses','clothes-women','فساتين','Dresses',1),
('clothes-women-evening-dresses','clothes-women','فساتين سواريه','Evening Dresses',2),
('clothes-women-blouses','clothes-women','بلوزات','Blouses',3),
('clothes-women-tops','clothes-women','توب وتيشيرتات','Tops & T-Shirts',4),
('clothes-women-trousers','clothes-women','بناطيل','Trousers',5),
('clothes-women-jeans','clothes-women','جينز','Jeans',6),
('clothes-women-skirts','clothes-women','جيبات','Skirts',7),
('clothes-women-abayas','clothes-women','عبايات','Abayas',8),
('clothes-women-outerwear','clothes-women','جاكيتات ومعاطف','Jackets & Coats',9),
('clothes-women-sportswear','clothes-women','ملابس رياضية','Sportswear',10),
('clothes-women-sleepwear','clothes-women','ملابس نوم','Sleepwear',11),
('clothes-women-underwear','clothes-women','ملابس داخلية','Underwear',12),
('clothes-kids-sets','clothes-kids','أطقم ملابس','Clothing Sets',1),
('clothes-kids-tops','clothes-kids','تيشيرتات وبلوزات','Tops',2),
('clothes-kids-bottoms','clothes-kids','بناطيل وشورتات','Bottoms & Shorts',3),
('clothes-kids-dresses','clothes-kids','فساتين','Dresses',4),
('clothes-kids-outerwear','clothes-kids','جاكيتات ومعاطف','Jackets & Coats',5),
('clothes-kids-sleepwear','clothes-kids','ملابس نوم','Sleepwear',6),
('shoes-men-sneakers','shoes-men','كوتشي وسنيكرز','Sneakers',1),
('shoes-men-formal','shoes-men','أحذية كلاسيك ورسمية','Formal Shoes',2),
('shoes-men-sandals','shoes-men','صنادل','Sandals',3),
('shoes-men-boots','shoes-men','بوت','Boots',4),
('shoes-men-slippers','shoes-men','شبشب','Slippers',5),
('shoes-men-sports','shoes-men','أحذية رياضية متخصصة','Sports Shoes',6),
('shoes-women-sneakers','shoes-women','كوتشي وسنيكرز','Sneakers',1),
('shoes-women-heels','shoes-women','كعب عالي','Heels',2),
('shoes-women-flats','shoes-women','فلات وباليرينا','Flats & Ballerinas',3),
('shoes-women-sandals','shoes-women','صنادل','Sandals',4),
('shoes-women-boots','shoes-women','بوت','Boots',5),
('shoes-women-slippers','shoes-women','شبشب','Slippers',6),
('shoes-kids-sneakers','shoes-kids','كوتشي أطفال','Kids Sneakers',1),
('shoes-kids-school','shoes-kids','أحذية مدارس','School Shoes',2),
('shoes-kids-sandals','shoes-kids','صنادل أطفال','Kids Sandals',3),
('shoes-kids-boots','shoes-kids','بوت أطفال','Kids Boots',4)
)
insert into public.categories(parent_id,name_ar,name_en,name_fr,slug,sort_order,is_active)
select p.id,a.name_ar,a.name_en,f.name_fr,a.slug,a.sort_order,true
from additions a
join public.categories p on p.slug=a.parent_slug
join category_french_labels f on f.slug=a.slug
on conflict (slug) do nothing;

with additions(parent_slug,name_ar,name_en,slug,sort_order) as (
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
)
insert into public.categories(parent_id,name_ar,name_en,name_fr,slug,sort_order,is_active)
select p.id,a.name_ar,a.name_en,f.name_fr,a.slug,a.sort_order,true
from additions a
join public.categories p on p.slug=a.parent_slug
join category_french_labels f on f.slug=a.slug
on conflict (slug) do nothing;

-- Add an "Other" fallback to every category that has children.
insert into public.categories(parent_id,name_ar,name_en,name_fr,slug,sort_order,is_active)
select p.id,'أخرى','Other','Autres',p.slug || '-other',
       coalesce(max(c.sort_order),0)+1,true
from public.categories p
join public.categories c on c.parent_id=p.id and c.is_active
where p.is_active
  and not exists (select 1 from public.categories x where x.slug=p.slug || '-other')
group by p.id,p.slug
on conflict (slug) do nothing;

-- More precise choices under Clothes > Other.
insert into public.categories(parent_id,name_ar,name_en,name_fr,slug,sort_order,is_active)
select p.id,v.name_ar,v.name_en,f.name_fr,v.slug,v.sort_order,true
from public.categories p
cross join (values
  ('ملابس موحدة','Uniforms','clothes-other-uniforms',1),
  ('ملابس عمل ومهن','Workwear','clothes-other-workwear',2),
  ('ملابس تنكرية','Costumes','clothes-other-costumes',3),
  ('ملابس مناسبات خاصة','Special Occasion Wear','clothes-other-special-occasion',4)
) as v(name_ar,name_en,slug,sort_order)
join category_french_labels f on f.slug=v.slug
where p.slug='clothes-other'
on conflict (slug) do nothing;

-- Keep every "Other" option last within its parent.
update public.categories o
set sort_order = (
  select coalesce(max(c.sort_order),0)+1
  from public.categories c
  where c.parent_id=o.parent_id and c.id<>o.id
)
where o.is_active and o.slug like '%-other';

-- Apply the French label catalog to existing slugs too, including conflict-skipped inserts.
update public.categories as category
set name_fr = french_labels.name_fr
from category_french_labels as french_labels
where category.slug = french_labels.slug;

-- Every generated "Other" category uses the localized French fallback.
update public.categories
set name_fr = 'Autres'
where slug like '%-other';

-- Fail this migration rather than leave any category with a missing French label.
do $$
begin
  if exists (
    select 1 from public.categories
    where name_fr is null or btrim(name_fr) = ''
  ) then
    raise exception 'Every category must have a non-empty French translation';
  end if;
end;
$$;
