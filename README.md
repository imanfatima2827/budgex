# Budgex

Budgex is a Flutter personal finance app that helps users track expenses, income, budgets, recurring payments, savings goals, and financial reports. It uses Supabase for authentication, database, and file storage.

## Features

- Email & Google Sign-In
- Expense and income tracking
- Budget management
- Savings goals
- Recurring expenses
- PDF & CSV export
- Receipt image upload
- Light & Dark theme
- PIN & Biometric app lock

## Tech Stack

- Flutter & Dart
- Provider
- Supabase
- Shared Preferences
- Local Auth

## Getting Started

1. Clone the repository.
2. Create a `.env` file in the project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
APP_REDIRECT_SCHEME=budgex
```

3. Install dependencies:

```bash
flutter pub get
```

4. Run the app:

```bash
flutter run
```

## Project Structure

```text
lib/
assets/
supabase/
test/
```

## Supabase Setup

Run the SQL script:

```text
supabase/complete_finance_assistant_setup.sql
```

in the Supabase SQL Editor.

## Security

- Supabase Authentication
- Row Level Security (RLS)
- Secure environment variables
- PIN & Biometric authentication

## License

This project is for educational and personal use.
