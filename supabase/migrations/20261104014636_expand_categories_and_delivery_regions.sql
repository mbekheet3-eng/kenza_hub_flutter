
WITH new_categories(slug,parent_slug,name_ar,name_en,display_order) AS (
VALUES
('kids-strollers','kids-supplies','عربات أطفال','Strollers',1),
('kids-car-seats','kids-supplies','كراسي سيارات للأطفال','Child Car Seats',2),
('kids-furniture','kids-supplies','أثاث الأطفال وغرفهم','Kids Furniture',3),
('kids-feeding','kids-supplies','الرضاعة والأكل','Feeding & Nursing',4),
('kids-toys','kids-supplies','ألعاب الأطفال','Toys',5),
('kids-school','kids-supplies','مستلزمات المدرسة','School Supplies',6),
('kids-bathing','kids-supplies','الاستحمام والعناية','Bath & Care',7),
('kids-safety','kids-supplies','السلامة والحماية','Safety & Protection',8),
('kids-carriers','kids-supplies','حمالات ومستلزمات التنقل','Carriers & Travel',9),
('kids-bedding','kids-supplies','مفروشات الأطفال','Kids Bedding',10),

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
INSERT INTO public.categories(parent_id,name_ar,name_en,slug,is_active,display_order)
SELECT parent.id,n.name_ar,n.name_en,n.slug,true,n.display_order
FROM new_categories n
JOIN public.categories parent ON parent.slug=n.parent_slug
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.regions(name_ar,name_en,city_ar,city_en,is_active,is_delivery_active)
VALUES
('زهراء المعادي','Zahraa El Maadi','القاهرة','Cairo',true,false),
('حدائق المعادي','Hadayeq El Maadi','القاهرة','Cairo',true,false),
('دار السلام','Dar El Salam','القاهرة','Cairo',true,false),
('جاردن سيتي','Garden City','القاهرة','Cairo',true,false),
('الزمالك','Zamalek','القاهرة','Cairo',true,false),
('بين السرايات','Bein El Sarayat','القاهرة','Cairo',true,false),
('أرض اللواء','Ard El Lewa','الجيزة','Giza',true,false),
('بولاق الدكرور','Boulaq El Dakrour','الجيزة','Giza',true,false),
('إمبابة','Imbaba','الجيزة','Giza',true,false),
('الوراق','El Warraq','الجيزة','Giza',true,false),
('الروضة','El Rawda','القاهرة','Cairo',true,false),
('مصر القديمة','Old Cairo','القاهرة','Cairo',true,false)
ON CONFLICT (name_en,city_en) DO NOTHING;

ALTER TABLE public.products
ADD CONSTRAINT products_weight_max_10kg_check
CHECK (weight_kg IS NULL OR (weight_kg > 0 AND weight_kg <= 10));
