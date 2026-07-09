# Budgex

Budgex is a Flutter personal finance app for tracking expenses, income, budgets, recurring payments, savings goals, receipts, and spending reports. It uses Supabase for authentication, database storage, and receipt uploads, while local device storage is used for app preferences such as theme mode, onboarding status, password recovery state, and security settings.

## Project Summary

Budgex helps users understand their money flow in one mobile-first app. Users can sign up, sign in, create a financial profile, add expenses and income, organize spending by category, set monthly budgets, manage recurring expenses, track savings goals, and export reports.

The project is built with:

- Flutter and Dart for the cross-platform app UI.
- Provider for state management.
- Supabase for authentication, database tables, row level security, and storage.
- Shared Preferences for lightweight local settings.
- Local Auth for PIN and biometric app lock features.
- PDF and CSV packages for export features.

## Main Features

- Email/password authentication through Supabase.
- Google OAuth support through Supabase.
- Email verification and password recovery flow.
- User profile with full name, preferred currency, and monthly budget.
- Dashboard with current spending, income, savings, category totals, and insights.
- Expense CRUD with title, amount, category, payment method, date, note, and receipt image.
- Custom expense categories.
- Income tracking with source, amount, date, and note.
- Category budgets with progress and over-budget insights.
- Recurring expenses with daily, weekly, monthly, and yearly frequencies.
- Automatic recurring expense generation logic.
- Savings goals with target amount, saved amount, target date, and completion state.
- Search and filter tools for expenses.
- CSV import for expenses.
- CSV export and preview.
- PDF report export and sharing.
- Daily, weekly, monthly, and yearly report views.
- Receipt image upload through Supabase Storage.
- Light and dark theme support.
- Onboarding screens.
- App lock with PIN and optional biometric unlock.

## Tech Stack

| Layer | Technology |
| --- | --- |
| App framework | Flutter |
| Language | Dart |
| State management | Provider |
| Backend | Supabase |
| Auth | Supabase Auth |
| Database | Supabase Postgres |
| File storage | Supabase Storage |
| Local settings | shared_preferences |
| Biometrics | local_auth |
| Exports | pdf, csv, share_plus |
| Images | image_picker |

## Project Structure

```text
lib/
  core/                 App-level helpers, navigation, Supabase config, recovery routing
  models/               Data models for expenses, categories, income, goals, profile, filters
  providers/            App state for auth, expenses, analytics, CSV, theme, and security
  screens/              Main UI screens and user workflows
  services/             Supabase, CSV, PDF, profile, finance, category, and expense services
  utils/                Theme, validators, dates, and reusable error messages
  widgets/              Reusable UI components

assets/
  fonts/                Montserrat, Manrope, BebasNeue fonts
  images/               App images, onboarding assets, logos, icons

supabase/
  complete_finance_assistant_setup.sql
                        Database schema, policies, triggers, seed categories, storage setup

test/
  widget_test.dart      Smoke and security-lock widget tests
```

## Important Files

- `lib/main.dart`: App entry point. Loads `.env`, initializes Supabase, loads theme/security preferences, and starts `BudgexApp`.
- `lib/core/supabase_config.dart`: Reads Supabase settings from `.env` with `--dart-define` fallback support.
- `lib/providers/auth_provider.dart`: Handles login, signup, logout, profile loading, password reset, and auth state.
- `lib/providers/expense_provider.dart`: Central finance state, CRUD operations, and loading/error handling.
- `lib/providers/expense_provider_analytics.dart`: Expense/income totals, category summaries, filters, and insight calculations.
- `lib/providers/expense_provider_csv.dart`: CSV import/export helpers for expenses.
- `lib/services/finance_service.dart`: Supabase operations for budgets, income, recurring expenses, savings goals, receipts, and finance data.
- `lib/services/expense_service.dart`: Supabase operations for expense CRUD.
- `lib/services/profile_service.dart`: Supabase operations for user profile data.
- `supabase/complete_finance_assistant_setup.sql`: SQL setup script for the Supabase backend.
- `.env`: Local Supabase URL, anon key, and redirect scheme. This file is ignored by Git.
- `.env.example`: Safe template for creating a local `.env` file.

## Supabase Configuration

Budgex expects these values in a `.env` file at the project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
APP_REDIRECT_SCHEME=budgex
```

The current app is configured to load `.env` as a Flutter asset in `pubspec.yaml`:

```yaml
flutter:
  assets:
      - .env
      - assets/images/
      - assets/images/google_icon.png
```

Important notes:

- `.env` is included in `.gitignore`, so each developer must create their own local `.env`.
- A Supabase anon key is safe to use in a client app when Row Level Security policies are correctly configured.
- Never place a Supabase service role key in this Flutter app.
- If `.env` is missing, Flutter can fail during build because it is listed as an asset.
- The app also supports `--dart-define` fallback values, but the preferred setup for this project is `.env`.

## Supabase Backend Setup

1. Create or open your Supabase project.
2. Open Supabase Dashboard > SQL Editor.
3. Run the SQL script from:

```text
supabase/complete_finance_assistant_setup.sql
```

This script creates or updates:

- `profiles`
- `categories`
- `expenses`
- `category_budgets`
- `incomes`
- `recurring_expenses`
- `savings_goals`
- `finance_transactions` view
- `receipts` storage bucket
- Row Level Security policies
- Updated-at triggers
- Default categories

## Auth Redirect Setup

Budgex uses this redirect URL for password recovery, email confirmation, and OAuth callbacks:

```text
budgex://login-callback/
```

Add this URL in Supabase Dashboard:

```text
Authentication > URL Configuration > Redirect URLs
```

Platform callback handlers are configured in:

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

## Environment Loading Flow

At startup, `main.dart` calls:

```dart
await SupabaseConfig.load();
```

Then, if the URL and anon key are valid, it initializes Supabase:

```dart
await Supabase.initialize(
  url: SupabaseConfig.url,
  publishableKey: SupabaseConfig.anonKey,
);
```

`SupabaseConfig.load()` is defined in `lib/core/supabase_config.dart`. If your IDE shows:

```text
The method 'load' isn't defined for the type 'SupabaseConfig'.
```

refresh the Dart analyzer after saving both `main.dart` and `supabase_config.dart`. You can also run:

```bash
flutter analyze
```

The project currently analyzes successfully with `SupabaseConfig.load()` in place.

## Data Model Overview

### profiles

Stores one profile row per Supabase auth user.

- `id`
- `full_name`
- `currency`
- `monthly_budget`
- `created_at`
- `updated_at`

### categories

Stores default and user-created spending categories.

- `id`
- `user_id`
- `name`
- `icon_name`
- `color_hex`
- `is_default`
- `created_at`

### expenses

Stores user expense records.

- `id`
- `user_id`
- `category_id`
- `title`
- `amount`
- `expense_date`
- `note`
- `payment_method`
- `receipt_url`
- `recurring_expense_id`
- `created_at`
- `updated_at`

### incomes

Stores user income records.

- `id`
- `user_id`
- `title`
- `amount`
- `income_date`
- `source`
- `note`
- `created_at`
- `updated_at`

### category_budgets

Stores monthly category limits.

- `id`
- `user_id`
- `category_id`
- `monthly_limit`
- `created_at`
- `updated_at`

### recurring_expenses

Stores repeating payment rules.

- `id`
- `user_id`
- `category_id`
- `title`
- `amount`
- `payment_method`
- `frequency`
- `next_due_date`
- `note`
- `is_active`
- `auto_post`
- `last_generated_date`
- `created_at`
- `updated_at`

### savings_goals

Stores savings targets.

- `id`
- `user_id`
- `title`
- `target_amount`
- `saved_amount`
- `target_date`
- `note`
- `is_completed`
- `created_at`
- `updated_at`

## Security

Budgex uses several safety layers:

- Supabase Row Level Security for user-owned finance data.
- Supabase Auth sessions for backend access.
- Local PIN lock for app access.
- Optional biometric unlock through `local_auth`.
- `.env` ignored by Git to avoid committing project-specific keys.

The anon key is intended for client use, but database access must always be protected by Row Level Security. Do not use a service role key in the app.

## Tests

Current tests are in:

```text
test/widget_test.dart
```

They cover:

- Project smoke test.
- Security lock screen layout with keyboard inset.
- PIN visibility toggle behavior.

Run tests with:

```bash
flutter test
```

## Common Troubleshooting

### Supabase is not configured

Make sure `.env` exists in the project root and contains:

```env
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
APP_REDIRECT_SCHEME=budgex
```

### Password recovery or OAuth does not return to the app

Make sure this redirect URL exists in Supabase Auth settings:

```text
budgex://login-callback/
```

### Flutter cannot find `.env`

Because `.env` is listed in `pubspec.yaml` assets, the file must exist before running or building the app.

### IDE still shows `SupabaseConfig.load()` error

Save `lib/core/supabase_config.dart`, restart the Dart analysis server, or run:

```bash
flutter analyze
```

The method is defined in:

```text
lib/core/supabase_config.dart
```

## How To Run The Project

1. Install Flutter and confirm your setup:

```bash
flutter doctor
```

2. Open the project folder:

```bash
cd C:\Users\ADMIN\StudioProjects\budgex
```

3. Create the `.env` file in the project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
APP_REDIRECT_SCHEME=budgex
```

4. Install dependencies:

```bash
flutter pub get
```

5. Run analyzer:

```bash
flutter analyze
```

6. Run tests:

```bash
flutter test
```

7. Check available devices:

```bash
flutter devices
```

8. Run the app:

```bash
flutter run
```

For a specific device:

```bash
flutter run -d <device-id>
```
#
