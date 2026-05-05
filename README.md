# AI Doctor Eyes 👁️

> **Your Digital Doctor in Your Pocket.** > A high-intelligence health-tech assistant that turns your camera into a medical guardian, ensuring every bite you take is safe for **your** specific body.

---

## 📖 The Story: Beyond the Label

Imagine standing in a grocery aisle, holding a product with a list of ingredients so long it feels like a chemistry textbook. For someone with **Diabetes**, a severe **Nut Allergy**, or **Hypertension**, this isn't just shopping—it’s a high-stakes guessing game.

**AI Doctor Eyes** was born to end the guesswork. By combining on-device OCR (Optical Character Recognition) with the reasoning power of **Gemini AI**, we created a tool that understands your medical history as well as a doctor does.

---

## ✨ Key Features

### 1. Precision Ingredient Scanning
Our custom-built scanning pipeline doesn't just read text; it understands it. Using **Google ML Kit**, it extracts ingredients and filters out the "noise" (like nutrition facts or brand names) to find exactly what matters.


<img width="461" height="1023" alt="image" src="https://github.com/user-attachments/assets/a5c1c128-5d70-4929-b3cd-4c5454908262" />

*Real-time scanning with immediate OCR cleanup.*

### 2. Personalized Medical Profiles
Your health is unique. The app allows you to select from standard conditions (Vegan, Keto, Gluten Allergy) or upload a **Lab Report**. Gemini AI analyzes your report to extract custom "forbidden keywords" that are saved directly to your local database.

| Condition Feature | Description |
| :--- | :--- |
| **Standard Profiles** | 10+ built-in conditions like Diabetes and Shellfish Allergy. |
| **Lab Report AI** | Dynamic extraction of restrictions from medical documents. |
| **Data Privacy** | All medical profiles are stored locally in an encrypted-ready SQLite database. |

### 3. Smart Alternatives & "Cravings" Search
If a product is unsafe, you don't have to go hungry. Our **Ideas** engine allows you to type in what you’re craving—like "Pizza"—and the AI suggests specific, healthy versions that are verified safe for your active health conditions.

<img width="461" height="1023" alt="image" src="https://github.com/user-attachments/assets/5a14e911-8cf7-41ee-b4a5-8cb41a9b6bd6" />

*Searching for healthy versions of your favorite cravings.*

---

## 🛠️ Technical Architecture

The app is built with a **Privacy-First, Offline-First** philosophy.

### The Analysis Pipeline:
1.  **EXTRACT:** Local OCR cleans and isolates the ingredient list.
2.  **TRANSFORM:** Normalizes text and applies OCR corrections.
3.  **ANALYZE (Tiered):**
    * **Tier 1:** Local SQLite check against your medical profile (Instant & Offline).
    * **Tier 2:** Gemini AI Cloud Analysis (Deep reasoning if the local check is inconclusive).

### Tech Stack:
* **Frontend:** Flutter (Mobile)
* **Intelligence:** Gemini 2.5 Flash & Google ML Kit
* **Persistence:** SQLite (sqflite) & SharedPreferences
* **Networking:** Connectivity Plus (for smart offline/online switching)

---

## 🔒 Privacy & Safety

We believe medical data should never leave your hand.
* **On-Device Processing:** Local dictionaries catch most threats without an internet connection.
* **No Tracking:** Your name, birth year, and medical keywords stay on your device.
* **Immediate Alerts:** High-contrast UI and vibration alerts ensure you never miss a critical warning.

<img width="461" height="1023" alt="image" src="https://github.com/user-attachments/assets/e99e5869-ad1e-493d-9ce3-11155374c46d" />
*Clear, color-coded danger levels for high-risk ingredients.*

---

## 🚀 How to Run
1. Clone the repository.
2. Create a `.env` file and add your `GEMINI_API_KEY`.
3. Run `flutter pub get`.
4. Launch on an Android or iOS device with camera support.

---

> **"AI Doctor Eyes: Because your health shouldn't be a guessing game."**
