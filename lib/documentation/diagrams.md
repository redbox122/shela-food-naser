# Architecture Diagrams

## Application Architecture Overview

### High-Level Architecture

```mermaid
graph TB
    subgraph "Presentation Layer"
        UI[UI Screens & Widgets]
        Controllers[GetX Controllers]
    end
    
    subgraph "Domain Layer"
        Models[Domain Models]
        Repositories[Repository Interfaces]
        Services[Business Services]
    end
    
    subgraph "Data Layer"
        RepoImpl[Repository Implementations]
        API[API Client]
        Cache[Cache Manager]
        Local[Local Storage]
    end
    
    subgraph "External"
        Backend[Backend API]
        Firebase[Firebase Services]
        Maps[Google Maps]
    end
    
    UI --> Controllers
    Controllers --> Services
    Controllers --> Repositories
    Services --> Models
    Repositories --> RepoImpl
    RepoImpl --> API
    RepoImpl --> Cache
    RepoImpl --> Local
    API --> Backend
    Controllers --> Firebase
    Controllers --> Maps
    
    style UI fill:#e1f5ff
    style Controllers fill:#fff4e1
    style Models fill:#f0e1ff
    style Repositories fill:#f0e1ff
    style RepoImpl fill:#e1ffe1
    style API fill:#e1ffe1
```

## Module System Architecture

```mermaid
graph LR
    subgraph "Multi-Module System"
        Splash[Splash Screen]
        ModuleSelector[Module Selector]
        
        subgraph "Modules"
            Food[Food Module]
            Grocery[Grocery Module]
            Pharmacy[Pharmacy Module]
            Ecommerce[E-commerce Module]
            Parcel[Parcel Module]
            Rental[Rental Module]
        end
    end
    
    Splash --> ModuleSelector
    ModuleSelector --> Food
    ModuleSelector --> Grocery
    ModuleSelector --> Pharmacy
    ModuleSelector --> Ecommerce
    ModuleSelector --> Parcel
    ModuleSelector --> Rental
    
    Food --> Dashboard
    Grocery --> Dashboard
    Pharmacy --> Dashboard
    Ecommerce --> Dashboard
    Parcel --> Dashboard
    Rental --> Dashboard
    
    Dashboard[Dashboard/Home]
    
    style Splash fill:#ff9999
    style ModuleSelector fill:#99ccff
    style Food fill:#ffcc99
    style Grocery fill:#99ff99
    style Pharmacy fill:#ff99ff
    style Ecommerce fill:#ffff99
    style Dashboard fill:#99ffff
```

## Data Flow Architecture

```mermaid
sequenceDiagram
    participant UI as UI Screen
    participant Controller as GetX Controller
    participant Repo as Repository
    participant API as API Client
    participant Cache as Cache Manager
    participant Backend as Backend Server
    
    UI->>Controller: User Action
    Controller->>Cache: Check Cache
    
    alt Data in Cache
        Cache-->>Controller: Return Cached Data
        Controller-->>UI: Update UI (Cached)
    end
    
    Controller->>Repo: Request Data
    Repo->>API: API Call
    API->>Backend: HTTP Request
    Backend-->>API: JSON Response
    API-->>Repo: Parsed Model
    Repo->>Cache: Store in Cache
    Cache-->>Repo: Cached
    Repo-->>Controller: Return Data
    Controller-->>UI: Update UI (Fresh)
```

## Feature Module Structure

```mermaid
graph TB
    subgraph "Feature Module Example: Store"
        Screen[store_screen.dart]
        Widget[store_widget.dart]
        Controller[store_controller.dart]
        
        subgraph "Domain"
            Model[store_model.dart]
            RepoInterface[store_repository.dart]
        end
        
        subgraph "Data"
            RepoImpl[store_repo_impl.dart]
            DataSource[store_api.dart]
        end
    end
    
    Screen --> Widget
    Screen --> Controller
    Widget --> Controller
    Controller --> RepoInterface
    Controller --> Model
    RepoInterface <-. implements .-> RepoImpl
    RepoImpl --> DataSource
    RepoImpl --> Model
    
    style Screen fill:#e1f5ff
    style Widget fill:#e1f5ff
    style Controller fill:#fff4e1
    style Model fill:#f0e1ff
    style RepoInterface fill:#f0e1ff
    style RepoImpl fill:#e1ffe1
    style DataSource fill:#e1ffe1
```

## State Management Flow (GetX)

```mermaid
graph LR
    subgraph "GetX Pattern"
        View[View/Screen]
        GetBuilder[GetBuilder/Obx]
        Controller[Controller]
        Observable[Observable State]
        
        View --> GetBuilder
        GetBuilder --> Controller
        Controller --> Observable
        Observable -. Reactive Update .-> GetBuilder
        GetBuilder --> View
    end
    
    subgraph "Dependency Injection"
        Binding[Feature Binding]
        GetPut[Get.put/lazyPut]
        GetFind[Get.find]
        
        Binding --> GetPut
        GetPut --> Controller
        View --> GetFind
        GetFind --> Controller
    end
    
    style View fill:#e1f5ff
    style Controller fill:#fff4e1
    style Observable fill:#ffcccc
    style Binding fill:#ccffcc
```

## Navigation Flow

```mermaid
graph TD
    Start[App Start] --> Splash[Splash Screen]
    Splash --> CheckAuth{Authenticated?}
    
    CheckAuth -->|No| OnBoarding{First Time?}
    CheckAuth -->|Yes| CheckLocation{Location Set?}
    
    OnBoarding -->|Yes| OnBoardScreen[OnBoarding Screen]
    OnBoarding -->|No| Landing[Landing Screen]
    OnBoardScreen --> Landing
    
    Landing --> Login[Login/Register]
    Login --> Dashboard
    
    CheckLocation -->|No| LocationPicker[Location Picker]
    CheckLocation -->|Yes| Dashboard[Dashboard/Home]
    
    LocationPicker --> Dashboard
    
    Dashboard --> Stores[Browse Stores]
    Dashboard --> Categories[Browse Categories]
    Dashboard --> Search[Search]
    
    Stores --> StoreDetails[Store Details]
    Categories --> Items[Item List]
    Search --> Items
    
    StoreDetails --> ItemDetails[Item Details]
    Items --> ItemDetails
    
    ItemDetails --> Cart[Cart]
    Cart --> Checkout[Checkout]
    Checkout --> Payment[Payment]
    Payment --> OrderSuccess[Order Success]
    
    Dashboard --> Profile[Profile]
    Dashboard --> Orders[My Orders]
    Dashboard --> Wallet[Wallet]
    
    style Start fill:#90EE90
    style Splash fill:#FFE4B5
    style Dashboard fill:#87CEEB
    style Checkout fill:#FFB6C1
    style OrderSuccess fill:#98FB98
```

## API Call Manager Flow

```mermaid
graph TB
    Request[API Request] --> Manager[API Call Manager]
    Manager --> CheckCache{Cache Enabled?}
    
    CheckCache -->|Yes| CacheValid{Cache Valid?}
    CheckCache -->|No| MakeCall[Make API Call]
    
    CacheValid -->|Yes| ReturnCache[Return Cached Data]
    CacheValid -->|No| MakeCall
    
    MakeCall --> Network[Network Request]
    Network --> Success{Success?}
    
    Success -->|Yes| Parse[Parse Response]
    Success -->|No| Error[Handle Error]
    
    Parse --> Cache[Cache Response]
    Cache --> Return[Return Data]
    Error --> Return
    ReturnCache --> Return
    
    Return --> Controller[Update Controller]
    
    style Request fill:#e1f5ff
    style Manager fill:#fff4e1
    style Network fill:#e1ffe1
    style Cache fill:#ffe1f5
    style Controller fill:#fff4e1
```

## Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant UI
    participant AuthController
    participant AuthRepo
    participant API
    participant SharedPrefs
    
    User->>UI: Enter Credentials
    UI->>AuthController: login()
    AuthController->>AuthRepo: authenticate()
    AuthRepo->>API: POST /login
    API-->>AuthRepo: Token + User Data
    AuthRepo->>SharedPrefs: Save Token
    AuthRepo->>SharedPrefs: Save User Data
    SharedPrefs-->>AuthRepo: Saved
    AuthRepo-->>AuthController: Success
    AuthController-->>UI: Navigate to Home
    UI-->>User: Show Home Screen
```

## Cart & Checkout Flow

```mermaid
stateDiagram-v2
    [*] --> BrowsingItems
    BrowsingItems --> AddToCart: Add Item
    AddToCart --> CartPage: View Cart
    
    CartPage --> ModifyCart: Update Quantity
    ModifyCart --> CartPage
    
    CartPage --> Checkout: Proceed
    
    Checkout --> SelectAddress: Choose Address
    SelectAddress --> SelectPayment: Choose Payment
    SelectPayment --> ApplyCoupon: Apply Discount
    ApplyCoupon --> ReviewOrder: Review
    
    ReviewOrder --> ProcessPayment: Confirm
    ProcessPayment --> OrderPlaced: Success
    ProcessPayment --> PaymentFailed: Failed
    
    PaymentFailed --> SelectPayment: Retry
    OrderPlaced --> [*]
    
    CartPage --> BrowsingItems: Continue Shopping
```

## Location & Zone Management

```mermaid
graph TB
    Start[User Opens App] --> HasLocation{Has Saved Location?}
    
    HasLocation -->|No| RequestLocation[Request Location Permission]
    HasLocation -->|Yes| ValidateZone[Validate Zone]
    
    RequestLocation --> PickLocation[Location Picker]
    PickLocation --> GetCoordinates[Get Coordinates]
    GetCoordinates --> CheckZone[Check Zone API]
    
    CheckZone --> ZoneValid{Zone Valid?}
    
    ZoneValid -->|Yes| SaveLocation[Save Location]
    ZoneValid -->|No| ShowError[Show Zone Error]
    ShowError --> PickLocation
    
    SaveLocation --> LoadModules[Load Available Modules]
    ValidateZone --> LoadModules
    
    LoadModules --> ShowHome[Show Home Screen]
    
    style Start fill:#90EE90
    style ShowError fill:#FFB6C1
    style ShowHome fill:#87CEEB
```

## Caching Strategy

```mermaid
graph LR
    subgraph "Cache Layers"
        Memory[Memory Cache]
        Disk[Disk Cache]
        Network[Network]
    end
    
    Request[Data Request] --> Memory
    Memory --> MemHit{Cache Hit?}
    
    MemHit -->|Yes| ReturnMem[Return from Memory]
    MemHit -->|No| Disk
    
    Disk --> DiskHit{Cache Hit?}
    DiskHit -->|Yes| LoadDisk[Load from Disk]
    DiskHit -->|No| Network
    
    LoadDisk --> UpdateMem[Update Memory]
    UpdateMem --> ReturnDisk[Return from Disk]
    
    Network --> API[API Call]
    API --> StoreDisk[Store in Disk]
    StoreDisk --> UpdateMem2[Update Memory]
    UpdateMem2 --> ReturnNet[Return from Network]
    
    style Memory fill:#ffcccc
    style Disk fill:#ccffcc
    style Network fill:#ccccff
```

## Multi-Store Cart Architecture

```mermaid
graph TB
    User[User] --> Cart[Cart Manager]
    
    Cart --> Store1[Store 1 Cart]
    Cart --> Store2[Store 2 Cart]
    Cart --> StoreN[Store N Cart]
    
    Store1 --> Items1[Items List]
    Store2 --> Items2[Items List]
    StoreN --> ItemsN[Items List]
    
    Cart --> Checkout{Checkout}
    
    Checkout --> Order1[Order 1]
    Checkout --> Order2[Order 2]
    Checkout --> OrderN[Order N]
    
    Order1 --> Payment1[Payment 1]
    Order2 --> Payment2[Payment 2]
    OrderN --> PaymentN[Payment N]
    
    style Cart fill:#87CEEB
    style Checkout fill:#FFB6C1
```

## Notification System

```mermaid
sequenceDiagram
    participant FCM as Firebase Cloud Messaging
    participant App as App (Foreground/Background)
    participant NotificationService
    participant NotificationController
    participant UI
    
    FCM->>App: Push Notification
    App->>NotificationService: Handle Message
    
    alt App in Foreground
        NotificationService->>NotificationController: Update State
        NotificationController->>UI: Show In-App Notification
    else App in Background
        NotificationService->>App: Show System Notification
    end
    
    UI->>NotificationController: User Taps Notification
    NotificationController->>UI: Navigate to Relevant Screen
```

## Order Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Pending: Order Created
    Pending --> Confirmed: Store Confirms
    Pending --> Cancelled: User/Store Cancels
    
    Confirmed --> Processing: Being Prepared
    Processing --> ReadyForPickup: Ready
    
    ReadyForPickup --> DriverAssigned: Driver Assigned
    DriverAssigned --> PickedUp: Driver Picks Up
    
    PickedUp --> InTransit: On the Way
    InTransit --> Delivered: Delivered
    
    Delivered --> [*]
    Cancelled --> [*]
    
    Confirmed --> Refunded: Cancelled After Confirm
    Processing --> Refunded
    Refunded --> [*]
```
