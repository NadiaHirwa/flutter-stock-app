# Sales Tracker App

## Overview
Sales Tracker is a cross-platform app (iPhone, Android, and web) for small tech shops to manage:

- Stock of items (laptops, accessories, storage devices, etc.)
- Sales transactions
- Income and profit tracking
- Customer information

This app is designed to simplify stock management, track sales, and calculate profits automatically.

---

## Project Structure

See [`STRUCTURE.md`](STRUCTURE.md) for the full folder/file layout.

```
sales_tracker/
├── lib/
│   ├── main.dart              # Entry point with AuthWrapper
│   ├── data/
│   │   └── app_data.dart      # Firebase data streams
│   ├── services/
│   │   ├── auth_service.dart      # Firebase Authentication
│   │   └── firestore_service.dart # Firestore CRUD operations
│   └── pages/                 # All UI screens
├── assets/
│   └── images/                # App icon and images
├── pubspec.yaml
├── README.md
├── STRUCTURE.md
├── FIREBASE_SETUP.md          # Firebase Authentication setup guide
└── ICON_SETUP.md              # App icon & splash screen setup
```

---

## Users & Authentication
- **3 authorized users** with password protection
- Firebase Authentication for secure login
- All users have full access to all features
- Session management with auto-logout
- "Remember me" functionality for convenience

---

## Pages & Features

### 1. Login Page
- Firebase Authentication integration
- Enter email/password to access the app
- Show/hide password toggle
- "Remember me" checkbox (saves email locally)
- Real-time validation and error handling
- Loading states during authentication

### 2. Dashboard / Summary
- Overview cards: item types, total units, inventory value, transactions count
- Quick action buttons: Add Item, Sell Item, View Stock, Transactions, Financials
- Responsive layout (centered, max-width constrained)

### 3. Stock Page
- Search bar (name, model, type)
- Filter dropdown by item type
- Item cards: name, type chip, condition, price (total selling price for stored quantity), status (Available / Out of stock). For bulk items (Storage and Other accessories) the card shows the current total minimum selling price for the remaining stock and the quantity in stock.
- View Details button → View Item Page
- Bottom "Sell Item" button → Sell Item Page
- FAB to Add Item

### 4. Add Item Page
- Validated form with type-specific fields:
  - Laptop: model, serial, RAM, storage, processor, condition, installed. Laptops are single unique items and do not have a quantity field.
  - Storage: type (SSD/HDD/Flash/RAM), size, condition; RAM shows DDR3/4/5 dropdown. Storage items are recorded in bulk and include a `Quantity` field.
  - Accessories (Mouse, Keyboard, Charger, Other accessories): condition and `Quantity` for bulk accessories.
- Required: name, buying price (total), selling price (total for the full quantity). For bulk items the entered buying/selling prices represent totals for the whole quantity; unit prices are derived by dividing by quantity.
- On save, adds/updates item in stock (Laptops saved as quantity = 1; bulk items save the provided `quantity`).

### 5. Sell Item Page
- Search/select item from stock
- Shows selected item info (stock, type, prices)
- Inputs: quantity to sell, selling price (entered as the total price for the selected quantity), customer (optional), notes (optional)
- Live calculated total and profit (in Rwf) — totals are computed from the entered selling total and the cost basis derived from stored totals / quantity.
- Validation rules updated for bulk items:
  - `qty` must be ≥ 1 and ≤ available stock.
  - For bulk items the stored `sellingPrice` represents the total minimum selling price for the entire stored quantity. The unit minimum selling price is computed as (stored sellingPrice ÷ quantity). When selling a partial quantity, the entered selling total must be >= (unit minimum selling price × quantity sold). This prevents selling below the calculated minimum.
  - The selling total must also be > 0.
- Confirm Sale: records the transaction (stores unit sale price and total), reduces the stock quantity by the sold amount, and updates the stored total `sellingPrice` and `buyingPrice` to reflect the remaining quantity using the unit prices (new total = unit price × remaining quantity). The item is only removed from stock when the remaining quantity becomes zero.
- Link to Transactions page

### 6. Transactions / Sales History Page
- Search by item, customer, or note
- Revenue and Profit summary cards
- List of transactions with date, amount, status
- Edit (customer, note, status) and Delete actions per transaction

### 7. View Item Page
- Detailed view of stock item fields (for bulk items the `Quantity` and current total `Selling Price` are shown). For laptops (single items) quantity is implicitly 1 and model/serial are required and displayed.
- `Condition` is recorded when the item is added and is shown on this page; it is not edited during selling.
- Edit and Delete actions in app bar

### 8. Financials Page
- Monthly dropdown filter (last 12 months)
- Metrics: revenue, profit, margin %, transactions, avg ticket, units sold
- Balance sheet: inventory cost, potential revenue, potential profit, losses
- Centered, responsive grid layout

---

## Key Functionalities
- Stock management: add, edit, remove items
- Sales recording: price, customer info, notes
- Automatic stock update after sale
- Transactions history: view, filter, edit, delete
- Live calculation of total sale and profit
- Search & filter functionality
- Responsive UI for mobile and desktop

---

## Data Storage & Backend

### Firebase Integration
- **Firestore Database**: All data persisted in Firebase
  - `items` collection: Stock items with all details
  - `transactions` collection: Sales records with item references
- **Real-time Sync**: All pages update automatically when data changes
- **Firebase Authentication**: Secure login for 3 authorized users

### Data Relationships
- **Stock Items** → Stored in Firestore `items` collection
- **Transactions** → Stored in Firestore `transactions` collection with item references
- Selling an item → Updates item quantity in Firestore and creates transaction document
- All operations are real-time: changes sync across all devices instantly

---

## Navigation Flow
1. Login → Dashboard
2. Dashboard → Stock Page / Sell Item / Transactions / Financials
3. Stock Page → Add Item / View Item / Sell Item
4. Sell Item → Confirm Sale → Updates stock & transactions
5. Transactions → view/edit/delete sales

---

## Notes for Developers
- **Backend**: Firebase Firestore for data persistence and real-time sync
- **Authentication**: Firebase Auth with 3 user accounts
- **Data Access**: `AppData` provides streams from Firestore (not in-memory)
- **Real-time Updates**: All pages use `StreamBuilder` for live data
- **Sell Item Page**: Calculates **total and profit live** as user enters quantity and selling price
- **Validation**: All forms include validation (e.g., cannot sell more than stock quantity, selling price ≥ buying price)
- **UI**: Responsive design with centered content, max-width constraints, adaptive grids, smaller buttons on desktop
- **Currency**: Displayed as **Rwf** (Rwandan Franc)
- **Error Handling**: Comprehensive error messages and loading states throughout

---

## Current Implementation (2025-01)
- ✅ **Firebase Integration**: Complete Firestore backend with real-time sync
- ✅ **Authentication**: Firebase Auth with 3-user support, secure login/logout
- ✅ **Login**: Carded form with Firebase authentication, show/hide password, remember-me, error handling
- ✅ **Dashboard**: Real-time summary cards, quick actions, responsive grid with live data
- ✅ **Stock Page**: Real-time search/filter, item cards, View/Sell actions, add-item FAB
- ✅ **Add Item**: Validated form, type-specific fields, saves to Firestore
- ✅ **Sell Item**: Search/select, live total/profit, validation, creates transaction and updates stock in Firestore
- ✅ **Transactions**: Real-time list, search, revenue/profit summary, edit/delete with Firestore
- ✅ **Financials**: Monthly snapshot with real-time data, balance sheet metrics, responsive layout
- ✅ **View Item**: Real-time item details, edit/delete with Firestore
- ✅ **App Icon & Splash Screen**: Configured with FH Technology branding
- ✅ **Device Preview**: Enabled in debug via `device_preview` for responsive testing

---

## Setup & Configuration

### Prerequisites
1. Flutter SDK (^3.8.1)
2. Firebase project configured
3. Firebase Authentication enabled (Email/Password)
4. Firestore Database initialized

### Initial Setup
1. **Firebase Setup**: Follow [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md) to create 3 user accounts
2. **App Icon**: Follow [`ICON_SETUP.md`](ICON_SETUP.md) to set up app icon and splash screen
3. **Install Dependencies**: `flutter pub get`
4. **Run App**: `flutter run`

---

## Remaining / Next Steps
- ✅ Test on real phone
- ✅ Fix any issues found during testing
- ✅ App icon & splash screen (configured, needs image file)
- ⏳ Final polish and optimizations
- 📋 Future enhancements:
  - Export transactions (CSV/PDF)
  - Charts for trends
  - Dark mode toggle
  - Low-stock notifications
  - Automated tests (widget/unit)
