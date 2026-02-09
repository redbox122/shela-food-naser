# Features Architecture Diagrams

## Feature Module Flow Diagrams

### Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant LoginScreen
    participant AuthController
    participant AuthRepo
    participant API
    participant SharedPrefs
    participant Dashboard
    
    User->>LoginScreen: Enter credentials
    LoginScreen->>AuthController: login(email, password)
    AuthController->>AuthController: Set loading state
    AuthController->>AuthRepo: authenticate()
    AuthRepo->>API: POST /customer/auth/login
    
    alt Success
        API-->>AuthRepo: {token, user_data}
        AuthRepo->>SharedPrefs: Save token
        AuthRepo->>SharedPrefs: Save user data
        AuthRepo-->>AuthController: Success(user)
        AuthController->>AuthController: Update user state
        AuthController->>Dashboard: Navigate to home
        Dashboard-->>User: Show home screen
    else Error
        API-->>AuthRepo: Error response
        AuthRepo-->>AuthController: Error(message)
        AuthController->>LoginScreen: Show error
        LoginScreen-->>User: Display error message
    end
```

### Store & Item Browsing Flow

```mermaid
graph TB
    Home[Home Screen] --> StoreList[Store List]
    Home --> CategoryList[Category List]
    
    StoreList --> StoreFilter{Apply Filters?}
    StoreFilter -->|Yes| FilteredStores[Filtered Store List]
    StoreFilter -->|No| AllStores[All Stores]
    
    FilteredStores --> StoreDetails[Store Details Screen]
    AllStores --> StoreDetails
    
    CategoryList --> CategoryItems[Category Items]
    
    StoreDetails --> Categories[Store Categories]
    Categories --> Items[Item List]
    CategoryItems --> Items
    
    Items --> ItemDetails[Item Details Screen]
    ItemDetails --> Variants{Has Variants?}
    
    Variants -->|Yes| SelectVariant[Select Variant/Addon]
    Variants -->|No| AddToCart[Add to Cart]
    
    SelectVariant --> AddToCart
    AddToCart --> Cart[Cart Screen]
    
    style Home fill:#87CEEB
    style StoreDetails fill:#FFE4B5
    style ItemDetails fill:#FFB6C1
    style Cart fill:#90EE90
```

### Shopping Cart Flow

```mermaid
stateDiagram-v2
    [*] --> EmptyCart
    EmptyCart --> ItemAdded: Add First Item
    
    ItemAdded --> SingleStore
    SingleStore --> MultiStore: Add Item from Different Store
    SingleStore --> SingleStore: Add More Items
    
    MultiStore --> MultiStore: Add More Items
    
    SingleStore --> UpdateQuantity: Change Quantity
    MultiStore --> UpdateQuantity: Change Quantity
    UpdateQuantity --> SingleStore
    UpdateQuantity --> MultiStore
    
    SingleStore --> RemoveItem: Remove Item
    MultiStore --> RemoveItem: Remove Item
    
    RemoveItem --> EmptyCart: All Items Removed
    RemoveItem --> SingleStore: Items Remain
    RemoveItem --> MultiStore: Items Remain
    
    SingleStore --> Checkout: Proceed to Checkout
    MultiStore --> MultiCheckout: Checkout Multiple Orders
    
    Checkout --> [*]
    MultiCheckout --> [*]
```

### Order Placement Flow

```mermaid
sequenceDiagram
    participant User
    participant CartScreen
    participant CheckoutScreen
    participant AddressSelector
    participant PaymentSelector
    participant OrderController
    participant OrderRepo
    participant PaymentGateway
    participant API
    
    User->>CartScreen: Click Checkout
    CartScreen->>CheckoutScreen: Navigate
    
    CheckoutScreen->>AddressSelector: Select Delivery Address
    User->>AddressSelector: Choose/Add Address
    AddressSelector-->>CheckoutScreen: Address Selected
    
    CheckoutScreen->>User: Choose Delivery Time
    User->>CheckoutScreen: Select Time Slot
    
    CheckoutScreen->>PaymentSelector: Select Payment Method
    User->>PaymentSelector: Choose Payment
    PaymentSelector-->>CheckoutScreen: Payment Method Selected
    
    User->>CheckoutScreen: Place Order
    CheckoutScreen->>OrderController: createOrder()
    OrderController->>OrderRepo: placeOrder(orderData)
    
    alt Online Payment
        OrderRepo->>PaymentGateway: Initialize Payment
        PaymentGateway-->>User: Show Payment UI
        User->>PaymentGateway: Complete Payment
        PaymentGateway-->>OrderRepo: Payment Success
    else COD/Wallet
        OrderRepo->>API: POST /customer/order/place
    end
    
    API-->>OrderRepo: Order Created
    OrderRepo-->>OrderController: Success(orderId)
    OrderController->>OrderController: Clear Cart
    OrderController->>User: Navigate to Order Success
```

### Search Feature Flow

```mermaid
graph TB
    SearchBar[Search Bar] --> InputQuery[User Input Query]
    InputQuery --> Debounce[Debounce 500ms]
    
    Debounce --> SearchAPI[Call Search API]
    SearchAPI --> SearchType{Search Type}
    
    SearchType -->|Stores| StoreResults[Store Search Results]
    SearchType -->|Items| ItemResults[Item Search Results]
    SearchType -->|Both| CombinedResults[Combined Results]
    
    StoreResults --> DisplayStores[Display Store List]
    ItemResults --> DisplayItems[Display Item List]
    CombinedResults --> DisplayTabs[Display Tabs: Stores/Items]
    
    DisplayStores --> StoreDetails[Navigate to Store]
    DisplayItems --> ItemDetails[Navigate to Item]
    DisplayTabs --> StoreDetails
    DisplayTabs --> ItemDetails
    
    SearchBar --> RecentSearches[Show Recent Searches]
    SearchBar --> PopularSearches[Show Popular Searches]
    RecentSearches --> InputQuery
    PopularSearches --> InputQuery
    
    style SearchBar fill:#87CEEB
    style DisplayStores fill:#FFE4B5
    style DisplayItems fill:#FFB6C1
```

### Location & Address Management

```mermaid
graph TD
    AppStart[App Start] --> CheckLocation{Has Saved Location?}
    
    CheckLocation -->|No| RequestPermission[Request Location Permission]
    CheckLocation -->|Yes| ValidateZone[Validate Zone]
    
    RequestPermission --> PermissionGranted{Permission Granted?}
    
    PermissionGranted -->|Yes| ShowMap[Show Google Maps]
    PermissionGranted -->|No| ManualEntry[Manual Address Entry]
    
    ShowMap --> UserSelectsLocation[User Selects Location]
    ManualEntry --> UserEntersAddress[User Enters Address]
    
    UserSelectsLocation --> GetCoordinates[Get Lat/Lng]
    UserEntersAddress --> GeocodeAddress[Geocode Address]
    
    GetCoordinates --> CheckZoneAPI[Check Zone API]
    GeocodeAddress --> CheckZoneAPI
    
    CheckZoneAPI --> InZone{In Service Zone?}
    
    InZone -->|Yes| SaveAddress[Save Address]
    InZone -->|No| ShowZoneError[Show Zone Error]
    
    ShowZoneError --> ShowMap
    
    SaveAddress --> SetAsDefault{Set as Default?}
    SetAsDefault -->|Yes| UpdateDefault[Update Default Address]
    SetAsDefault -->|No| AddToList[Add to Address List]
    
    UpdateDefault --> LoadHome[Load Home Screen]
    AddToList --> LoadHome
    ValidateZone --> LoadHome
    
    style CheckLocation fill:#87CEEB
    style InZone fill:#FFB6C1
    style LoadHome fill:#90EE90
```

### Promotion & Offers System

```mermaid
graph TB
    subgraph "Promotion Types"
        Banner[Banners]
        FlashSale[Flash Sales]
        Coupon[Coupons]
        Loyalty[Loyalty Points]
    end
    
    subgraph "Display Locations"
        HomeScreen[Home Screen]
        StoreScreen[Store Screen]
        CheckoutScreen[Checkout Screen]
        CartScreen[Cart Screen]
    end
    
    subgraph "Application Logic"
        AutoApply[Auto Apply]
        UserApply[User Apply]
        Validate[Validate Conditions]
    end
    
    Banner --> HomeScreen
    FlashSale --> HomeScreen
    FlashSale --> StoreScreen
    
    Coupon --> CheckoutScreen
    Coupon --> CartScreen
    
    Loyalty --> CheckoutScreen
    
    CheckoutScreen --> UserApply
    CartScreen --> AutoApply
    
    UserApply --> Validate
    AutoApply --> Validate
    
    Validate --> ApplyDiscount{Valid?}
    ApplyDiscount -->|Yes| UpdateTotal[Update Cart Total]
    ApplyDiscount -->|No| ShowError[Show Error Message]
    
    style Banner fill:#FFE4B5
    style FlashSale fill:#FFB6C1
    style Coupon fill:#90EE90
    style Loyalty fill:#87CEEB
```

### Wallet System Flow

```mermaid
sequenceDiagram
    participant User
    participant WalletScreen
    participant WalletController
    participant WalletRepo
    participant API
    participant PaymentGateway
    
    User->>WalletScreen: Open Wallet
    WalletScreen->>WalletController: getWalletBalance()
    WalletController->>WalletRepo: fetchBalance()
    WalletRepo->>API: GET /customer/wallet
    API-->>WalletRepo: {balance, transactions}
    WalletRepo-->>WalletController: Wallet Data
    WalletController-->>WalletScreen: Display Balance
    
    User->>WalletScreen: Add Money
    WalletScreen->>User: Enter Amount
    User->>WalletScreen: Confirm Amount
    WalletScreen->>WalletController: addMoney(amount)
    WalletController->>WalletRepo: initiateAddMoney()
    WalletRepo->>PaymentGateway: Create Payment
    PaymentGateway-->>User: Payment UI
    User->>PaymentGateway: Complete Payment
    PaymentGateway->>API: Payment Webhook
    API-->>WalletRepo: Balance Updated
    WalletRepo-->>WalletController: Success
    WalletController-->>WalletScreen: Refresh Balance
    
    User->>WalletScreen: Transfer Money
    WalletScreen->>User: Enter Recipient & Amount
    User->>WalletScreen: Confirm Transfer
    WalletScreen->>WalletController: transferMoney()
    WalletController->>WalletRepo: makeTransfer()
    WalletRepo->>API: POST /customer/wallet/transfer
    API-->>WalletRepo: Transfer Success
    WalletRepo-->>WalletController: Updated Balance
    WalletController-->>WalletScreen: Show Success
```

### Notification System Architecture

```mermaid
graph TB
    subgraph "Notification Sources"
        FCM[Firebase Cloud Messaging]
        LocalNotif[Local Notifications]
        InApp[In-App Notifications]
    end
    
    subgraph "Notification Service"
        Service[Notification Service]
        Handler[Notification Handler]
        Storage[Local Storage]
    end
    
    subgraph "Notification Types"
        OrderUpdate[Order Updates]
        Promotional[Promotional]
        Chat[Chat Messages]
        General[General Announcements]
    end
    
    subgraph "User Actions"
        Tap[Tap Notification]
        Dismiss[Dismiss]
        View[View in App]
    end
    
    FCM --> Service
    LocalNotif --> Service
    InApp --> Service
    
    Service --> Handler
    Handler --> Storage
    Handler --> OrderUpdate
    Handler --> Promotional
    Handler --> Chat
    Handler --> General
    
    OrderUpdate --> Tap
    Promotional --> Tap
    Chat --> Tap
    General --> Tap
    
    Tap --> Navigate[Navigate to Screen]
    Tap --> View
    Dismiss --> Storage
    View --> Storage
    
    style FCM fill:#FFE4B5
    style Service fill:#87CEEB
    style Navigate fill:#90EE90
```

### Review & Rating System

```mermaid
stateDiagram-v2
    [*] --> OrderDelivered
    OrderDelivered --> CanReview: Order Completed
    
    CanReview --> WriteReview: User Clicks Review
    WriteReview --> SelectRating: Rate (1-5 stars)
    SelectRating --> WriteComment: Add Comment
    WriteComment --> UploadImages: Add Photos (Optional)
    
    UploadImages --> SubmitReview: Submit
    SubmitReview --> Pending: Under Review
    
    Pending --> Approved: Admin Approves
    Pending --> Rejected: Admin Rejects
    
    Approved --> Published: Visible to Public
    Published --> CanEdit: User Can Edit
    
    CanEdit --> WriteReview: Edit Review
    
    Rejected --> [*]
    Published --> [*]
```

### Loyalty Points Flow

```mermaid
graph LR
    subgraph "Earning Points"
        OrderPlace[Place Order]
        OrderComplete[Order Delivered]
        ReferFriend[Refer Friend]
        FirstOrder[First Order]
    end
    
    subgraph "Points System"
        Calculate[Calculate Points]
        AddPoints[Add to Wallet]
        Balance[Points Balance]
    end
    
    subgraph "Redemption"
        MinPoints{Meet Minimum?}
        ConvertCash[Convert to Cash]
        ApplyDiscount[Apply at Checkout]
    end
    
    OrderPlace --> OrderComplete
    OrderComplete --> Calculate
    ReferFriend --> Calculate
    FirstOrder --> Calculate
    
    Calculate --> AddPoints
    AddPoints --> Balance
    
    Balance --> MinPoints
    MinPoints -->|Yes| ConvertCash
    MinPoints -->|Yes| ApplyDiscount
    MinPoints -->|No| Wait[Wait for More Points]
    
    ConvertCash --> Balance
    ApplyDiscount --> Balance
    
    style Calculate fill:#87CEEB
    style Balance fill:#90EE90
    style ApplyDiscount fill:#FFB6C1
```

### Chat System Architecture

```mermaid
sequenceDiagram
    participant Customer
    participant ChatScreen
    participant ChatController
    participant ChatRepo
    participant WebSocket
    participant API
    participant Admin/Store
    
    Customer->>ChatScreen: Open Chat
    ChatScreen->>ChatController: initChat()
    ChatController->>ChatRepo: loadMessages()
    ChatRepo->>API: GET /chat/messages
    API-->>ChatRepo: Message History
    ChatRepo-->>ChatController: Display Messages
    
    ChatController->>WebSocket: Connect
    WebSocket-->>ChatController: Connected
    
    Customer->>ChatScreen: Type Message
    ChatScreen->>ChatController: sendMessage(text)
    ChatController->>ChatRepo: send(message)
    ChatRepo->>WebSocket: Emit Message
    WebSocket->>API: Store Message
    API->>Admin/Store: Notify
    
    Admin/Store->>API: Send Reply
    API->>WebSocket: Broadcast Reply
    WebSocket-->>ChatController: New Message
    ChatController-->>ChatScreen: Display Reply
    ChatScreen-->>Customer: Show Message
    
    Customer->>ChatScreen: Close Chat
    ChatScreen->>ChatController: dispose()
    ChatController->>WebSocket: Disconnect
```

### Module Switching Flow

```mermaid
graph TD
    Dashboard[Dashboard] --> ModuleSelector[Module Selector]
    
    ModuleSelector --> SelectModule{Select Module}
    
    SelectModule -->|Food| LoadFood[Load Food Config]
    SelectModule -->|Grocery| LoadGrocery[Load Grocery Config]
    SelectModule -->|Pharmacy| LoadPharmacy[Load Pharmacy Config]
    SelectModule -->|Ecommerce| LoadEcom[Load E-commerce Config]
    SelectModule -->|Parcel| LoadParcel[Load Parcel Config]
    
    LoadFood --> ValidateLocation{Location Valid?}
    LoadGrocery --> ValidateLocation
    LoadPharmacy --> ValidateLocation
    LoadEcom --> ValidateLocation
    LoadParcel --> ValidateLocation
    
    ValidateLocation -->|Yes| LoadModuleHome[Load Module Home]
    ValidateLocation -->|No| LocationPicker[Show Location Picker]
    
    LocationPicker --> SetLocation[Set Location]
    SetLocation --> LoadModuleHome
    
    LoadModuleHome --> FetchData[Fetch Module Data]
    FetchData --> DisplayHome[Display Home Screen]
    
    style ModuleSelector fill:#87CEEB
    style LoadModuleHome fill:#90EE90
    style DisplayHome fill:#FFE4B5
```

### Parcel Booking Flow

```mermaid
stateDiagram-v2
    [*] --> SelectCategory: Open Parcel
    SelectCategory --> EnterDetails: Choose Parcel Type
    
    EnterDetails --> SenderInfo: Enter Sender Details
    SenderInfo --> ReceiverInfo: Enter Receiver Details
    ReceiverInfo --> ParcelInfo: Enter Parcel Info
    
    ParcelInfo --> SelectPickup: Select Pickup Location
    SelectPickup --> SelectDelivery: Select Delivery Location
    
    SelectDelivery --> CalculatePrice: Calculate Distance & Price
    CalculatePrice --> ReviewOrder: Review Parcel Order
    
    ReviewOrder --> SelectPayment: Choose Payment
    SelectPayment --> ConfirmOrder: Confirm Booking
    
    ConfirmOrder --> OrderPlaced: Parcel Booked
    OrderPlaced --> AssignDriver: Waiting for Driver
    AssignDriver --> DriverAssigned: Driver Assigned
    DriverAssigned --> PickupComplete: Driver Picks Up
    PickupComplete --> InTransit: On the Way
    InTransit --> Delivered: Parcel Delivered
    
    Delivered --> [*]
```
