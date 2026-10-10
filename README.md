# AION 2 Türkçe Yama (Steam Sürümü)

AION 2 için hazırlanmış kapsamlı ve yerel Türkçe dil yamasıdır.

Bu yama, oyunun en güncel Steam sürümündeki **152.774 metin satırının tamamını** kapsar ve Unreal Engine 5'in yerel L10N (Localization) yapısını kullanarak oyunu Türkçe oynanabilir hale getirir.

---

## 🌟 Özellikler

- **%100 Kapsam (152.774 Satır):** Hikâye diyalogları, görevler, arayüz (UI), eşyalar, beceriler ve sinematikler dahil eksiksiz Türkçe veri seti.
- **Tipografi & Font Optimizasyonu:** Oyun motorunun büyük başlıklarda, eşya kartlarında, becerilerde ve yaratık panellerinde kullandığı dekoratif serif fontunun özel karakter uyumsuzlukları (boynuzlu/glif bozulmaları) giderilmiştir. Görev başlıkları, eşya isimleri, kostüm/skin adları, boss ve bölge adları temiz ve estetik font görünümüne kavuşturulmuştur. Tüm diyalog, hikâye anlatımı ve gövde metinleri ise tam Türkçe karakter desteğiyle sunulur.
- **Güvenli & Otomatik Kurulum:** Tek tıkla otomatik kurulum, orijinal dosyaları yedekleme ve tek tıkla orijinal İngilizceye geri dönme imkânı.
- **Oyun Dosyalarına Zarar Vermez:** Orijinal oyun dosyalarını bozmaz, istediğiniz an `GeriAl.bat` ile orijinal haline getirebilirsiniz.

---

## 🚀 Kurulum

1. Bu depoyu indirin (`Code` -> `Download ZIP` veya `git clone`).
2. İndirdiğiniz klasörü açın.
3. **`Kur.bat`** dosyasına çift tıklayın.
4. Kurulum aracı Steam kütüphanenizdeki AION 2 kurulumunu otomatik olarak bulur, orijinal dosyaları yedekler ve Türkçe yamayı kurar.
5. Oyuna girin! *(Oyun içi dil ayarınız **İngilizce (English)** olarak kalmalıdır).*

---

## 🔄 Yamayı Kaldırma (Orijinale Dönme)

Yamayı dilediğiniz zaman kaldırmak için:
1. Klasördeki **`GeriAl.bat`** dosyasına çift tıklayın.
2. Orijinal dosyalarınız yedekten geri yüklenecektir.

---

## 🔍 Durum Kontrolü

Yamanın kurulu olup olmadığını kontrol etmek için:
- **`Durum.bat`** dosyasını çalıştırabilirsiniz.

---

## ⚠️ Önemli Notlar & Sıkça Sorulan Sorular

- **Oyun İçi Dil:** Oyun içi ayarlarında dil **English / İngilizce** seçili olmalıdır. Yama, İngilizce yerelleştirme katmanına Türkçe veri enjekte eder.
- **Steam Güncellemeleri:** Steam üzerinden oyuna bir güncelleme geldiğinde veya *Dosyaların Bütünlüğünü Doğrula* yaptığınızda yama dosyaları sıfırlanabilir. Böyle bir durumda tek yapmanız gereken **`Kur.bat`** dosyasını yeniden çalıştırmaktır.
- **Güvenlik / Anti-Cheat:** Yama yalnızca yerelleştirme (dil metin tablosu) dosyalarını hedefler. Oyunun çalıştırılabilir kodlarına, belleğe veya motor ikililerine müdahale etmez.

---

## 🛠️ Teknik Detaylar

- **Veri Yapısı:** Unreal Engine 5 ikili `FString` serileştirmesi, LZ4 blok sıkıştırma ve AES-256-ECB şifreleme ile paketlenmiş `L10NString.dat`.
- **Yöntem:** UE5 L10N gevşek dosya (loose file) önceliği ve yerel fallback mekanizması.
