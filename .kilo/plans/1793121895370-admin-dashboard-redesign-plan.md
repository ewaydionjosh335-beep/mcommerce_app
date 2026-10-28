# Admin Dashboard Redesign Plan ("Chopify" M-Commerce App)

## 1. Goal
Redesign the admin side of the Flutter + Firebase e-commerce app ("Chopify") to look modern, clean, and professional while strictly preserving all existing business logic, Firestore queries, streams, providers, models, and features.

## 2. Design System (`app_theme.dart`)
- **Typography**: Integrate `google_fonts` (using **Plus Jakarta Sans** for headings and **Inter** for body text) across a complete Material 3 `TextTheme`.
- **Color Palette**:
  - **Light Mode**:
    - Primary: Indigo/Slate Blue (`#4F46E5`)
    - Secondary: Coral/Amber (`#FF6B6B`)
    - Background: Light Neutral (`#F8FAFC`)
    - Surface / Cards: Pure White (`#FFFFFF`) with subtle borders (`#E2E8F0`)
    - Text: Dark Slate (`#0F172A`) for primary, Muted Gray (`#64748B`) for secondary
  - **Dark Mode**:
    - Primary: Lighter Indigo (`#6366F1`)
    - Secondary: Coral (`#FF8E53`)
    - Background: Deep Slate (`#0F172A`)
    - Surface / Cards: Dark Surface (`#1E293B`) with subtle dark borders (`#334155`)
    - Text: Off-White (`#F8FAFC`) for primary, Muted Light Gray (`#94A3B8`) for secondary
  - **Status & Semantic Colors**:
    - Success (Delivered / Active): `#10B981` (Emerald)
    - Warning (Pending / Low Stock): `#F59E0B` (Amber)
    - Info (Processing): `#3B82F6` (Blue)
    - Purple (Shipped): `#8B5CF6` (Violet)
    - Danger (Cancelled / Out of Stock): `#EF4444` (Red)
- **Spacing & Elevation**:
  - Extend `AppSpacing`: `s4 (4)`, `s8 (8)`, `s12 (12)`, `s16 (16)`, `s20 (20)`, `s24 (24)`, `s32 (32)`.
  - Border radius: Uniform `12px` or `16px` for cards, dialogs, inputs, and buttons.
  - Subtle shadows and borders instead of heavy elevation.

## 3. Reusable UI Components (`lib/widgets/`)
- `PageHeader`: Consistent header component for sections with title, subtitle, and primary/secondary action buttons positioned top-right.
- `StatCard`: Modern analytics card with icon badge, large metric display, label, and trend indicator.
- `StatusChip`: Pill-shaped badge for order statuses, stock levels, and user roles.
- `AdminButton`: Unified button styling (Filled, Outlined, Destructive) ensuring minimum 48px touch targets and consistent padding.

## 4. Layout & Sidebar Refinement (`admin_dashboard.dart`)
- **Sidebar**:
  - Clean brand header with icon and "Chopify Admin" title.
  - Navigation items with rounded active indicator pills, smooth hover/selection states.
  - Grouped bottom section containing Dark Mode toggle switch and Logout action.
- **Responsive Handling**:
  - Permanent sidebar on screens >= 800px.
  - Responsive Drawer on narrow screens with AppBar title.
  - Clean content padding and responsive grid layouts for dashboard metrics.

## 5. Section Refactoring (Maintaining Logic & Streams)
- **Analytics Dashboard**: Modern responsive grid of `StatCard` widgets and clean charts/metrics.
- **Product Management & Inventory**: Clean table/list layouts with aligned columns, search/filter bars, status badges, and neatly arranged action buttons.
- **Orders & Users & Notifications**: Consistent card/table layouts, clear status chips, and polished modal dialogs for add/edit/view flows.

## 6. Validation Plan
- Verify package addition (`google_fonts`) in `pubspec.yaml`.
- Run `flutter analyze` and test build to ensure zero compile errors or linter warnings.
- Confirm both light and dark modes function correctly.
