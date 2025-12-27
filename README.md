# Bitki Doktorum 🌿📱
**Bitki Doktorum**, Flutter + Firebase + Gemini (google_generative_ai) ile geliştirilmiş; **fotoğraftan bitki analizi** yapan ve analiz sonucunu **sohbet bağlamı** olarak kullanarak kullanıcıyla konuşabilen bir mobil uygulamadır.

---

## 📸 Uygulama Ekran Görüntüleri

> Görseller: `assets/screenshots/` klasöründe.

### Giriş / Kimlik Doğrulama
| Giriş Yap |
|---|
| ![](assets/screenshots/01_login.png) |

### Analiz Ekranı
| Foto Seçme (Kamera/Galeri) |
|---|
| ![](assets/screenshots/02_analyze.png) |

### Analiz Sonucu + Sohbet (Aynı bağlam)
| Analiz Sonucu + Sohbet | Uzun Sonuç Görünümü |
|---|---|
| ![](assets/screenshots/03_result_chat.png) | ![](assets/screenshots/04_result_chat.png) |

### Profil
| Profil Sayfası |
|---|
| ![](assets/screenshots/05_profile.png) |

---

## ✨ Özellikler

### 🔍 Bitki Analizi
- Kamera veya galeriden fotoğraf seçme
- Gemini ile fotoğraftan:
  - Bitki türü tahmini
  - Olası hastalık/zararlı belirtileri
  - Kısa bakım önerileri
- Analiz metni **SelectableText** (kopyalanabilir)

### 💬 Analiz Bağlamında Sohbet
- Analiz ekranında sohbet alanı
- “Tam ekran sohbet” sayfası
- **Yeni chat context oluşturmaz**: analiz bağlamını ve aynı mesaj geçmişini kullanır
- Sohbet tutarlılığı için en az son 6 mesaj modele aktarılır

### 🔐 Firebase Auth
- Kayıt / Giriş / Çıkış
- Şifremi Unuttum:
  - E-posta doluysa direkt reset mail
  - Boşsa e-posta isteyen dialog
- Mail değiştir / Şifre değiştir:
  - `requires-recent-login` gelirse re-auth modal (mevcut şifre) ile tekrar dener
  - Başarılı olunca güvenlik için logout + login ekranına dönüş
- Hesabı sil:
  - Auth hesabı + `/users/{uid}` Firestore dokümanı silinir

### 👤 Firestore Profil
- Döküman yolu: `/users/{uid}`
- Alanlar: `firstName`, `lastName`, `phone`, `birthDate`, `email`, `createdAt`
- Profil görüntüleme + düzenleme

### 🌓 Tema
- Material 3
- Dark/Light toggle
- SharedPreferences ile kalıcı tema

### 🧯 Stabilite
- Tüm async işlemler try/catch
- Hatalar kullanıcıya SnackBar ile Türkçe gösterilir
- `.env / Firebase / Gemini` gibi kurulum eksiklerinde crash yerine kontrollü uyarı yaklaşımı

---

## 🧱 Teknolojiler ve Paketler
- Flutter (Material 3)
- Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`
- Gemini: `google_generative_ai`
- Diğer: `image_picker`, `shared_preferences`, `flutter_dotenv`, `intl`, `mime`

---

## ✅ Kurulum

### 1) Projeyi oluştur
```bash
flutter create --org com.example bitki_doktorum
cd bitki_doktorum
