begin;

with root as (
  insert into public.categories (name_ar, name_en, name_fr, slug, parent_id, sort_order, is_active)
  values ('شنط وإكسسوارات', 'Bags & Accessories', 'Sacs et accessoires', 'bags-accessories', null, 5, true)
  returning id
)
insert into public.categories (name_ar, name_en, name_fr, slug, parent_id, sort_order, is_active)
select v.name_ar, v.name_en, v.name_fr, v.slug, root.id, v.sort_order, true
from root
cross join (values
  ('الشنط','Bags','Sacs','bags-accessories-bags',1),
  ('المجوهرات والحُلي','Jewelry','Bijoux','bags-accessories-jewelry',2),
  ('الساعات','Watches','Montres','bags-accessories-watches',3),
  ('النظارات','Eyewear','Lunetterie','bags-accessories-eyewear',4),
  ('إكسسوارات الملابس','Clothing Accessories','Accessoires vestimentaires','bags-accessories-clothing-accessories',5),
  ('إكسسوارات الشعر','Hair Accessories','Accessoires pour cheveux','bags-accessories-hair-accessories',6),
  ('إكسسوارات شخصية متنوعة','Personal Accessories','Accessoires personnels','bags-accessories-personal-accessories',7)
) as v(name_ar,name_en,name_fr,slug,sort_order);

insert into public.categories (name_ar, name_en, name_fr, slug, parent_id, sort_order, is_active)
select v.name_ar, v.name_en, v.name_fr, v.slug, p.id, v.sort_order, true
from (values
  ('شنط حريمي','Women’s Bags','Sacs pour femmes','bags-accessories-bags-women',1,'bags-accessories-bags'),
  ('شنط رجالي','Men’s Bags','Sacs pour hommes','bags-accessories-bags-men',2,'bags-accessories-bags'),
  ('شنط ظهر','Backpacks','Sacs à dos','bags-accessories-bags-backpacks',3,'bags-accessories-bags'),
  ('شنط مدارس','School Bags','Sacs scolaires','bags-accessories-bags-school',4,'bags-accessories-bags'),
  ('شنط سفر','Travel Bags','Sacs de voyage','bags-accessories-bags-travel',5,'bags-accessories-bags'),
  ('شنط لابتوب','Laptop Bags','Sacs pour ordinateur portable','bags-accessories-bags-laptop',6,'bags-accessories-bags'),
  ('شنط رياضية','Sports Bags','Sacs de sport','bags-accessories-bags-sports',7,'bags-accessories-bags'),
  ('محافظ وحافظات بطاقات','Wallets & Card Holders','Portefeuilles et porte-cartes','bags-accessories-bags-wallets',8,'bags-accessories-bags'),
  ('أخرى','Other','Autres','bags-accessories-bags-other',9,'bags-accessories-bags'),

  ('أطقم ومجموعات','Jewelry Sets','Parures et ensembles','bags-accessories-jewelry-sets',1,'bags-accessories-jewelry'),
  ('سلاسل وقلادات','Necklaces','Colliers','bags-accessories-jewelry-necklaces',2,'bags-accessories-jewelry'),
  ('أساور','Bracelets','Bracelets','bags-accessories-jewelry-bracelets',3,'bags-accessories-jewelry'),
  ('خواتم','Rings','Bagues','bags-accessories-jewelry-rings',4,'bags-accessories-jewelry'),
  ('حلق','Earrings','Boucles d’oreilles','bags-accessories-jewelry-earrings',5,'bags-accessories-jewelry'),
  ('دبابيس وبروش','Pins & Brooches','Épingles et broches','bags-accessories-jewelry-brooches',6,'bags-accessories-jewelry'),
  ('أخرى','Other','Autres','bags-accessories-jewelry-other',7,'bags-accessories-jewelry'),

  ('ساعات رجالي','Men’s Watches','Montres pour hommes','bags-accessories-watches-men',1,'bags-accessories-watches'),
  ('ساعات حريمي','Women’s Watches','Montres pour femmes','bags-accessories-watches-women',2,'bags-accessories-watches'),
  ('ساعات أطفال','Kids’ Watches','Montres pour enfants','bags-accessories-watches-kids',3,'bags-accessories-watches'),
  ('ساعات ذكية','Smart Watches','Montres connectées','bags-accessories-watches-smart',4,'bags-accessories-watches'),
  ('أخرى','Other','Autres','bags-accessories-watches-other',5,'bags-accessories-watches'),

  ('نظارات شمس','Sunglasses','Lunettes de soleil','bags-accessories-eyewear-sunglasses',1,'bags-accessories-eyewear'),
  ('نظارات طبية وإطارات','Optical Glasses & Frames','Lunettes de vue et montures','bags-accessories-eyewear-optical',2,'bags-accessories-eyewear'),
  ('أخرى','Other','Autres','bags-accessories-eyewear-other',3,'bags-accessories-eyewear'),

  ('أحزمة','Belts','Ceintures','bags-accessories-clothing-accessories-belts',1,'bags-accessories-clothing-accessories'),
  ('كوفيات وشالات','Scarves & Shawls','Écharpes et châles','bags-accessories-clothing-accessories-scarves',2,'bags-accessories-clothing-accessories'),
  ('قبعات وكابات','Hats & Caps','Chapeaux et casquettes','bags-accessories-clothing-accessories-hats',3,'bags-accessories-clothing-accessories'),
  ('جوانتيات','Gloves','Gants','bags-accessories-clothing-accessories-gloves',4,'bags-accessories-clothing-accessories'),
  ('ربطات عنق','Ties','Cravates','bags-accessories-clothing-accessories-ties',5,'bags-accessories-clothing-accessories'),
  ('أخرى','Other','Autres','bags-accessories-clothing-accessories-other',6,'bags-accessories-clothing-accessories'),

  ('توك ومشابك','Hair Ties & Clips','Élastiques et pinces à cheveux','bags-accessories-hair-accessories-clips',1,'bags-accessories-hair-accessories'),
  ('أطواق وباندانات','Headbands & Bandanas','Bandeaux et bandanas','bags-accessories-hair-accessories-headbands',2,'bags-accessories-hair-accessories'),
  ('إكسسوارات تسريحات الشعر','Hair Styling Accessories','Accessoires de coiffure','bags-accessories-hair-accessories-styling',3,'bags-accessories-hair-accessories'),
  ('أخرى','Other','Autres','bags-accessories-hair-accessories-other',4,'bags-accessories-hair-accessories'),

  ('ميداليات وسلاسل مفاتيح','Keychains','Porte-clés','bags-accessories-personal-accessories-keychains',1,'bags-accessories-personal-accessories'),
  ('إكسسوارات الهاتف','Phone Accessories','Accessoires pour téléphone','bags-accessories-personal-accessories-phone',2,'bags-accessories-personal-accessories'),
  ('أخرى','Other','Autres','bags-accessories-personal-accessories-other',3,'bags-accessories-personal-accessories')
) as v(name_ar,name_en,name_fr,slug,sort_order,parent_slug)
join public.categories p on p.slug = v.parent_slug;

update public.categories
set parent_id = (select id from public.categories where slug = 'clothes'),
    sort_order = case slug
      when 'clothes-other-uniforms' then 5
      when 'clothes-other-workwear' then 6
      when 'clothes-other-costumes' then 7
      else sort_order
    end
where slug in ('clothes-other-uniforms','clothes-other-workwear','clothes-other-costumes');

update public.categories
set parent_id = (select id from public.categories where slug = 'clothes-women'),
    sort_order = 18
where slug = 'clothes-other-special-occasion';

commit;
