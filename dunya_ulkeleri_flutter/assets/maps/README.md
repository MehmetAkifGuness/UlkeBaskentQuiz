# Harita Asset'leri

Bu klasöre GeoJSON formatında dünya ülkeleri haritası eklenmelidir. Ülke
özelliklerinde `name`, `iso_a2` veya `iso_a3` alanları bulunmalıdır.

Beklenen dosyalar:
- `world_map_simplified.json` (önerilen, performans için sadeleştirilmiş)
- `world_map.json` (opsiyonel, ham/yüksek detay kaynak)

Not:
- `world_map_simplified.json`, `world_map.json` üzerinden sadeleştirme (vertex azaltma) yapılarak üretilir.
- Harita performansı düşük cihazlarda kasıyorsa öncelikle GeoJSON sadeleştirme seviyesini artırın.

Örnek (CLI):
- `cd dunya_ulkeleri_flutter`
- `python tools/simplify_world_map_geojson.py --tolerance 0.02`

Önerilen veri kaynağı:
- Natural Earth "Admin 0 - Countries" (GeoJSON / Shapefile'dan dönüştürülmüş)

Beklenen özellik alanları (en az biri yeterlidir):
- Ülke adı: `name`, `NAME`, `admin`, `ADMIN`
- ISO kodu: `iso_a2`, `ISO_A2`, `iso_a3`, `ISO_A3` (tercihen `ISO_A3`)

Not:
- Bu repo, harita verisi eksik olsa bile uygulamanın crash etmemesi için kullanıcı dostu hata mesajı gösterir.
