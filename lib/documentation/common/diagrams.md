# Common Components Architecture Diagrams

## API Client Architecture

```mermaid
graph TB
    subgraph "API Client Layer"
        ApiClient[API Client]
        Interceptor[Request Interceptor]
        Logger[Response Logger]
        ErrorHandler[Error Handler]
    end
    
    subgraph "Request Flow"
        Request[HTTP Request]
        AddHeaders[Add Headers]
        AddToken[Add Auth Token]
        AddZone[Add Zone ID]
    end
    
    subgraph "Response Flow"
        Response[HTTP Response]
        ParseJSON[Parse JSON]
        ValidateResponse[Validate Response]
        HandleError[Handle Error]
    end
    
    subgraph "Cache Layer"
        CheckCache[Check Cache]
        StoreCache[Store in Cache]
        ReturnCache[Return Cached]
    end
    
    Request --> Interceptor
    Interceptor --> AddHeaders
    AddHeaders --> AddToken
    AddToken --> AddZone
    AddZone --> CheckCache
    
    CheckCache -->|Cache Hit| ReturnCache
    CheckCache -->|Cache Miss| ApiClient
    
    ApiClient --> Response
    Response --> Logger
    Logger --> ParseJSON
    ParseJSON --> ValidateResponse
    
    ValidateResponse -->|Success| StoreCache
    ValidateResponse -->|Error| HandleError
    
    StoreCache --> ReturnData[Return Data]
    HandleError --> ReturnError[Return Error]
    
    style ApiClient fill:#87CEEB
    style CheckCache fill:#FFE4B5
    style HandleError fill:#FFB6C1
```

## Cache System Architecture

```mermaid
graph LR
    subgraph "Cache Layers"
        Memory["Memory Cache<br/>(Fast Access)"]
        Disk["Disk Cache<br/>(Persistent)"]
        Network["Network<br/>(Fresh Data)"]
    end
    
    subgraph "Cache Manager"
        Manager[API Call Manager]
        TTL[TTL Checker]
        Invalidator[Cache Invalidator]
    end
    
    Request[Data Request] --> Manager
    Manager --> TTL
    
    TTL -->|Valid| Memory
    TTL -->|Expired| Invalidator
    
    Memory -->|Hit| Return1[Return Immediately]
    Memory -->|Miss| Disk
    
    Disk -->|Hit| UpdateMemory[Update Memory]
    Disk -->|Miss| Network
    
    UpdateMemory --> Return2[Return from Disk]
    
    Network --> FetchAPI[Fetch from API]
    FetchAPI --> StoreDisk[Store in Disk]
    StoreDisk --> StoreMemory[Store in Memory]
    StoreMemory --> Return3[Return Fresh Data]
    
    Invalidator --> Network
    
    style Memory fill:#ffcccc
    style Disk fill:#ccffcc
    style Network fill:#ccccff
```

## State Management with GetX

```mermaid
graph TB
    subgraph "GetX Controller"
        Controller[Controller Class]
        State[Observable State]
        Methods[Business Methods]
        Lifecycle[Lifecycle Hooks]
    end
    
    subgraph "UI Layer"
        Widget[Widget/Screen]
        GetBuilder[GetBuilder]
        Obx[Obx Widget]
    end
    
    subgraph "Dependency Injection"
        Binding[Feature Binding]
        GetPut[Get.put]
        GetLazy[Get.lazyPut]
        GetFind[Get.find]
    end
    
    Binding --> GetPut
    Binding --> GetLazy
    GetPut --> Controller
    GetLazy --> Controller
    
    Controller --> State
    Controller --> Methods
    Controller --> Lifecycle
    
    Widget --> GetFind
    GetFind --> Controller
    
    Widget --> GetBuilder
    GetBuilder --> Controller
    
    Widget --> Obx
    Obx --> State
    
    State -.Update.-> GetBuilder
    State -.Reactive.-> Obx
    
    style Controller fill:#fff4e1
    style State fill:#ffcccc
    style GetBuilder fill:#e1f5ff
    style Obx fill:#e1ffe1
```

## Theme Management Flow

```mermaid
stateDiagram-v2
    [*] --> LoadPreferences
    LoadPreferences --> CheckSavedTheme
    
    CheckSavedTheme --> LightTheme: Default
    CheckSavedTheme --> DarkTheme: Saved as Dark
    CheckSavedTheme --> SystemTheme: Follow System
    
    LightTheme --> UserAction: User Toggles
    DarkTheme --> UserAction: User Toggles
    SystemTheme --> UserAction: User Changes Setting
    
    UserAction --> UpdateTheme: Toggle/Change
    UpdateTheme --> SavePreference: Save to Storage
    SavePreference --> ApplyTheme: Apply to App
    
    ApplyTheme --> LightTheme
    ApplyTheme --> DarkTheme
    ApplyTheme --> SystemTheme
    
    SystemTheme --> DetectChange: System Theme Changes
    DetectChange --> ApplyTheme
```

## Localization System

```mermaid
graph TB
    subgraph "Language Resources"
        EnglishJSON[en_US.json]
        ArabicJSON[ar_SA.json]
        FrenchJSON[fr_FR.json]
        OtherJSON[Other Languages]
    end
    
    subgraph "Localization Controller"
        Controller[LocalizationController]
        CurrentLocale[Current Locale]
        Translator[Translation Service]
    end
    
    subgraph "UI"
        Widget[Widget]
        TranslateKey[Translate Key]
        Display[Display Text]
    end
    
    EnglishJSON --> Translator
    ArabicJSON --> Translator
    FrenchJSON --> Translator
    OtherJSON --> Translator
    
    Controller --> CurrentLocale
    Controller --> Translator
    
    Widget --> TranslateKey
    TranslateKey --> Translator
    Translator --> Display
    
    UserChange[User Changes Language] --> Controller
    Controller --> SavePreference[Save to Preferences]
    SavePreference --> UpdateLocale[Update App Locale]
    UpdateLocale --> Reload[Reload UI]
    
    style Translator fill:#87CEEB
    style CurrentLocale fill:#FFE4B5
    style Display fill:#90EE90
```

## Validation System

```mermaid
graph LR
    subgraph "Input Fields"
        Email[Email Field]
        Phone[Phone Field]
        Password[Password Field]
        Custom[Custom Field]
    end
    
    subgraph "Validators"
        EmailValidator[Email Validator]
        PhoneValidator[Phone Validator]
        PasswordValidator[Password Validator]
        CustomValidator[Custom Validator]
    end
    
    subgraph "Validation Rules"
        Required[Required Check]
        Format[Format Check]
        Length[Length Check]
        Pattern[Pattern Match]
    end
    
    subgraph "Result"
        Valid[Valid ✓]
        Invalid[Invalid ✗]
        ErrorMsg[Error Message]
    end
    
    Email --> EmailValidator
    Phone --> PhoneValidator
    Password --> PasswordValidator
    Custom --> CustomValidator
    
    EmailValidator --> Required
    EmailValidator --> Format
    
    PhoneValidator --> Required
    PhoneValidator --> Length
    
    PasswordValidator --> Required
    PasswordValidator --> Length
    PasswordValidator --> Pattern
    
    Required -->|Pass| Valid
    Required -->|Fail| Invalid
    Format -->|Pass| Valid
    Format -->|Fail| Invalid
    Length -->|Pass| Valid
    Length -->|Fail| Invalid
    Pattern -->|Pass| Valid
    Pattern -->|Fail| Invalid
    
    Invalid --> ErrorMsg
    
    style Valid fill:#90EE90
    style Invalid fill:#FFB6C1
```

## Widget Hierarchy

```mermaid
graph TB
    subgraph "Base Widgets"
        CustomButton[CustomButton]
        CustomTextField[CustomTextField]
        CustomAppBar[CustomAppBar]
        LoadingIndicator[LoadingIndicator]
    end
    
    subgraph "Composite Widgets"
        FormWidget[Form Widget]
        ListWidget[List Widget]
        CardWidget[Card Widget]
    end
    
    subgraph "Feature Widgets"
        StoreCard[Store Card]
        ItemCard[Item Card]
        CartItem[Cart Item Widget]
    end
    
    CustomButton --> FormWidget
    CustomTextField --> FormWidget
    
    CustomButton --> CardWidget
    LoadingIndicator --> ListWidget
    
    FormWidget --> StoreCard
    CardWidget --> StoreCard
    
    FormWidget --> ItemCard
    CardWidget --> ItemCard
    
    ListWidget --> CartItem
    CardWidget --> CartItem
    
    style CustomButton fill:#e1f5ff
    style FormWidget fill:#fff4e1
    style StoreCard fill:#e1ffe1
```

## Error Handling Flow

```mermaid
sequenceDiagram
    participant API
    participant ApiClient
    participant ApiChecker
    participant ErrorHandler
    participant UI
    participant User
    
    API->>ApiClient: HTTP Response
    ApiClient->>ApiChecker: Check Response
    
    alt Success (200)
        ApiChecker->>ApiClient: Pass Through
        ApiClient->>UI: Return Data
        UI->>User: Display Content
    else Client Error (400)
        ApiChecker->>ErrorHandler: Handle Client Error
        ErrorHandler->>UI: Show Error Message
        UI->>User: Display Error
    else Unauthorized (401)
        ApiChecker->>ErrorHandler: Handle Unauthorized
        ErrorHandler->>ErrorHandler: Clear User Data
        ErrorHandler->>UI: Navigate to Login
        UI->>User: Show Login Screen
    else Server Error (500)
        ApiChecker->>ErrorHandler: Handle Server Error
        ErrorHandler->>UI: Show Generic Error
        UI->>User: Display Error
    else Network Error
        ApiChecker->>ErrorHandler: Handle Network Error
        ErrorHandler->>UI: Show Connection Error
        UI->>User: Display Offline Message
    end
```

## Security Layer Architecture

```mermaid
graph TB
    subgraph "Data Input"
        UserInput[User Input]
        APIData[API Data]
        StoredData[Stored Data]
    end
    
    subgraph "Security Layer"
        Sanitizer[Input Sanitizer]
        Encryptor[Encryption Service]
        TokenManager[Token Manager]
        SecureStorage[Secure Storage]
    end
    
    subgraph "Protected Data"
        EncryptedData[Encrypted Data]
        SecureToken[Secure Token]
        SensitiveInfo[Sensitive Info]
    end
    
    UserInput --> Sanitizer
    Sanitizer --> Encryptor
    
    APIData --> TokenManager
    TokenManager --> SecureToken
    
    StoredData --> Encryptor
    Encryptor --> EncryptedData
    
    SecureToken --> SecureStorage
    EncryptedData --> SecureStorage
    SensitiveInfo --> SecureStorage
    
    SecureStorage -.Decrypt.-> TokenManager
    SecureStorage -.Decrypt.-> Encryptor
    
    style Sanitizer fill:#FFE4B5
    style Encryptor fill:#FFB6C1
    style SecureStorage fill:#90EE90
```

## Notification Service Architecture

```mermaid
graph TB
    subgraph "Notification Sources"
        FCM[Firebase Cloud Messaging]
        LocalTrigger[Local Trigger]
        Schedule[Scheduled Notification]
    end
    
    subgraph "Notification Service"
        Service[NotificationService]
        Handler[Message Handler]
        Processor[Notification Processor]
    end
    
    subgraph "App States"
        Foreground[App in Foreground]
        Background[App in Background]
        Terminated[App Terminated]
    end
    
    subgraph "User Actions"
        Display[Display Notification]
        Navigate[Navigate to Screen]
        Update[Update Badge]
        Store[Store in Database]
    end
    
    FCM --> Service
    LocalTrigger --> Service
    Schedule --> Service
    
    Service --> Handler
    Handler --> Processor
    
    Processor --> Foreground
    Processor --> Background
    Processor --> Terminated
    
    Foreground --> Display
    Background --> Display
    Terminated --> Display
    
    Display --> Navigate
    Display --> Update
    Display --> Store
    
    style Service fill:#87CEEB
    style Display fill:#FFE4B5
    style Navigate fill:#90EE90
```

## Responsive Design System

```mermaid
graph LR
    subgraph "Screen Sizes"
        Mobile[Mobile<br/>< 600px]
        Tablet[Tablet<br/>600-1200px]
        Desktop[Desktop<br/>> 1200px]
    end
    
    subgraph "Dimensions Util"
        Calculator[Size Calculator]
        FontSize[Font Sizes]
        Padding[Padding Values]
        Margin[Margin Values]
    end
    
    subgraph "Responsive Output"
        SmallFont[Small Font]
        MediumFont[Medium Font]
        LargeFont[Large Font]
        SmallPad[Small Padding]
        MediumPad[Medium Padding]
        LargePad[Large Padding]
    end
    
    Mobile --> Calculator
    Tablet --> Calculator
    Desktop --> Calculator
    
    Calculator --> FontSize
    Calculator --> Padding
    Calculator --> Margin
    
    FontSize -->|Mobile| SmallFont
    FontSize -->|Tablet| MediumFont
    FontSize -->|Desktop| LargeFont
    
    Padding -->|Mobile| SmallPad
    Padding -->|Tablet| MediumPad
    Padding -->|Desktop| LargePad
    
    style Mobile fill:#FFB6C1
    style Tablet fill:#FFE4B5
    style Desktop fill:#90EE90
```

## Image Loading & Caching

```mermaid
sequenceDiagram
    participant Widget
    participant CachedImage
    participant MemoryCache
    participant DiskCache
    participant Network
    participant Server
    
    Widget->>CachedImage: Load Image URL
    CachedImage->>MemoryCache: Check Memory
    
    alt In Memory
        MemoryCache-->>CachedImage: Return Image
        CachedImage-->>Widget: Display Image
    else Not in Memory
        CachedImage->>DiskCache: Check Disk
        
        alt On Disk
            DiskCache-->>CachedImage: Return Image
            CachedImage->>MemoryCache: Store in Memory
            CachedImage-->>Widget: Display Image
        else Not on Disk
            CachedImage->>Widget: Show Placeholder
            CachedImage->>Network: Download Image
            Network->>Server: HTTP Request
            Server-->>Network: Image Data
            Network->>DiskCache: Save to Disk
            Network->>MemoryCache: Save to Memory
            Network-->>CachedImage: Return Image
            CachedImage-->>Widget: Display Image
        end
    end
```

## Pagination System

```mermaid
graph TB
    ListView[List View] --> ScrollController[Scroll Controller]
    ScrollController --> ScrollListener[Scroll Listener]
    
    ScrollListener --> CheckPosition{At Bottom?}
    
    CheckPosition -->|No| Wait[Continue Scrolling]
    CheckPosition -->|Yes| CheckLoading{Already Loading?}
    
    Wait --> ScrollListener
    
    CheckLoading -->|Yes| Wait
    CheckLoading -->|No| CheckMore{Has More Data?}
    
    CheckMore -->|No| ShowEnd[Show End Message]
    CheckMore -->|Yes| LoadMore[Load Next Page]
    
    LoadMore --> UpdateOffset[Update Page Offset]
    UpdateOffset --> APICall[API Call]
    APICall --> AppendData[Append to List]
    AppendData --> UpdateUI[Update UI]
    UpdateUI --> ScrollListener
    
    style ListView fill:#e1f5ff
    style APICall fill:#87CEEB
    style AppendData fill:#90EE90
```
