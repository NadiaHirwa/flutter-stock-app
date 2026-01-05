# Sales Tracker – Project Structure

```
sales_tracker/
├── lib/
│   ├── main.dart                  # App entry point, AuthWrapper, MaterialApp, DevicePreview
│   ├── firebase_options.dart       # FlutterFire generated configuration
│   ├── data/
│   │   └── app_data.dart          # Firebase data streams (stockItemsStream, transactionsStream)
│   ├── services/
│   │   ├── auth_service.dart          # Firebase Authentication (login, logout, remember me)
│   │   └── firestore_service.dart    # Firestore CRUD operations (items & transactions)
│   └── pages/
│       ├── login_page.dart        # Firebase Auth login form with validation
│       ├── dashboard_page.dart    # Real-time overview stats & quick action buttons
│       ├── stock_page.dart        # Real-time stock list with search/filter, View/Sell actions
│       ├── add_item_page.dart     # Add/edit item form, saves to Firestore
│       ├── view_item_page.dart    # Item detail view with edit/delete (Firestore)
│       ├── sell_item_page.dart    # Sell flow: creates transaction & updates item in Firestore
│       ├── transactions_page.dart # Real-time transaction list with revenue/profit summary
│       └── financials_page.dart   # Monthly financial snapshot with real-time data
├── assets/
│   └── images/
│       └── app_icon.jpg           # App icon (FH Technology logo)
├── android/                       # Android platform configuration
├── ios/                           # iOS platform configuration
├── web/                           # Web platform configuration
├── pubspec.yaml                   # Dependencies (Firebase, device_preview, etc.)
├── README.md                      # Project overview, features, navigation, notes
├── STRUCTURE.md                   # This file – folder/file layout
├── FIREBASE_SETUP.md              # Firebase Authentication setup guide
└── ICON_SETUP.md                  # App icon & splash screen setup guide
``` 

## Key Folders

| Folder            | Purpose                                      |
|-------------------|----------------------------------------------|
| `lib/`            | All Dart source code                         |
| `lib/data/`       | Data access layer (Firebase streams)         |
| `lib/services/`   | Business logic & Firebase services           |
| `lib/pages/`      | UI screens (one file per page)               |
| `assets/images/`  | App icon and image assets                    |

## Data Flow

1. **Firestore Collections**:
   - `items` collection: Stock items with all details (type, name, qty, prices, etc.)
   - `transactions` collection: Sales records with item references, quantities, prices, profit, dates

2. **Real-time Streams**:
   - `AppData.stockItemsStream` → Stream from Firestore `items` collection
   - `AppData.transactionsStream` → Stream from Firestore `transactions` collection

3. **Data Operations**:
   - All CRUD operations go through `FirestoreService`
   - Pages use `StreamBuilder` for real-time updates
   - Selling an item → Updates item in Firestore + Creates transaction document
   - Changes sync automatically across all devices

## Navigation

```
AuthWrapper (main.dart)
   │
   ├──▶ LoginPage (if not authenticated)
   │       └──▶ Firebase Authentication
   │
   └──▶ DashboardPage (if authenticated)
           ├──▶ StockPage ──▶ AddItemPage / ViewItemPage / SellItemPage
           ├──▶ SellItemPage
           ├──▶ TransactionsPage
           └──▶ FinancialsPage
```

## Firebase Collections

### `items` Collection
Each document contains:
- `id` (auto-generated)
- `type`, `name`, `brand`
- `buyingPrice`, `sellingPrice` (totals for quantity)
- `quantity`
- `dateOfPurchase`, `description`
- Type-specific fields (model, serial, RAM, storage, etc.)

### `transactions` Collection
Each document contains:
- `id` (auto-generated)
- `itemId` (Reference to items collection)
- `itemType`, `itemName` (for easy display/search)
- `quantity`, `unitPrice`, `total`, `profit`
- `buyingPrice`, `sellingPrice` (unit prices at time of sale)
- `customer`, `notes`, `status`
- `date` (Timestamp)

## Services

### `AuthService`
- `signInWithEmailAndPassword()` - User login
- `signOut()` - User logout
- `authStateChanges` - Stream for auth state
- `saveRememberMe()` / `getRememberedEmail()` - Remember me functionality

### `FirestoreService`
- Items: `getItemsStream()`, `addItem()`, `updateItem()`, `deleteItem()`, `getItem()`
- Transactions: `getTransactionsStream()`, `addTransaction()`, `updateTransaction()`, `deleteTransaction()`, `getTransaction()`

