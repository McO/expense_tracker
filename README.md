# Expense Tracker

A modern Flutter Android app for managing personal expenses with beautiful UI, multi-currency support, and intuitive user experience.

## Features

### 📊 Dashboard Overview
- **Total Expenses**: View your overall spending at a glance with automatic currency detection
- **Category Breakdown**: Visual representation of spending by category with progress bars
- **Recent Expenses**: Quick access to your latest transactions with proper currency display

### 💰 Expense Management
- **Add Expenses**: Easy-to-use form with validation
- **Edit Expenses**: Modify existing expenses with pre-populated data
- **Delete Expenses**: Remove expenses with confirmation dialogs
- **Multi-Currency Support**: Choose from 15 different currencies for each expense:
  - 🇺🇸 USD (US Dollar)
  - 🇪🇺 EUR (Euro)
  - 🇬🇧 GBP (British Pound)
  - 🇯🇵 JPY (Japanese Yen)
  - 🇨🇦 CAD (Canadian Dollar)
  - 🇦🇺 AUD (Australian Dollar)
  - 🇨🇭 CHF (Swiss Franc)
  - 🇨🇳 CNY (Chinese Yuan)
  - 🇮🇳 INR (Indian Rupee)
  - 🇰🇷 KRW (South Korean Won)
  - 🇧🇷 BRL (Brazilian Real)
  - 🇷🇺 RUB (Russian Ruble)
  - 🇲🇽 MXN (Mexican Peso)
  - 🇸🇬 SGD (Singapore Dollar)
  - 🇳🇿 NZD (New Zealand Dollar)
- **Categories**: 9 predefined categories with emojis:
  - 🍽️ Food
  - 🚗 Transportation  
  - 🛒 Shopping
  - 🎬 Entertainment
  - 💡 Bills
  - 💊 Health
  - 📚 Education
  - ✈️ Travel
  - 📋 Other

### 📱 User Interface
- **Material Design 3**: Modern, clean interface
- **Animations**: Smooth transitions and staggered animations
- **Dark/Light Theme**: Follows system theme preferences
- **Search & Filter**: Find expenses quickly by title, description, or category
- **Currency Display**: Proper currency symbols and formatting for all supported currencies

### 🔍 Expense List
- **Search Functionality**: Search through expenses by title or description
- **Category Filtering**: Filter expenses by specific categories
- **Sort by Date**: Expenses sorted by most recent first
- **Edit Options**: Quick access to edit expenses from list view
- **Delete Options**: Remove expenses with confirmation dialog
- **Multi-Currency Display**: Each expense shows with its respective currency

### 📋 Expense Details
- **Full Information**: View complete expense details
- **Edit Button**: Quick access to edit expense from detail view
- **Additional Metadata**: See expense ID, day of week, and time added
- **Currency Information**: Displays amount with proper currency symbol

### ⚙️ Settings
- **Default Currency**: Set your preferred currency for new expenses
- **Currency Information**: View details about selected currency
- **Quick Access**: Settings accessible from home screen

### 💾 Data Persistence
- **Local Storage**: Uses SharedPreferences for data persistence
- **JSON Serialization**: Efficient data storage and retrieval with currency support
- **Data Validation**: Ensures data integrity with currency validation

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio with Android SDK
- Android device or emulator

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd expense_tracker
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

### Building for Android

**Debug APK:**
```bash
flutter build apk --debug
```

**Release APK:**
```bash
flutter build apk --release
```

## Project Structure

```
lib/
├── main.dart                     # App entry point
├── models/
│   ├── expense.dart             # Expense model and categories
│   └── currency.dart            # Currency model with 15 currencies
├── services/
│   ├── expense_service.dart     # Data persistence service
│   └── settings_service.dart    # Settings management
└── screens/
    ├── home_screen.dart         # Dashboard/Home screen
    ├── add_expense_screen.dart  # Add new expense form
    ├── edit_expense_screen.dart # Edit existing expense form
    ├── expenses_list_screen.dart # All expenses list with search
    ├── expense_detail_screen.dart # Individual expense details
    └── settings_screen.dart     # Currency settings
```

## Dependencies

- **shared_preferences**: ^2.2.2 - Local data storage
- **intl**: ^0.19.0 - Date formatting and internationalization
- **flutter_staggered_animations**: ^1.1.1 - Beautiful animations

## Features in Detail

### Home Screen
- Displays total expenses with automatic currency detection
- Shows category breakdown with visual progress indicators
- Lists recent expenses with proper currency formatting
- Pull-to-refresh functionality
- Floating action button for quick expense addition
- Settings access via app bar

### Add Expense Screen
- Form validation for all required fields
- Currency selection dropdown with all 15 supported currencies
- Default currency loaded from user settings
- Date picker for expense date selection
- Category selection with visual chips
- Description field (optional)
- Loading states and error handling

### Edit Expense Screen
- Pre-populated form with existing expense data including currency
- Same validation and UI as add expense screen
- Shows original expense information for reference
- Currency selection with current currency pre-selected
- Updates expense data while maintaining ID consistency
- Loading states and error handling

### Expenses List Screen
- Real-time search functionality
- Category-based filtering
- Currency-aware display for each expense
- Swipe-to-refresh
- Edit and delete options in context menu
- Empty state handling

### Settings Screen
- Default currency selection with dropdown
- Currency information display
- Real-time currency updates
- User-friendly currency selection with symbols and names

### Data Management
- Automatic expense ID generation
- Currency-aware JSON serialization
- Error handling for storage operations
- Data validation and type safety
- Migration support for existing data

## Multi-Currency Features

### Supported Currencies
The app supports 15 major world currencies with proper symbols:
- **USD** ($) - US Dollar
- **EUR** (€) - Euro
- **GBP** (£) - British Pound
- **JPY** (¥) - Japanese Yen
- **CAD** (C$) - Canadian Dollar
- **AUD** (A$) - Australian Dollar
- **CHF** (CHF) - Swiss Franc
- **CNY** (¥) - Chinese Yuan
- **INR** (₹) - Indian Rupee
- **KRW** (₩) - South Korean Won
- **BRL** (R$) - Brazilian Real
- **RUB** (₽) - Russian Ruble
- **MXN** ($) - Mexican Peso
- **SGD** (S$) - Singapore Dollar
- **NZD** (NZ$) - New Zealand Dollar

### Currency Management
- **Default Currency**: Set in settings for new expenses
- **Per-Expense Currency**: Each expense can have its own currency
- **Smart Totals**: Home screen intelligently handles multiple currencies
- **Proper Formatting**: Each currency displays with correct symbol and formatting

## Customization

### Adding New Categories
To add new expense categories, modify the `ExpenseCategory` enum in `lib/models/expense.dart`:

```dart
enum ExpenseCategory {
  // existing categories...
  newCategory('New Category', '🆕'),
}
```

### Adding New Currencies
To add new currencies, modify the `Currency` enum in `lib/models/currency.dart`:

```dart
enum Currency {
  // existing currencies...
  newCurrency('CODE', 'SYMBOL', 'Full Name'),
}
```

### Changing Theme Colors
Modify the `seedColor` in `lib/main.dart`:

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF6366F1), // Change this color
),
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Screenshots

> Screenshots would go here showing the app in action with different currencies

## Support

For support or questions, please open an issue in the repository.

---

**Built with ❤️ using Flutter**

