# Shopora – Product Explorer (Flutter + REST API)

Shopora is a Flutter app built for the university assignment
**"Build a Flutter App Using a Public REST API"**. It lets you browse, search,
filter, sort, add, edit, delete and favorite products from the free
[DummyJSON](https://dummyjson.com) API. It also works offline using a Hive
cache.

---

## API Used

**DummyJSON Products API** – https://dummyjson.com/docs/products

| Purpose | Method & Endpoint |
|---|---|
| Product list (pagination) | `GET /products?limit=10&skip={n}` |
| Search | `GET /products/search?q={query}&limit=10&skip={n}` |
| Category list | `GET /products/category-list` |
| Products of a category | `GET /products/category/{slug}` |
| Product details | `GET /products/{id}` |
| Add product | `POST /products/add` |
| Update product | `PUT /products/{id}` |
| Delete product | `DELETE /products/{id}` |

Sorting uses the API query parameters `sortBy=price|rating` and
`order=asc|desc`.

> **Note:** DummyJSON only *simulates* add/update/delete; nothing is saved on
> the server. The app first calls the real API, then saves the result in Hive,
> so your changes stay after a refresh or app restart. Products created in the
> app get a negative id (`-timestamp`); editing or deleting them skips the API
> and only changes local storage.

---

## Features

### Core
1. **Splash screen** – logo and app name, opens Home after 2 seconds.
2. **Home screen** – product cards with image, title, brand/category,
   2-line description, price and rating.
3. **Search** – search field in the AppBar, 500 ms debounce, uses the API
   search endpoint; filters cached data when offline.
4. **Detail screen** – swipeable image gallery (PageView), title,
   description, price, discount, rating, stock, brand, category, tags and
   reviews. Hero animation from the list image.
5. **CRUD** – Add Product form (FAB) with validation; Edit and Delete
   (with confirmation dialog) on the detail screen; success/error SnackBars.
6. **Local cache (Hive)** – every fetched product is cached. Without internet
   the app shows cached data with an *"Offline mode - showing cached data"*
   banner. Local changes (added, edited, deleted) are stored in separate boxes
   and merged with API data, so refreshing never loses them.
7. **Pagination** – infinite scrolling, 10 products per page, small loader at
   the bottom and a *"No more products"* message at the end.
8. **Error handling** – separate widgets for loading (shimmer), empty, no
   internet and API failure, each with a Retry button. Dio timeouts are set.
9. **Pull to refresh** – `RefreshIndicator` fetches fresh data.
10. **Responsive UI** – list on phones, 3–4 column grid on tablets
    (`LayoutBuilder`, width > 600).

### Bonus
- Dark mode toggle (saved in Hive)
- Favorites with heart icon, saved in Hive, separate Favorites screen
- Sorting (price low→high, high→low, top rated) and category filter chips
- Debounced search, repository pattern, dependency injection with Provider
- Auto refresh when the internet comes back

---

## Packages Used

| Package | Why |
|---|---|
| [`dio`](https://pub.dev/packages/dio) | HTTP client for the REST API, with timeouts and clear error types |
| [`provider`](https://pub.dev/packages/provider) | State management (`ChangeNotifier`) and dependency injection |
| [`hive`](https://pub.dev/packages/hive) + [`hive_flutter`](https://pub.dev/packages/hive_flutter) | Fast local key-value storage for cache, local changes, favorites and settings. Products are stored as Maps (`toJson`/`fromJson`), so no code generation is needed |
| [`cached_network_image`](https://pub.dev/packages/cached_network_image) | Loads and caches product images on disk, so images also show offline |
| [`connectivity_plus`](https://pub.dev/packages/connectivity_plus) | Detects online/offline state and connection changes |

---

## Folder Structure

```
lib/
├── core/
│   ├── constants.dart        # API URL, page size, timeouts, Hive box names
│   ├── theme.dart            # Material 3 light & dark themes
│   ├── utils.dart            # AppException, formatting, SnackBar, responsive helpers
│   └── debouncer.dart        # Timer based debouncer for search
├── data/
│   ├── model/
│   │   └── product_model.dart            # Product, Review, ProductPage (+ fromJson/toJson)
│   ├── datasource/
│   │   ├── product_remote_datasource.dart # All API calls with Dio
│   │   └── product_local_datasource.dart  # All Hive reads/writes
│   └── repository/
│       └── product_repository.dart        # Merges remote data with local changes
├── presentation/
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── home_screen.dart
│   │   ├── detail_screen.dart
│   │   ├── add_edit_product_screen.dart
│   │   └── favorites_screen.dart
│   └── widgets/
│       ├── product_card.dart
│       ├── product_grid.dart      # responsive list/grid (sliver)
│       ├── product_image.dart     # cached network image with fallback
│       ├── error_view.dart
│       ├── empty_view.dart
│       ├── loading_shimmer.dart
│       └── offline_banner.dart
├── providers/
│   ├── product_provider.dart
│   └── theme_provider.dart
├── services/
│   └── connectivity_service.dart
└── main.dart
```

**Data flow:** `Screen (UI)` → `Provider` → `Repository` → `Remote (Dio)` /
`Local (Hive)` datasource. The UI never talks to Dio or Hive directly.

---

## Screenshots

> Screenshots will be added here.

| Splash | Home | Detail |
|---|---|---|
| _coming soon_ | _coming soon_ | _coming soon_ |

| Add / Edit | Favorites | Offline mode |
|---|---|---|
| _coming soon_ | _coming soon_ | _coming soon_ |

| Dark mode | Tablet grid |
|---|---|
| _coming soon_ | _coming soon_ |

---

## How to Run

**Requirements:** Flutter SDK (3.x, Dart 3.13+), Android Studio / an Android
device or emulator.

```bash
# 1. Get the code
git clone <repository-url>
cd shopora

# 2. Install packages
flutter pub get

# 3. Run on a connected device / emulator
flutter run

# 4. (Optional) Run tests and the analyzer
flutter test
flutter analyze

# 5. Build a release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

To try offline mode: open the app once with internet (so data gets cached),
then turn on airplane mode and restart the app.
