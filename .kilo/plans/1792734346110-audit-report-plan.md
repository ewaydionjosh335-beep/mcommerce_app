# M-Commerce App Architecture & Codebase Audit Report

## 1. Environment & Build Validation (`flutter pub get`, `flutter analyze`, `flutter test`)
*Note: Due to sandboxed execution restrictions preventing direct CLI tool invocation (`flutter`), static code analysis and test suite review were performed across the entire codebase.*

- **`flutter pub get` / Dependencies:** Dependencies in `pubspec.yaml` (`firebase_core: ^4.15.0`, `firebase_auth: ^6.7.0`, `cloud_firestore: ^6.10.0`, `provider: ^6.1.5+1`) are correctly declared and locked.
- **`flutter analyzer` / Static Analysis:** Code adheres to standard lints (`flutter_lints ^6.0.0`), but static code review identified several potential runtime issues, race conditions, type mismatches, and architectural anti-patterns detailed below.
- **`flutter test` / Test Suite:** The default test file `test/widget_test.dart` runs counter increments testing against `CounterApp`, but the project root widget is `MyApp()` (Chopify mcommerce app). Consequently, running `flutter test` currently fails because the counter widget tree is absent.

---

## 2. Comprehensive Audit Report (lib/)

### Crashes / Exceptions / Unhandled Null or Network Cases
1. **High** | `lib/providers/wishlist_provider.dart:51` | Asynchronous `Future.wait` inside Firestore snapshot listener can cause out-of-order state updates or race conditions when user switches accounts rapidly. | Cancel previous pending async fetch or use query snapshots with data directly rather than fetching individual document references.
2. **Med** | `lib/admin/orders_section.dart:237` | Unhandled future lookup of user doc without timeout handling if network fails when resolving customer name. | Wrap `_resolve` in try/catch with robust fallback and timeout.
3. **Med** | `lib/user/profile_screen.dart:57` | Potential type cast exception if user profile document fields (`phone`, `address`) are stored as non-String types in Firestore. | Safely cast using `data['phone']?.toString() ?? ''`.

### Logic Bugs (Cart, Checkout, Stock, Cancel/Restock, Notifications, Reviews)
1. **High** | `lib/user/checkout_screen.dart:148` | Stock deduction (`currentStock - item.quantity`) is performed outside a transaction, risking negative inventory or race conditions under concurrent checkouts. | Wrap stock updates and order creation in a Firestore transaction (`_db.runTransaction`).
2. **Med** | `lib/admin/orders_section.dart:60` & `lib/user/my_orders_screen.dart:57` | Order cancellation restocks items without tracking previous state transitions, allowing potential double-restocking if order status is updated repeatedly. | Track previous status transition and only restock if transitioning to 'cancelled' from a non-cancelled state.
3. **Med** | `lib/user/product_reviews_section.dart:33` | Review eligibility check queries all user orders without pagination or composite index, risking query failure or performance degradation. | Optimize query or catch Firestore index errors gracefully with fallback messaging.

### UI Overflow / Overlap Risks
1. **High** | `lib/admin/users_section.dart:194` | `CustomerDetailsDialog` has fixed height (`460`) and width (`500`), causing vertical overflow on mobile screens or when customer order history is extensive. | Replace fixed height with responsive constraints (`maxHeight: MediaQuery.of(context).size.height * 0.8`) and scrollable body.
2. **Med** | `lib/admin/product_management.dart:98` | Product form dialog uses a fixed width (`420`) without responsive adaptation for narrow screens. | Use responsive `ConstrainedBox` with max width percentage.
3. **Med** | `lib/admin/orders_section.dart:160` | `ConstrainedBox` with maxWidth 280 in orders table items column may overflow horizontally on narrow displays. | Wrap text cells in flexible containers or adjust table column widths.

### Dark Mode Issues
1. **High** | `lib/admin/admin_dashboard.dart:103` & `lib/user/profile_screen.dart:200` | Hardcoded `Colors.white`, `Colors.white70`, `Colors.grey.shade50`, and white backgrounds across multiple screens (`CheckoutScreen`, `CartScreen`, `ProductManagement`, `ProductCard`) do not adapt to dark mode, resulting in blinding white cards or invisible text. | Replace hardcoded white/grey colors with `Theme.of(context).colorScheme.surface` and `onSurface`.
2. **Med** | `lib/user/product_details_screen.dart:125` | Bottom sheet container has hardcoded `backgroundColor: Colors.white`, clashing with dark theme. | Use `Theme.of(context).cardColor` or `colorScheme.surface`.

### Flow Gaps
1. **High** | `lib/user/home_screen.dart:305` | Guest users clicking protected tabs (Cart, Wishlist, Orders, Profile) see empty/guest placeholders instead of an immediate login modal redirect. | Intercept tab selection for guests on protected tabs to invoke login modal directly.
2. **Med** | `lib/user/checkout_screen.dart:182` | Post-checkout navigation pops to `CartScreen` (which is now empty) rather than routing to `MyOrdersScreen` or order success confirmation. | Navigate to `MyOrdersScreen` upon successful checkout completion.
3. **Med** | `test/widget_test.dart:14` | Default template test suite tests counter app instead of `MyApp()` and mcommerce features, causing test suite failure. | Update `widget_test.dart` to test `MyApp()` and smoke test product loading/navigation.

### Code Quality
1. **High** | `lib/user/home_screen.dart` (424 lines) & `lib/admin/users_section.dart` (356 lines) & `lib/user/product_reviews_section.dart` (392 lines) | Files exceed the 300 lines limit, tightly coupling UI building, business logic, and multiple StreamBuilders. | Extract dialogs and sub-widgets into dedicated files under `lib/widgets/` or feature directories.
2. **High** | `lib/widgets/product_card.dart:123` & `lib/admin/orders_section.dart:237` & `lib/user/product_reviews_section.dart:186` | Direct Firestore queries (`FirebaseFirestore.instance.collection(...)`) inside widget build methods (`StreamBuilder` / `FutureBuilder`), causing re-query storms and tight database coupling. | Migrate database queries into services or providers (`ProductService`, `CartProvider`, `WishlistProvider`).
3. **Med** | `lib/admin/orders_section.dart` & `lib/user/my_orders_screen.dart` | Duplicated order cancellation and restock logic across admin and user sections. | Centralize order operations and restock logic into an `OrderService`.

---

## 3. Proposed Fix Order & Decisions

### Phase 1: Critical Crashes, Security & Flow Gaps
1. Wrap checkout stock deduction and order creation in a Firestore transaction (`_db.runTransaction`) in `CheckoutScreen`.
2. Fix post-checkout navigation to route users to `MyOrdersScreen`.
3. Fix guest tab navigation gating in `HomeScreen`.
4. Update `widget_test.dart` to test `MyApp()` successfully.

### Phase 2: Logic Bugs & Data Integrity
1. Implement idempotent order cancellation status checking to prevent double-restocking.
2. Secure `WishlistProvider` snapshot listener against async race conditions.
3. Add robust type casting validation for user profile fields.

### Phase 3: UI Overflows & Dark Mode Compliance
1. Replace hardcoded `Colors.white`, `Colors.white70`, and light grey container backgrounds with `Theme.of(context)` surface and color schemes across all screens.
2. Fix dialog height and width constraints (`CustomerDetailsDialog`, product management form).

### Phase 4: Code Quality & Architecture Refactoring
1. Extract Firestore queries out of widget build methods into service classes.
2. Refactor files exceeding 300 lines (`home_screen.dart`, `users_section.dart`, `product_reviews_section.dart`) into modular components.
3. Centralize shared order/restock logic into `OrderService`.
