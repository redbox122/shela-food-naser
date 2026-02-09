# Application Documentation

## Overview
This is a comprehensive multi-module Flutter e-commerce application supporting various business types including Food Delivery, Grocery, Pharmacy, E-commerce, and more.

## Architecture

The application follows **Clean Architecture** principles with a clear separation of concerns:

- **Presentation Layer**: UI widgets and screens
- **Domain Layer**: Business logic and entities
- **Data Layer**: Repositories and data sources
- **Common Layer**: Shared utilities, widgets, and services

## Project Structure

```
lib/
├── api/                  # API client configuration
├── common/              # Shared components across features
├── features/            # Feature modules (Clean Architecture)
├── helper/              # Helper utilities
├── interfaces/          # Shared interfaces
├── local/               # Local data management
├── services/            # Platform services
├── theme/               # App theming
├── util/                # Utility functions
└── widgets/             # Shared widgets
```

## Key Features

### Core Features
- **Multi-Module System**: Food, Grocery, Pharmacy, E-commerce, Parcel, Rental
- **Authentication**: Login, Registration, Social Auth
- **Location Services**: Address management, Zone validation
- **Cart & Checkout**: Multi-store cart support
- **Orders**: Order tracking, history, and management
- **Payment Integration**: Multiple payment gateways
- **Search**: Advanced search with filters
- **Notifications**: Push notifications and in-app alerts

### Business Features
- **Store Management**: Browse stores by category/module
- **Item Management**: Product/Food item listings
- **Categories**: Hierarchical category system
- **Brands**: Brand-based filtering
- **Flash Sales**: Time-limited offers
- **Discounts & Coupons**: Promotional system
- **Loyalty Program**: Points and rewards
- **Refer & Earn**: Referral system
- **Wallet**: In-app wallet and subscriptions

### User Features
- **Profile Management**: User settings and preferences
- **Favorites**: Save favorite stores and items
- **Reviews**: Rating and review system
- **Chat**: In-app messaging support
- **Language**: Multi-language support
- **Onboarding**: First-time user experience

## Documentation Structure

Each section contains:
- **README.md**: Detailed explanation of the module
- **diagrams.md**: Visual architecture and flow diagrams

### Available Documentation

1. [Features Documentation](./features/README.md)
2. [Common Components](./common/README.md)
3. [Services Documentation](./services/README.md)
4. [API Documentation](./api/README.md)
5. [Utilities Documentation](./util/README.md)
6. [Architecture Diagrams](./diagrams.md)

## Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- iOS development setup (for iOS builds)

### State Management
The app uses **GetX** for:
- State management
- Dependency injection
- Route management
- Reactive programming

### Key Dependencies
- `get`: State management and navigation
- `http`: API calls
- `shared_preferences`: Local storage
- `firebase_messaging`: Push notifications
- `google_maps_flutter`: Maps integration
- `image_picker`: Image selection
- `cached_network_image`: Image caching

## Code Standards

### Clean Architecture Layers
Each feature follows this structure:
```
feature_name/
├── controllers/         # GetX controllers (Presentation)
├── screens/            # UI screens (Presentation)
├── widgets/            # Feature-specific widgets (Presentation)
├── domain/             # Business logic
│   ├── models/        # Domain entities
│   ├── repositories/  # Repository interfaces
│   └── services/      # Domain services
└── data/              # Data layer
    ├── repositories/  # Repository implementations
    └── datasources/   # API and local data sources
```

### Naming Conventions
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables**: `camelCase`
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Controllers**: `FeatureNameController`
- **Models**: `FeatureNameModel`

## Additional Resources

- [API Integration Guide](./api/README.md)
- [State Management Guide](./common/controllers/README.md)
- [Widget Library](./common/widgets/README.md)
- [Caching System](./common/cache/README.md)
- [Security Implementation](./common/security/README.md)

## Contributing

When adding new features:
1. Follow Clean Architecture principles
2. Create appropriate documentation
3. Add Mermaid diagrams for complex flows
4. Update this index

## Support

For issues and questions, refer to the specific feature documentation or contact the development team.
