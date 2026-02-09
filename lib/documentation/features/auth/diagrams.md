# Authentication Flow Diagrams

## Complete Authentication Flow

```mermaid
flowchart TD
    Start[App Launch] --> CheckToken{Token Exists?}
    
    CheckToken -->|Yes| ValidateToken{Token Valid?}
    CheckToken -->|No| GuestOption{Continue as Guest?}
    
    ValidateToken -->|Yes| LoadUser[Load User Data]
    ValidateToken -->|No| ClearData[Clear Invalid Token]
    
    LoadUser --> Dashboard[Navigate to Dashboard]
    ClearData --> LoginScreen
    
    GuestOption -->|Yes| GuestMode[Enable Guest Mode]
    GuestOption -->|No| LoginScreen[Login Screen]
    
    GuestMode --> Dashboard
    
    LoginScreen --> LoginChoice{Login Method}
    
    LoginChoice -->|Email/Phone| EmailLogin[Email/Phone Login]
    LoginChoice -->|Google| GoogleLogin[Google Sign In]
    LoginChoice -->|Facebook| FacebookLogin[Facebook Sign In]
    LoginChoice -->|Apple| AppleLogin[Apple Sign In]
    LoginChoice -->|Sign Up| SignUpScreen[Sign Up Screen]
    
    EmailLogin --> ValidateInput{Input Valid?}
    ValidateInput -->|No| ShowErrors[Show Validation Errors]
    ShowErrors --> EmailLogin
    ValidateInput -->|Yes| CallLoginAPI[Call Login API]
    
    CallLoginAPI --> LoginSuccess{Success?}
    LoginSuccess -->|Yes| SaveTokens[Save Auth Tokens]
    LoginSuccess -->|No| LoginError[Show Error Message]
    LoginError --> EmailLogin
    
    SaveTokens --> CheckVerified{Phone Verified?}
    CheckVerified -->|Yes| Dashboard
    CheckVerified -->|No| VerifyPhone[Phone Verification]
    
    GoogleLogin --> GoogleAuth[Google OAuth]
    FacebookLogin --> FacebookAuth[Facebook OAuth]
    AppleLogin --> AppleAuth[Apple OAuth]
    
    GoogleAuth --> SocialAPICall[Call Social Login API]
    FacebookAuth --> SocialAPICall
    AppleAuth --> SocialAPICall
    
    SocialAPICall --> SocialSuccess{Success?}
    SocialSuccess -->|Yes| SaveTokens
    SocialSuccess -->|No| SocialError[Show Error]
    SocialError --> LoginScreen
    
    SignUpScreen --> FillForm[Fill Registration Form]
    FillForm --> ValidateRegister{Form Valid?}
    ValidateRegister -->|No| FormErrors[Show Errors]
    FormErrors --> FillForm
    ValidateRegister -->|Yes| CallRegisterAPI[Call Register API]
    
    CallRegisterAPI --> RegisterSuccess{Success?}
    RegisterSuccess -->|Yes| VerifyPhone
    RegisterSuccess -->|No| RegisterError[Show Error]
    RegisterError --> SignUpScreen
    
    VerifyPhone --> EnterOTP[Enter OTP Code]
    EnterOTP --> VerifyOTP{OTP Correct?}
    VerifyOTP -->|Yes| SaveTokens
    VerifyOTP -->|No| OTPError[Show Error]
    OTPError --> ResendOption{Resend OTP?}
    ResendOption -->|Yes| SendOTP[Send New OTP]
    ResendOption -->|No| EnterOTP
    SendOTP --> EnterOTP
    
    style LoginScreen fill:#87CEEB
    style Dashboard fill:#90EE90
    style SaveTokens fill:#FFE4B5
    style VerifyPhone fill:#FFB6C1
```

## Login Flow (Email/Phone)

```mermaid
sequenceDiagram
    participant User
    participant LoginScreen as Login Screen
    participant Controller as Auth Controller
    participant Validator
    participant API as Auth API
    participant Storage as Shared Preferences
    participant Dashboard
    
    User->>LoginScreen: Enter email/phone & password
    User->>LoginScreen: Click Sign In
    
    LoginScreen->>Validator: Validate inputs
    
    alt Invalid Input
        Validator-->>LoginScreen: Validation errors
        LoginScreen-->>User: Show error messages
    else Valid Input
        Validator-->>LoginScreen: Input valid
        LoginScreen->>Controller: login(email, password)
        Controller->>Controller: Set isLoading = true
        Controller->>API: POST /auth/login
        
        alt Success (200)
            API-->>Controller: {token, refresh_token, user}
            Controller->>Storage: Save auth token
            Controller->>Storage: Save refresh token
            Controller->>Storage: Save user data
            Controller->>Controller: Set userInfoModel
            Controller->>Controller: Set isGuestMode = false
            Controller->>Controller: Set isLoading = false
            Controller->>Dashboard: Navigate to home
            Dashboard-->>User: Show dashboard
        else Error (401)
            API-->>Controller: Invalid credentials
            Controller->>Controller: Set isLoading = false
            Controller->>LoginScreen: Show error
            LoginScreen-->>User: Invalid email or password
        else Error (403)
            API-->>Controller: Account suspended
            Controller->>Controller: Set isLoading = false
            Controller->>LoginScreen: Show error
            LoginScreen-->>User: Account suspended message
        else Network Error
            API-->>Controller: Connection failed
            Controller->>Controller: Set isLoading = false
            Controller->>LoginScreen: Show error
            LoginScreen-->>User: Network error message
        end
    end
```

## Registration Flow

```mermaid
sequenceDiagram
    participant User
    participant SignUpScreen as Sign Up Screen
    participant ImagePicker
    participant Controller as Auth Controller
    participant API as Auth API
    participant VerificationScreen as Verification Screen
    participant Dashboard
    
    User->>SignUpScreen: Fill registration form
    User->>SignUpScreen: Upload profile image (optional)
    
    alt Upload Image
        SignUpScreen->>ImagePicker: Pick image
        ImagePicker-->>SignUpScreen: Image file
        SignUpScreen->>SignUpScreen: Crop & compress
    end
    
    User->>SignUpScreen: Accept terms & conditions
    User->>SignUpScreen: Click Sign Up
    
    SignUpScreen->>SignUpScreen: Validate form
    
    alt Invalid Form
        SignUpScreen-->>User: Show validation errors
    else Valid Form
        SignUpScreen->>Controller: registration(signUpBody)
        Controller->>API: POST /auth/register
        
        alt Registration Success
            API-->>Controller: {token, user, is_phone_verified}
            
            alt Phone Not Verified
                Controller->>VerificationScreen: Navigate with phone
                VerificationScreen->>API: Send OTP
                API-->>VerificationScreen: OTP sent
                VerificationScreen-->>User: Enter OTP screen
                
                User->>VerificationScreen: Enter OTP
                VerificationScreen->>API: POST /auth/verify-phone
                
                alt OTP Valid
                    API-->>Controller: Verification success
                    Controller->>Controller: Save tokens & user data
                    Controller->>Dashboard: Navigate to home
                    Dashboard-->>User: Show dashboard
                else OTP Invalid
                    API-->>VerificationScreen: Invalid OTP
                    VerificationScreen-->>User: Show error
                end
                
            else Phone Pre-Verified
                Controller->>Controller: Save tokens & user data
                Controller->>Dashboard: Navigate to home
                Dashboard-->>User: Show dashboard
            end
            
        else Registration Error
            API-->>Controller: Error (email exists, etc)
            Controller-->>SignUpScreen: Show error
            SignUpScreen-->>User: Display error message
        end
    end
```

## Social Login Flow

```mermaid
sequenceDiagram
    participant User
    participant LoginScreen as Login Screen
    participant SocialSDK as Social Auth SDK
    participant Controller as Auth Controller
    participant API as Backend API
    participant Storage as Shared Preferences
    participant Dashboard
    
    User->>LoginScreen: Click Google/Facebook/Apple
    LoginScreen->>SocialSDK: Initiate OAuth
    SocialSDK-->>User: Show consent screen
    
    User->>SocialSDK: Grant permission
    
    alt User Approves
        SocialSDK-->>LoginScreen: {token, email, id, name}
        LoginScreen->>Controller: socialLogin(socialBody)
        
        Controller->>API: POST /auth/social-login
        Note over API: Create account if new user<br/>Link if existing user
        
        alt Login Success
            API-->>Controller: {token, user}
            Controller->>Storage: Save auth token
            Controller->>Storage: Save user data
            Controller->>Controller: Update state
            Controller->>Dashboard: Navigate to home
            Dashboard-->>User: Show dashboard
        else Login Error
            API-->>Controller: Error response
            Controller-->>LoginScreen: Show error
            LoginScreen-->>User: Social login failed
        end
        
    else User Cancels
        SocialSDK-->>LoginScreen: User cancelled
        LoginScreen-->>User: Stay on login screen
    else OAuth Error
        SocialSDK-->>LoginScreen: OAuth error
        LoginScreen-->>User: Show error message
    end
```

## Phone Verification Flow

```mermaid
stateDiagram-v2
    [*] --> SendOTP: Enter Phone Number
    SendOTP --> WaitingForOTP: OTP Sent via SMS
    
    WaitingForOTP --> EnterOTP: User Receives SMS
    EnterOTP --> ValidateOTP: Submit OTP
    
    ValidateOTP --> Verified: OTP Correct
    ValidateOTP --> InvalidOTP: OTP Incorrect
    
    InvalidOTP --> RetryLimit: Check Attempts
    RetryLimit --> EnterOTP: < 3 attempts
    RetryLimit --> Locked: >= 3 attempts
    
    WaitingForOTP --> ResendOTP: Didn't Receive
    ResendOTP --> TimerCheck: Check Timer
    
    TimerCheck --> SendOTP: Timer Expired (60s)
    TimerCheck --> WaitingForOTP: Timer Active
    
    Locked --> [*]: Account Locked
    Verified --> SaveData: Save User Data
    SaveData --> [*]: Complete
```

## Session Management

```mermaid
graph TB
    AppLaunch[App Launch] --> CheckSession[Check Stored Session]
    
    CheckSession --> HasToken{Has Auth Token?}
    
    HasToken -->|No| GuestMode[Continue as Guest]
    HasToken -->|Yes| ValidateToken[Validate Token]
    
    ValidateToken --> TokenValid{Token Valid?}
    
    TokenValid -->|Yes| LoadUserData[Load User Data]
    TokenValid -->|No| CheckRefresh{Has Refresh Token?}
    
    CheckRefresh -->|Yes| RefreshToken[Refresh Auth Token]
    CheckRefresh -->|No| ClearSession[Clear Session]
    
    RefreshToken --> RefreshSuccess{Refresh Success?}
    
    RefreshSuccess -->|Yes| SaveNewToken[Save New Token]
    RefreshSuccess -->|No| ClearSession
    
    SaveNewToken --> LoadUserData
    ClearSession --> LoginScreen[Show Login Screen]
    
    LoadUserData --> Dashboard[Show Dashboard]
    GuestMode --> Dashboard
    
    Dashboard --> UserAction[User Activity]
    UserAction --> APICall[API Request]
    
    APICall --> CheckAuth{Authorized?}
    
    CheckAuth -->|Yes| Success[Continue]
    CheckAuth -->|No 401| AutoRefresh[Auto Refresh Token]
    
    AutoRefresh --> RefreshSuccess
    
    Success --> UserAction
    
    style Dashboard fill:#90EE90
    style ClearSession fill:#FFB6C1
    style RefreshToken fill:#FFE4B5
```

## Logout Flow

```mermaid
sequenceDiagram
    participant User
    participant UI
    participant Controller as Auth Controller
    participant CartController
    participant FavController
    participant Storage as Shared Preferences
    participant API as Backend API
    participant LoginScreen as Login Screen
    
    User->>UI: Click Logout
    UI->>Controller: logout()
    
    Controller->>Controller: Set isLoading = true
    
    par Clear User Data
        Controller->>Storage: Clear auth token
        Controller->>Storage: Clear refresh token
        Controller->>Storage: Clear user data
    and Notify Backend
        Controller->>API: POST /auth/logout
        API-->>Controller: Logout confirmed
    and Clear App State
        Controller->>CartController: clearCart()
        Controller->>FavController: clearFavorites()
    end
    
    Controller->>Controller: Set userInfoModel = null
    Controller->>Controller: Set isGuestMode = true
    Controller->>Controller: Set isLoading = false
    
    Controller->>LoginScreen: Navigate to login
    LoginScreen-->>User: Show login screen
    
    Note over User,LoginScreen: User logged out successfully
```

## Password Reset Flow

```mermaid
flowchart TD
    ForgotPassword[Forgot Password Link] --> EnterEmail[Enter Email/Phone]
    
    EnterEmail --> ValidateEmail{Valid?}
    ValidateEmail -->|No| EmailError[Show Error]
    EmailError --> EnterEmail
    
    ValidateEmail -->|Yes| SendResetCode[Send Reset Code]
    SendResetCode --> CodeSent[Code Sent via SMS/Email]
    
    CodeSent --> EnterCode[Enter Reset Code]
    EnterCode --> VerifyCode{Code Valid?}
    
    VerifyCode -->|No| CodeError[Show Error]
    CodeError --> ResendCode{Resend?}
    ResendCode -->|Yes| SendResetCode
    ResendCode -->|No| EnterCode
    
    VerifyCode -->|Yes| EnterNewPassword[Enter New Password]
    EnterNewPassword --> ValidatePassword{Strong Password?}
    
    ValidatePassword -->|No| PasswordError[Show Requirements]
    PasswordError --> EnterNewPassword
    
    ValidatePassword -->|Yes| ResetPassword[Reset Password API]
    ResetPassword --> ResetSuccess{Success?}
    
    ResetSuccess -->|Yes| AutoLogin[Auto Login]
    ResetSuccess -->|No| ResetError[Show Error]
    
    AutoLogin --> Dashboard[Navigate to Dashboard]
    ResetError --> EnterEmail
    
    style SendResetCode fill:#87CEEB
    style ResetPassword fill:#FFE4B5
    style Dashboard fill:#90EE90
```

## Multi-Device Session Handling

```mermaid
graph TB
    User[User Login] --> Device1[Device 1]
    User --> Device2[Device 2]
    User --> Device3[Device 3]
    
    Device1 --> Token1[Token 1]
    Device2 --> Token2[Token 2]
    Device3 --> Token3[Token 3]
    
    Token1 --> Backend[Backend Session Manager]
    Token2 --> Backend
    Token3 --> Backend
    
    Backend --> SessionLimit{Max Sessions?}
    
    SessionLimit -->|Under Limit| AllowAll[Allow All Sessions]
    SessionLimit -->|Over Limit| PolicyCheck{Session Policy}
    
    PolicyCheck -->|Last In| InvalidateOld[Invalidate Oldest]
    PolicyCheck -->|Specific Device| InvalidateOther[Invalidate Other Devices]
    PolicyCheck -->|Ask User| UserChoose[User Chooses Which Session]
    
    InvalidateOld --> Device1Logout[Logout Device 1]
    InvalidateOther --> Device2Logout[Logout Device 2]
    InvalidateOther --> Device3Logout[Logout Device 3]
    
    AllowAll --> ActiveSessions[All Sessions Active]
    Device1Logout --> TwoActive[Device 2 & 3 Active]
    
    style Backend fill:#87CEEB
    style AllowAll fill:#90EE90
    style InvalidateOld fill:#FFB6C1
```
