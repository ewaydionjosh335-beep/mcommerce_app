# Project Audit & Debug Plan (Chopify M-Commerce & Admin)

This document outlines the complete architectural mapping, static analysis findings, performance risks, flow integrity checks, and responsiveness evaluation for the Flutter + Firebase m-commerce application (Mobile & Admin sides).

---

## Project Structure & Architecture Mapping

### 1. Mobile Screens
- **HomeScreen** (`lib/user/home_screen.dart`): Main landing page with category choice chips, search bar, sort dropdown, promotional banner, and bottom navigation bar (Home, Wishlist, Cart, Orders, Profile). Supports Guest mode.
- **CartScreen** (`lib/user/cart_screen.dart`): Shopping cart items list, quantity increaser/decreaser, item removal, total amount calculation, and checkout trigger.
- **WishlistScreen** (`lib/user/wishlist_screen.dart`): User saved wishlist items backed by Firestore subcollection, direct add-to-cart or remove actions.
- **MyOrdersScreen** (`lib/user/my_orders_screen.dart`): Real-time stream of user orders, status badges, order items summary, delivery address, payment method, and cancel order capability.
- **ProfileScreen** (`lib/user/profile_screen.dart`): Customer account profile form (name, phone, default delivery address), dark mode toggle, profile saving, and logout.
- **ProductDetailsScreen** (`lib/user/product_details_screen.dart`): Product image gallery (Hero), price, stock status, interactive size selector chips, description, customer reviews section, and bottom sheet action bar ("Add to Cart" & "Buy Now").
- **NotificationsScreen** (`lib/user/notifications_screen.dart`): User notifications and admin broadcast messages stream with read status tracking and dismissal.
- **CheckoutScreen** (`lib/user/checkout_screen.dart`): Shipping address input, phone number, order notes, payment method selector (COD, GCash, Card, Maya), real-time stock/price validation against Firestore, and order placement.
- **LoginScreen** (`lib/screens/login_screen.dart`): Email/password authentication modal or full-screen view with error handling and automatic role-based routing (Admin vs User).
- **RegisterScreen** (`lib/screens/register_screen.dart`): New account creation form with validation and Firestore `users` document initialization.

### 2. Admin Screens & Sections
- **AdminDashboard** (`lib/admin/admin_dashboard.dart`): Responsive admin shell featuring a persistent sidebar for wide screens (desktop/tablet) and a drawer for narrow screens, dark mode toggle, logout, and tab switching.
- **AnalyticsDashboardSection** (`lib/admin/analytics_dashboard_section.dart`): Real-time metrics overview (Total Revenue, Total Orders, Products in Catalog, Registered Users) and Order Status Breakdown.
- **ProductManagement** (`lib/admin/product_management.dart`): Product catalog data table with CRUD operations (Add, Edit, Delete) and size/stock management dialogs.
- **InventorySection** (`lib/admin/inventory_section.dart`): Stock level monitoring, low-stock filter toggle, and quick restock buttons (+10, +50, custom quantity).
- **OrdersSection** (`lib/admin/orders_section.dart`): Comprehensive orders table with customer name resolution, items summary, total amount, and interactive status update popup menu.
- **UsersSection** (`lib/admin/users_section.dart`): Registered user base monitoring, search by name/email, and customer inspection dialog with profile details and order history.
- **NotificationsSection** (`lib/admin/notifications_section.dart`): Promotional broadcast notification sender for all users and live view of admin out-of-stock / system alerts.

### 3. Navigation & Routing Setup
- **Routing**: No named routes (`routes` map) are registered in `MaterialApp`. Navigation relies entirely on imperative API (`Navigator.push`, `Navigator.pushReplacement`, `Navigator.pop`). Tab switching within `HomeScreen` and `AdminDashboard` is state-driven via local integer indices (`_currentIndex` / `_index`).
- **Modals**: Authentication flows utilize static helper methods (`LoginScreen.showAsModal`, `RegisterScreen.showAsModal`).

### 4. Firebase Services Used
- **Firebase Core** (`firebase_core`): Initialization in `main.dart` with platform-specific options (`firebase_options.dart`).
- **Firebase Authentication** (`firebase_auth`): Email/password sign-in, sign-up, sign-out, and auth state change listeners.
- **Cloud Firestore** (`cloud_firestore`): Real-time streams and documents for collections: `products`, `orders`, `users`, `notifications`, `reviews`, and user subcollection `users/{uid}/wishlist`.

---

## Comprehensive Checklist & Action Plan (DEBUG_PLAN.md)

### Phase 1: Build errors and analyzer issues
- [x] **File:** `lib/user/home_screen.dart` (Line 303, 304)  
  *Problem:* Unnecessary widget watch calls inside build when user is guest (`context.watch<CartProvider>()`).  
  *Proposed Fix:* Guard provider watches behind `isGuest ? 0 : ...` or use `Provider.of<CartProvider>(context, listen: false)` where appropriate to prevent unnecessary rebuilds.
- [x] **File:** `lib/admin/analytics_dashboard_section.dart` (Lines 13-21)  
  *Problem:* Nested `StreamBuilder` widgets (orders, products, users) creating deep callback indentation and triple stream subscriptions without unified error handling.  
  *Proposed Fix:* Combine streams into a single ViewModel/Combined Future or separate independent section widgets with proper `AsyncStateView`.

### Phase 2: Performance / slow tap response
- [x] **File:** `lib/user/home_screen.dart` (Lines 61-95)  
  *Problem:* Filtering, searching, and sorting the entire product stream inside `StreamBuilder.builder` on every snapshot event on the main thread.  
  *Proposed Fix:* Move filtering and sorting logic into a dedicated Notifier or debounce search input queries to prevent UI jank during typing.
- [x] **File:** `lib/admin/orders_section.dart` (Lines 197-214)  
  *Problem:* `_CustomerName` widget performs an asynchronous `Firestore.get()` call inside a stateless widget builder (`FutureBuilder`), causing potential duplicate reads per row render.  
  *Proposed Fix:* Denormalize `customerName` into the order document at checkout (already partially done) and eliminate individual `FutureBuilder` lookups in DataTable rows.
- [x] **File:** `lib/admin/notifications_section.dart` (Lines 167-173)  
  *Problem:* `ListView.builder` nested inside `SingleChildScrollView` with `shrinkWrap: true` and `physics: NeverScrollableScrollPhysics()`.  
  *Proposed Fix:* Convert the parent layout to a custom sliver scroll view or use proper sliver lists.

### Phase 3: Page loading and navigation
- [x] **File:** `lib/admin/users_section.dart` (Lines 155-175)  
  *Problem:* `CustomerDetailsDialog` order history `StreamBuilder` only checks `!snapshot.hasData ? LinearProgressIndicator() : ...` without error or empty state handling.  
  *Proposed Fix:* Wrap order history in `AsyncStateView` handling both `snapshot.hasError` and empty docs.
- [x] **File:** `lib/screens/login_screen.dart` (Lines 78-81)  
  *Problem:* Role lookup query on `users/{uid}` during login lacks explicit timeout handling, which can hang the loading indicator if Firestore rules or network stall.  
  *Proposed Fix:* Add a `.timeout(const Duration(seconds: 10))` with fallback handling.

### Phase 4: Mobile flows and dead buttons
- [x] **File:** `lib/user/product_details_screen.dart` (Lines 209-218)
  *Problem:* Out of stock button correctly has `onPressed: null`, but UI feedback when attempting to select out-of-stock sizes is minimal.  
  *Proposed Fix:* Add a helper tooltip or snackbar when tapping disabled out-of-stock size chips explaining stock status.
- [x] **File:** `lib/user/my_orders_screen.dart` (Lines 266-281)  
  *Problem:* Order cancellation restores stock but does not invalidate or refresh local UI optimistically before stream update arrives.  
  *Proposed Fix:* Provide immediate UI state feedback during cancellation transaction execution.

### Phase 5: Admin flows and dead buttons
- [x] **File:** `lib/admin/product_management.dart` (Lines 113-156)  
  *Problem:* Add size dialog inside product form instantiates controllers without disposal tracking inside the dialog state.  
  *Proposed Fix:* Properly dispose temporary text controllers in dialog lifecycle or use state variables.
- [x] **File:** `lib/admin/orders_section.dart` (Lines 157-171)  
  *Problem:* Status update popup menu items trigger immediate Firestore writes without confirmation dialog for critical status changes (e.g. delivered or cancelled).  
  *Proposed Fix:* Add a confirmation dialog before executing status updates for destructive/final states like cancelled.

### Phase 6: Responsiveness (admin + mobile)
- [x] **File:** `lib/user/cart_screen.dart` & `WishlistScreen.dart`  
  *Problem:* Mobile lists and grids assume portrait phone viewports; on wide tablet screens or desktop, items stretch horizontally without max-width constraints.  
  *Proposed Fix:* Wrap content in `Center` with `ConstrainedBox(constraints: BoxConstraints(maxWidth: 600))` for tablet/desktop layouts.
- [x] **File:** `lib/admin/product_management.dart` & `OrdersSection.dart`  
  *Problem:* DataTables inside `SingleChildScrollView(scrollDirection: Axis.horizontal)` force horizontal scrolling on narrower admin screens.  
  *Proposed Fix:* Implement responsive column visibility or card-based list views for smaller admin viewports.
