-- Keep imported third-level catalog items after their existing second-level siblings.
with imported(slug,parent_id,sort_order) as (
  select c.slug,c.parent_id,
         row_number() over (partition by c.parent_id order by c.sort_order,c.slug)::integer
  from public.categories c
  where c.slug in ('home-furniture-sofas','home-furniture-chairs','home-furniture-tables','home-furniture-tv-units','home-furniture-shoe-racks','home-furniture-mattresses','home-decor-clocks','home-decor-candles','home-decor-artificial-plants','home-kitchen-utensils','home-kitchen-coffee-tea','home-kitchen-food-storage','home-kitchen-knives','home-kitchen-glassware','home-appliances-fridges','home-appliances-washers','home-appliances-dishwashers','home-appliances-ovens','home-appliances-microwaves','home-appliances-vacuums','home-textiles-throws','home-textiles-cushions','home-textiles-bath','home-lighting-floor','home-lighting-smart','home-storage-shoes','home-storage-laundry','home-cleaning-mops','home-cleaning-glass','home-bathroom-curtains-mats','home-bathroom-towel-holders','home-garden-tools','home-garden-umbrellas','kids-strollers-travel-systems','kids-strollers-weather-accessories','kids-car-seats-bases','kids-car-seats-accessories','kids-furniture-changing-tables','kids-furniture-playpens','kids-feeding-nursing','kids-feeding-sterilizers','kids-feeding-cups','kids-feeding-bibs','kids-toys-puzzles','kids-toys-pretend-play','kids-toys-musical','kids-toys-ride-on','kids-school-books','kids-school-learning-aids','kids-bathing-potty','kids-bathing-diaper-changing','kids-safety-corner-guards','kids-safety-childproof-locks','kids-carriers-travel-cots','kids-bedding-protectors','clothes-men-shorts','clothes-men-hoodies','clothes-men-knitwear','clothes-men-swimwear','clothes-women-shorts','clothes-women-hoodies','clothes-women-knitwear','clothes-women-swimwear','clothes-kids-underwear','clothes-kids-swimwear','clothes-kids-socks-basics','clothes-kids-occasion-wear','shoes-men-loafers','shoes-men-running','shoes-women-mules','shoes-women-platform','shoes-kids-indoor','shoes-kids-baby')
), base as (
  select c.parent_id,coalesce(max(c.sort_order),0) as max_order
  from public.categories c
  where c.slug not in ('home-furniture-sofas','home-furniture-chairs','home-furniture-tables','home-furniture-tv-units','home-furniture-shoe-racks','home-furniture-mattresses','home-decor-clocks','home-decor-candles','home-decor-artificial-plants','home-kitchen-utensils','home-kitchen-coffee-tea','home-kitchen-food-storage','home-kitchen-knives','home-kitchen-glassware','home-appliances-fridges','home-appliances-washers','home-appliances-dishwashers','home-appliances-ovens','home-appliances-microwaves','home-appliances-vacuums','home-textiles-throws','home-textiles-cushions','home-textiles-bath','home-lighting-floor','home-lighting-smart','home-storage-shoes','home-storage-laundry','home-cleaning-mops','home-cleaning-glass','home-bathroom-curtains-mats','home-bathroom-towel-holders','home-garden-tools','home-garden-umbrellas','kids-strollers-travel-systems','kids-strollers-weather-accessories','kids-car-seats-bases','kids-car-seats-accessories','kids-furniture-changing-tables','kids-furniture-playpens','kids-feeding-nursing','kids-feeding-sterilizers','kids-feeding-cups','kids-feeding-bibs','kids-toys-puzzles','kids-toys-pretend-play','kids-toys-musical','kids-toys-ride-on','kids-school-books','kids-school-learning-aids','kids-bathing-potty','kids-bathing-diaper-changing','kids-safety-corner-guards','kids-safety-childproof-locks','kids-carriers-travel-cots','kids-bedding-protectors','clothes-men-shorts','clothes-men-hoodies','clothes-men-knitwear','clothes-men-swimwear','clothes-women-shorts','clothes-women-hoodies','clothes-women-knitwear','clothes-women-swimwear','clothes-kids-underwear','clothes-kids-swimwear','clothes-kids-socks-basics','clothes-kids-occasion-wear','shoes-men-loafers','shoes-men-running','shoes-women-mules','shoes-women-platform','shoes-kids-indoor','shoes-kids-baby')
    and c.slug not like '%-other'
  group by c.parent_id
)
update public.categories target
set sort_order = base.max_order + imported.sort_order
from imported
join base on base.parent_id=imported.parent_id
where target.slug=imported.slug;

update public.categories other
set sort_order = (
  select coalesce(max(sibling.sort_order),0)+1
  from public.categories sibling
  where sibling.parent_id=other.parent_id and sibling.id<>other.id
)
where other.is_active and other.slug like '%-other';
