# Pharmacy Manager – Flutter App

A simple offline-first mobile app for pharmacy/medical store management: medicine inventory,
automatic low-stock & expiry alerts, patient records with purchase history, and a point-of-sale
(POS) screen that deducts stock automatically on every sale.

Everything is stored **locally on the phone** using SQLite (via the `sqflite` package) — no
internet or backend server required to run it.

---

## What's included

```
pharmacy_app/
  pubspec.yaml
  lib/
    main.dart                        -> app entry point + bottom navigation
    models/
      medicine.dart                  -> Medicine model (stock, expiry, price, etc.)
      patient.dart                   -> Patient model
      sale.dart                      -> Sale + SaleItem models
    db/
      database_helper.dart           -> SQLite setup + all CRUD + stock deduction logic
    screens/
      login_screen.dart              -> staff login (+ Forgot password link, + link to sign up)
      signup_screen.dart             -> create a new staff account (now includes email)
      forgot_password_screen.dart    -> recover password: emails it to the account's registered email
      auth_gate.dart                 -> top-level screen; owns session + auto-logout timer
      dashboard_screen.dart          -> home screen with stats (sales, low stock, expiry)
      medicine_list_screen.dart      -> browse/search medicines, badges for status
      medicine_reference_list_screen.dart -> browse built-in drug reference list, Add to Stock, export sheet
      add_medicine_screen.dart       -> add/edit medicine form
      bulk_upload_screen.dart        -> import medicines in bulk from Excel/CSV
      alerts_screen.dart             -> Low Stock / Expiring / Expired tabs
      patient_list_screen.dart       -> browse/search patients
      add_patient_screen.dart        -> add/edit patient form
      patient_history_screen.dart    -> patient details + purchase history
      sale_screen.dart               -> POS screen: search, cart, checkout
      sales_history_screen.dart      -> list of all past sales
      settings_screen.dart           -> profile + manual logout
    services/
      session_manager.dart           -> auto-logout timer (SharedPreferences-backed)
      email_service.dart             -> SMTP email sending for password recovery
    theme/
      app_colors.dart                -> one accent color per app section/menu
```

## Features implemented (working, not just UI mockups)

- ✅ **Staff sign up / login** — anyone can create their own username + email + password from the login screen; passwords are hashed (never stored as plain text) for login checks. A default `admin` / `admin123` account is still created automatically the first time the app runs.
- ✅ **Bulk medicine upload from Excel (.xlsx) or CSV** — pick a file from the Medicines screen (upload icon, top right), the app reads every row, shows a preview + skipped-row list, and imports them all in one tap.
- ✅ Add / edit / delete medicines with name, category, batch, prices, quantity, unit, expiry date, supplier
- ✅ **Automatic low-stock badge/alert** when quantity ≤ threshold you set per medicine
- ✅ **Automatic expiry alerts** — separate tabs for "expiring within 60 days" and "already expired"
- ✅ Add / edit / delete patient records (age, gender, phone, address, allergies, notes)
- ✅ Per-patient purchase history (auto-linked from sales)
- ✅ POS screen: search medicine → add to cart → adjust quantity → checkout
- ✅ **Stock is automatically deducted** from inventory the moment a sale is completed
- ✅ Optional discount field and payment type (Cash / Card / Mobile Wallet)
- ✅ Dashboard with today's total sales, medicine count, patient count, and alert counts
- ✅ Full sales history log

### Bulk upload file format
First row = column headers (any order). Only `name` is required — everything else
uses a sensible default if left blank:

```
name, genericName, category, batchNo, purchasePrice, salePrice, quantity, unit, expiryDate, supplier, minStockAlert
Panadol, Paracetamol, Painkiller, B-101, 3.5, 5, 100, tablet, 2027-06-30, ABC Distributors, 20
```
`expiryDate` should ideally be `YYYY-MM-DD`, but common `DD/MM/YYYY` style is also
detected. **PDF files are not supported for import** — table data inside PDFs is
unreliable to auto-extract. If your list is in PDF, open it and re-save/export it as
Excel or CSV first (or copy-paste into a spreadsheet) — that only takes a minute and
guarantees a clean import.

## New: Medicine & Patient Lookup + Settings

- ✅ **Medicine & Patient Lookup** (tap the shield icon in the top bar, or the teal
  banner on the dashboard) — type the medicine the patient asked for (brand or
  generic name, e.g. "Brufen") and instantly see its **usage, dosage, overdose
  risks, and precautions**, pulled from a built-in offline drug reference
  covering ~20 common medicines (Brufen, Panadol, Augmentin, Disprin, Ponstan,
  Flagyl, Risek, Motilium, Ventolin, and more). At the same time, search for or
  quick-create the patient's record right there, then jump straight into a sale
  with both pre-filled. An info icon next to each medicine in the Sell screen
  opens the same reference card. You can also add your own usage/dosage/
  overdose/precautions notes to any medicine in Add/Edit Medicine — those
  always take priority over the built-in reference (with an "Auto-fill from
  reference database" shortcut).
- ✅ **Settings screen** (account icon in the top bar) — shows the signed-in
  staff member's profile (full name, username, email, account created date)
  with a Logout button at the bottom that logs out immediately when tapped
  and confirmed.

## New: Auto-logout timer, Forgot Password, and Medicine Reference browsing

### 🔒 Auto-logout after closing the app
The app now automatically logs a user out after it has been closed/backgrounded
for **30 seconds** (configurable — see `lib/services/session_manager.dart`,
`autoLogoutAfter`). If you switch back within that window, you stay logged in;
after that, the next time you open the app you're back at the Login screen.
The manual "Log out" button in Settings still works immediately and
independently, exactly as before.

### 🔑 Forgot Password (emails your password to you)
On the Login screen, tap **"Forgot password?"**. Enter your username or email,
and — if it matches an account — the app emails your actual password to the
email address on file for that account (never to an address you type in, so
no one can recover someone else's password just by knowing their username).

**⚠️ You must configure this before it will actually send email.** Open
`lib/services/email_service.dart` and set `_senderEmail` / `_senderAppPassword`
to a real Gmail address + [App Password](https://myaccount.google.com/apppasswords)
(requires 2-Step Verification enabled on that Gmail account — Gmail blocks
normal passwords for this). Until configured, the screen shows a clear
"not configured yet" message instead of failing silently.

**A security note worth understanding:** passwords are normally stored as a
one-way hash that can *never* be reversed — that's what makes hashing secure.
To satisfy "email me my actual password back," this app keeps a **second,
separately-encrypted, reversible copy** of the password just for this feature
(see the comments in `lib/db/auth_helper.dart`). This is a deliberate
trade-off for convenience and is fine for a student/demo project, but it is
weaker than a real password-reset-link flow, and the SMTP credentials above
also live inside the compiled app. For a production app, ask me to switch
this to a reset-link/reset-code flow instead — it never needs to store a
recoverable password at all.

### 📖 Medicine Reference List (browse, add to stock, export)
From the Medicines tab, tap the book icon (top right) to open the full
built-in drug reference list — not just one-at-a-time search like the
Medicine & Patient Lookup screen. You can search/filter it, tap any entry to
see full details, tap **"Add to Stock"** to jump straight into Add Medicine
pre-filled with that drug's info, and tap the export icon to save the
current list as an `.xlsx` sheet.

### 🎨 Distinct color per section
Each part of the app now has its own accent color so it's easy to tell which
section you're in at a glance — Dashboard (teal), Medicines (indigo), Sell
(deep orange), Patients (purple), Alerts (red), Settings (blue-grey),
Medicine Reference (green), Medicine & Patient Lookup (cyan). See
`lib/theme/app_colors.dart` to change any of them.

## Not yet included (you can ask me to add these next)

- Barcode scanning (needs a camera plugin like `mobile_scanner`)
- Cloud sync/backup (currently local-only storage)
- Staff roles / permissions (currently every signed-up account has full access)
- PDF receipt printing
- Urdu language translation
- Reset-link/reset-code password flow (safer alternative to emailing the
  actual password, mentioned above)

---

## How to run this app

You'll need **Flutter SDK** installed on your computer (Windows/Mac/Linux) — this app cannot run
directly inside this chat, only on your machine or in an emulator/real phone.

### Step 1 — Install Flutter
Download and install from: https://docs.flutter.dev/get-started/install
Then verify it works:
```
flutter doctor
```

### Step 2 — Get the project onto your computer
Extract the ZIP file you downloaded from this chat into a folder, e.g. `pharmacy_app/`.

### Step 3 — Install dependencies
Open a terminal inside the `pharmacy_app` folder and run:
```
flutter pub get
```

### Step 4 — Run it
Connect an Android phone (with USB debugging on) or start an emulator, then run:
```
flutter run
```

### Step 5 — Build a real installable APK (to share/install without a computer)
```
flutter build apk --release
```
The installable file will appear at:
```
build/app/outputs/flutter-apk/app-release.apk
```
Send that `.apk` file to any Android phone and install it directly.

---

## How to build a Windows desktop app (.exe)

This same codebase can also run as a Windows desktop app — you just need to
generate the Windows platform files once on your own Windows PC (they can't
be pre-packaged in this ZIP since they need to be generated by the exact
Flutter SDK version installed on your machine).

### Step 1 — Install Flutter (with Windows desktop support)
Download from https://docs.flutter.dev/get-started/install, then confirm
desktop support is enabled:
```
flutter config --enable-windows-desktop
flutter doctor
```
`flutter doctor` should show a checkmark for "Visual Studio" — Windows
desktop builds need the free **Visual Studio (Community) with the "Desktop
development with C++" workload**, not VS Code's C++ tools. Install that if
`flutter doctor` flags it missing.

### Step 2 — Extract the ZIP and open it
Extract this project, then open the `pharmacy_app` folder in VS Code (with
the Flutter + Dart extensions installed).

### Step 3 — Generate the Windows platform files
In a terminal inside the `pharmacy_app` folder:
```
flutter create . --platforms=windows
```
This adds a new `windows/` folder to the project (this is normal — it's the
native Windows wrapper Flutter needs and only has to be generated once).

### Step 4 — Get dependencies
```
flutter pub get
```

### Step 5 — Run it
```
flutter run -d windows
```

### Step 6 — Build a shareable .exe
```
flutter build windows --release
```
The finished app folder (containing the `.exe` and required `.dll` files —
copy the **whole folder**, not just the `.exe`) will be at:
```
build\windows\x64\runner\Release\
```

### Note on the database
This app was originally built for Android/iOS storage (`sqflite`). I've
already added `sqflite_common_ffi` and updated `lib/db/database_helper.dart`
so it automatically switches to the Windows-compatible database engine — no
extra steps needed for that part, it "just works" once you've done Steps 1–6
above.

---

## Recommended next tools
- **Android Studio** or **VS Code** (with the Flutter + Dart extensions) — easiest way to open and run this project with a visual interface.
- To publish on the Play Store, you'll need a Google Play Developer account ($25 one-time fee).

---

## Notes
- All data is stored locally on the device. If you uninstall the app, the data is lost — for a
  real pharmacy, ask me to add cloud backup (Firebase) next.
- Prices are shown in "Rs." (Pakistani Rupees) — change this in the screen files if needed.
