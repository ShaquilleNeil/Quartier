# Quartier Project Architecture

## Project Overview
* **Application:** Quartier (iOS)
* **Architecture Pattern:** MVVM (Model-View-ViewModel) + Service Layer
* **Backend:** Firebase (Authentication, Firestore Database)
* **Minimum Target:** iOS 16.0+

## Directory Structure & Responsibilities

### 1. Root Directory
* **QuartierApp.swift**: Application entry point. Configures Firebase setup on launch.
* **ContentView.swift**: The root view coordinator. Responsible for routing users based on `AuthService` state (Login vs. Home).
* **Assets.xcassets**: Contains app icons (`AppIcon`), color sets (`AccentColor`), and static images.

### 2. Models (Data Layer)
Located in `Quartier/Model/`
Defines the data structures used throughout the application.

* **User.swift**: Base class/struct. Contains shared attributes (ID, email, profile image).
* **Tenant.swift**: Inherits from `User`. Contains tenant-specific data (budget, saved listings).
* **Landlord.swift**: Inherits from `User`. Contains landlord-specific data (owned buildings).
* **Enum/UserType.swift**: Enumeration defining the two primary roles (`.tenant`, `.landlord`).

### 3. Services (Logic Layer)
Located in `Quartier/Services/`
Handles backend communication.

* **AuthService.swift**: Manages authentication (Sign In, Sign Up via Email/Google). Publishes `userSession` and `currentUser`.
* **FirebaseManager.swift**: Singleton for Firestore operations (saving users, updating preferences).

### 4. Views (UI Layer)
Located in `Quartier/Views/`

#### Shared Components (`Views/`)
* **DesignHelpers.swift**: Contains shared UI components (`SocialButton`, `QuartierFieldModifier`) and extensions (e.g., `Color(hex:)`) used across multiple screens.

#### Authentication (`Views/Authentication/`)
* **LoginSwitch.swift**: Top-level switcher that toggles between Tenant and Landlord login forms.
* **TenantLogin.swift**: Login form specific to tenants.
* **LandlordLogin.swift**: Login form specific to landlords.
* **SignUp.swift**: User registration screen with role selection.

#### Tenant Feature Set (`Views/TenantViews/`)
* **TenantPreferencesView.swift**: **(New)** Onboarding screen for capturing budget, location, and housing needs.
* **TenantTabView.swift**: Main container (Tab Bar) for the Tenant UI.
* **TenantHome.swift**: Dashboard/Feed.
* **TenantDiscover.swift**: Search and Map interface.
* **TenantSaved.swift**: Saved listings.
* **TenantSchedule.swift**: Viewing appointments.
* **TenantProfile.swift**: Settings and profile management.

#### Landlord Feature Set (`Views/LandlordViews/`)
* **LandlordTabView.swift**: Main container for the Landlord UI.
* **LandlordHome.swift**: Dashboard showing properties and stats.
* **LandlordListings.swift**: Inventory management.
* **LandlordMessages.swift**: Inbox for tenant inquiries.
* **LandlordSchedule.swift**: Calendar for viewings.
* **LandlordProfile.swift**: Account management.

### 5. Legacy / Template Files
* **Persistence.swift** & **Quartier.xcdatamodeld**: CoreData files (unused/deprecated).

## Navigation Flow
1. **Launch**: `QuartierApp` initializes Firebase.
2. **Auth Check**: `ContentView` observes `AuthService`.
   * **If Unauthenticated**: Show `LoginSwitch` (defaulting to Tenant Login).
   * **If Authenticated**: Check `UserType` and Onboarding Status.
     * **New Tenant**: Show `TenantPreferencesView` (Profile Setup).
     * **Existing Tenant**: Show `TenantTabView`.
     * **Landlord**: Show `LandlordTabView`.
