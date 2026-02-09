# API Architecture Diagrams

## API Request Flow

```mermaid
sequenceDiagram
    participant Controller
    participant ApiClient
    participant CacheManager
    participant Network
    participant Backend
    participant ApiChecker
    
    Controller->>CacheManager: Request Data
    CacheManager->>CacheManager: Check Cache
    
    alt Cache Hit & Valid
        CacheManager-->>Controller: Return Cached Data
        Note over Controller: Display cached data immediately
        CacheManager->>Network: Background refresh
    else Cache Miss/Expired
        CacheManager->>ApiClient: Make API Call
    end
    
    ApiClient->>ApiClient: Add Headers (Token, Zone, etc)
    ApiClient->>Network: HTTP Request
    Network->>Backend: Send Request
    
    alt Success
        Backend-->>Network: 200 OK + Data
        Network-->>ApiClient: Response
        ApiClient->>ApiChecker: Validate Response
        ApiChecker-->>ApiClient: Valid
        ApiClient->>CacheManager: Store in Cache
        CacheManager-->>Controller: Return Fresh Data
        Controller->>Controller: Update UI
    else Error (400-499)
        Backend-->>Network: Client Error
        Network-->>ApiClient: Error Response
        ApiClient->>ApiChecker: Validate Response
        ApiChecker-->>Controller: Show Error Message
    else Error (401)
        Backend-->>Network: Unauthorized
        Network-->>ApiClient: 401 Response
        ApiClient->>ApiChecker: Validate Response
        ApiChecker->>ApiChecker: Clear User Data
        ApiChecker-->>Controller: Redirect to Login
    else Error (500-599)
        Backend-->>Network: Server Error
        Network-->>ApiClient: Error Response
        ApiClient->>ApiChecker: Validate Response
        ApiChecker-->>Controller: Show Server Error
    else Network Error
        Network-->>ApiClient: Connection Failed
        ApiClient-->>Controller: Show Network Error
    end
```

## API Client Architecture

```mermaid
graph TB
    subgraph "HTTP Methods"
        GET[GET Request]
        POST[POST Request]
        PUT[PUT Request]
        DELETE[DELETE Request]
        MULTIPART[Multipart Upload]
    end
    
    subgraph "API Client Core"
        Client[API Client]
        Headers[Header Manager]
        Interceptor[Request Interceptor]
        Logger[Request Logger]
    end
    
    subgraph "Authentication"
        Token[Token Manager]
        Refresh[Token Refresh]
        Zone[Zone Manager]
    end
    
    subgraph "Backend"
        Server[Backend Server]
    end
    
    GET --> Client
    POST --> Client
    PUT --> Client
    DELETE --> Client
    MULTIPART --> Client
    
    Client --> Interceptor
    Interceptor --> Headers
    Headers --> Token
    Headers --> Zone
    
    Token --> Refresh
    
    Interceptor --> Logger
    Logger --> Server
    
    Server -.Response.-> Logger
    Logger -.Response.-> Client
    
    style Client fill:#87CEEB
    style Token fill:#FFE4B5
    style Server fill:#90EE90
```

## Cache Strategy Flow

```mermaid
graph TD
    Request[API Request] --> CacheEnabled{Caching Enabled?}
    
    CacheEnabled -->|No| DirectAPI[Direct API Call]
    CacheEnabled -->|Yes| CheckMemory[Check Memory Cache]
    
    CheckMemory --> MemoryHit{Found in Memory?}
    
    MemoryHit -->|Yes| ValidateMemory{Cache Valid?}
    MemoryHit -->|No| CheckDisk[Check Disk Cache]
    
    ValidateMemory -->|Yes| ReturnMemory[Return from Memory]
    ValidateMemory -->|No| CheckDisk
    
    CheckDisk --> DiskHit{Found on Disk?}
    
    DiskHit -->|Yes| ValidateDisk{Cache Valid?}
    DiskHit -->|No| DirectAPI
    
    ValidateDisk -->|Yes| LoadDisk[Load from Disk]
    ValidateDisk -->|No| DirectAPI
    
    LoadDisk --> UpdateMemory[Update Memory Cache]
    UpdateMemory --> ReturnDisk[Return from Disk]
    
    DirectAPI --> APICall[Make Network Call]
    APICall --> Success{Success?}
    
    Success -->|Yes| SaveDisk[Save to Disk]
    Success -->|No| ReturnError[Return Error]
    
    SaveDisk --> SaveMemory[Save to Memory]
    SaveMemory --> ReturnFresh[Return Fresh Data]
    
    ReturnMemory --> BackgroundRefresh[Background Refresh]
    ReturnDisk --> BackgroundRefresh
    BackgroundRefresh -.Optional.-> APICall
    
    style CheckMemory fill:#ffcccc
    style CheckDisk fill:#ccffcc
    style DirectAPI fill:#ccccff
```

## Error Handling Flow

```mermaid
flowchart TD
    Response[API Response] --> CheckStatus{Status Code}
    
    CheckStatus -->|200-299| Success[Success Response]
    CheckStatus -->|400| BadRequest[Bad Request]
    CheckStatus -->|401| Unauthorized[Unauthorized]
    CheckStatus -->|403| Forbidden[Forbidden]
    CheckStatus -->|404| NotFound[Not Found]
    CheckStatus -->|429| RateLimit[Rate Limited]
    CheckStatus -->|500-599| ServerError[Server Error]
    CheckStatus -->|Network| NetworkError[Network Error]
    
    Success --> ParseJSON[Parse JSON]
    ParseJSON --> ReturnData[Return Data to Controller]
    
    BadRequest --> ExtractError[Extract Error Message]
    ExtractError --> ShowSnackbar1[Show Error Snackbar]
    
    Unauthorized --> ClearSession[Clear User Session]
    ClearSession --> NavigateLogin[Navigate to Login]
    NavigateLogin --> ShowSnackbar2[Show Session Expired]
    
    Forbidden --> ShowSnackbar3[Show Access Denied]
    
    NotFound --> ShowSnackbar4[Show Not Found]
    
    RateLimit --> ShowSnackbar5[Show Rate Limit Message]
    
    ServerError --> ShowSnackbar6[Show Server Error]
    
    NetworkError --> CheckConnectivity{Has Internet?}
    CheckConnectivity -->|No| ShowOffline[Show Offline Message]
    CheckConnectivity -->|Yes| ShowTimeout[Show Timeout Message]
    
    style Success fill:#90EE90
    style Unauthorized fill:#FFB6C1
    style ServerError fill:#FFB6C1
    style NetworkError fill:#FFE4B5
```

## Authentication Flow

```mermaid
sequenceDiagram
    participant App
    participant AuthController
    participant ApiClient
    participant TokenManager
    participant Backend
    participant SharedPrefs
    
    App->>AuthController: login(email, password)
    AuthController->>ApiClient: POST /auth/login
    ApiClient->>Backend: HTTP Request
    
    alt Valid Credentials
        Backend-->>ApiClient: {token, refresh_token, user}
        ApiClient-->>AuthController: Success Response
        AuthController->>TokenManager: saveToken(token)
        TokenManager->>SharedPrefs: Store Token
        TokenManager->>SharedPrefs: Store Refresh Token
        AuthController->>SharedPrefs: Store User Data
        AuthController-->>App: Navigate to Home
    else Invalid Credentials
        Backend-->>ApiClient: 401 Unauthorized
        ApiClient-->>AuthController: Error Response
        AuthController-->>App: Show Error Message
    end
    
    Note over TokenManager,Backend: All subsequent API calls
    
    App->>ApiClient: GET /some-endpoint
    ApiClient->>TokenManager: getToken()
    TokenManager-->>ApiClient: token
    ApiClient->>ApiClient: Add Authorization header
    ApiClient->>Backend: Request with Bearer token
    
    alt Token Valid
        Backend-->>ApiClient: 200 OK + Data
        ApiClient-->>App: Return Data
    else Token Expired
        Backend-->>ApiClient: 401 Unauthorized
        ApiClient->>TokenManager: refreshToken()
        
        alt Refresh Successful
            TokenManager->>Backend: POST /auth/refresh
            Backend-->>TokenManager: New tokens
            TokenManager->>SharedPrefs: Update tokens
            TokenManager-->>ApiClient: Retry with new token
            ApiClient->>Backend: Retry original request
            Backend-->>ApiClient: 200 OK + Data
            ApiClient-->>App: Return Data
        else Refresh Failed
            TokenManager-->>ApiClient: Refresh failed
            ApiClient->>AuthController: Logout
            AuthController-->>App: Navigate to Login
        end
    end
```

## Multi-Module API Architecture

```mermaid
graph TB
    subgraph "App Layer"
        ModuleSelector[Module Selector]
        CurrentModule[Current Module State]
    end
    
    subgraph "API Configuration"
        BaseURL[Base URL]
        ModuleID[Module ID Header]
        ZoneID[Zone ID Header]
        Headers[Request Headers]
    end
    
    subgraph "Module Types"
        Food[Food Module<br/>moduleId: 1]
        Grocery[Grocery Module<br/>moduleId: 2]
        Pharmacy[Pharmacy Module<br/>moduleId: 3]
        Ecommerce[E-commerce Module<br/>moduleId: 4]
        Parcel[Parcel Module<br/>moduleId: 6]
    end
    
    subgraph "Backend Routing"
        Router[API Router]
        FoodAPI[Food Endpoints]
        GroceryAPI[Grocery Endpoints]
        PharmacyAPI[Pharmacy Endpoints]
        EcomAPI[E-commerce Endpoints]
        ParcelAPI[Parcel Endpoints]
    end
    
    ModuleSelector --> CurrentModule
    CurrentModule --> ModuleID
    
    Food -.moduleId: 1.-> ModuleID
    Grocery -.moduleId: 2.-> ModuleID
    Pharmacy -.moduleId: 3.-> ModuleID
    Ecommerce -.moduleId: 4.-> ModuleID
    Parcel -.moduleId: 6.-> ModuleID
    
    ModuleID --> Headers
    ZoneID --> Headers
    BaseURL --> Headers
    
    Headers --> Router
    
    Router -->|moduleId: 1| FoodAPI
    Router -->|moduleId: 2| GroceryAPI
    Router -->|moduleId: 3| PharmacyAPI
    Router -->|moduleId: 4| EcomAPI
    Router -->|moduleId: 6| ParcelAPI
    
    style CurrentModule fill:#87CEEB
    style Headers fill:#FFE4B5
    style Router fill:#90EE90
```

## File Upload Flow

```mermaid
sequenceDiagram
    participant User
    participant UI
    participant ImagePicker
    participant Controller
    participant ApiClient
    participant Backend
    
    User->>UI: Tap Upload Button
    UI->>ImagePicker: Pick Image
    ImagePicker-->>UI: Image File
    UI->>Controller: uploadImage(file)
    
    Controller->>Controller: Validate File (size, type)
    
    alt Valid File
        Controller->>ApiClient: postMultipartData()
        ApiClient->>ApiClient: Create multipart request
        ApiClient->>ApiClient: Add image file
        ApiClient->>ApiClient: Add form fields
        ApiClient->>Backend: Upload (multipart/form-data)
        
        alt Upload Success
            Backend-->>ApiClient: {image_url}
            ApiClient-->>Controller: Success
            Controller->>Controller: Update state with URL
            Controller-->>UI: Show success message
            UI-->>User: Display uploaded image
        else Upload Failed
            Backend-->>ApiClient: Error
            ApiClient-->>Controller: Error
            Controller-->>UI: Show error
            UI-->>User: Display error message
        end
    else Invalid File
        Controller-->>UI: Show validation error
        UI-->>User: Display error (size/type)
    end
```

## Pagination Flow

```mermaid
graph TB
    ListView[List View] --> InitialLoad[Initial Load<br/>offset=0, limit=10]
    
    InitialLoad --> APICall1[API Call]
    APICall1 --> Response1[Response with 10 items]
    Response1 --> Display1[Display Items]
    
    Display1 --> UserScrolls[User Scrolls Down]
    UserScrolls --> ScrollDetector{At Bottom?}
    
    ScrollDetector -->|No| UserScrolls
    ScrollDetector -->|Yes| CheckLoading{Already Loading?}
    
    CheckLoading -->|Yes| UserScrolls
    CheckLoading -->|No| CheckMore{Has More?}
    
    CheckMore -->|No| ShowEnd[Show End Message]
    CheckMore -->|Yes| LoadNext[Load Next Page<br/>offset=10, limit=10]
    
    LoadNext --> APICall2[API Call]
    APICall2 --> Response2[Response with next 10]
    Response2 --> Append[Append to List]
    Append --> Display2[Update Display]
    Display2 --> UserScrolls
    
    ShowEnd --> UserScrolls
    
    style InitialLoad fill:#87CEEB
    style APICall1 fill:#90EE90
    style APICall2 fill:#90EE90
    style Display2 fill:#FFE4B5
```

## Zone-Based API Routing

```mermaid
graph LR
    subgraph "User Location"
        GPS[GPS Coordinates]
        SavedAddress[Saved Address]
    end
    
    subgraph "Zone Detection"
        ZoneAPI[Zone Check API]
        ZoneID[Assigned Zone ID]
    end
    
    subgraph "API Headers"
        Headers[Request Headers]
        ZoneHeader[zoneId: JSON Array]
    end
    
    subgraph "Backend Logic"
        Filter[Zone-based Filtering]
        Stores[Available Stores]
        Items[Available Items]
    end
    
    GPS --> ZoneAPI
    SavedAddress --> ZoneID
    
    ZoneAPI --> ZoneID
    ZoneID --> ZoneHeader
    ZoneHeader --> Headers
    
    Headers --> Filter
    Filter --> Stores
    Filter --> Items
    
    style ZoneAPI fill:#87CEEB
    style ZoneID fill:#FFE4B5
    style Filter fill:#90EE90
```

## Request Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Preparing: Trigger API Call
    
    Preparing --> AddingHeaders: Prepare Request
    AddingHeaders --> AddingAuth: Add Headers
    AddingAuth --> CheckingCache: Add Auth Token
    
    CheckingCache --> ReturningCache: Cache Hit
    CheckingCache --> Sending: Cache Miss
    
    ReturningCache --> [*]
    
    Sending --> Waiting: HTTP Request Sent
    Waiting --> Processing: Response Received
    
    Processing --> Success: Status 200
    Processing --> ClientError: Status 400-499
    Processing --> ServerError: Status 500-599
    Processing --> NetworkError: Connection Failed
    
    Success --> Caching: Parse Response
    Caching --> [*]
    
    ClientError --> ErrorHandling: Show Error
    ServerError --> ErrorHandling
    NetworkError --> ErrorHandling
    
    ErrorHandling --> [*]
```

## API Retry Mechanism

```mermaid
flowchart TD
    Request[Make API Request] --> Attempt1[Attempt 1]
    
    Attempt1 --> Success1{Success?}
    Success1 -->|Yes| Return[Return Data]
    Success1 -->|No| CheckRetryable{Retryable Error?}
    
    CheckRetryable -->|No| FinalError[Return Error]
    CheckRetryable -->|Yes| Wait1[Wait 1s]
    
    Wait1 --> Attempt2[Attempt 2]
    Attempt2 --> Success2{Success?}
    
    Success2 -->|Yes| Return
    Success2 -->|No| Wait2[Wait 2s]
    
    Wait2 --> Attempt3[Attempt 3]
    Attempt3 --> Success3{Success?}
    
    Success3 -->|Yes| Return
    Success3 -->|No| FinalError
    
    style Return fill:#90EE90
    style FinalError fill:#FFB6C1
    style Attempt1 fill:#87CEEB
    style Attempt2 fill:#87CEEB
    style Attempt3 fill:#87CEEB
```
