# Iteration Summary: Landlord Features

This iteration implements the main landlord flows and wires them to Core Data, plus fixes for merge conflicts and build errors.

## What Was Implemented

**1. Listings**  
- List is loaded from Core Data (LDListing) with filters (All / Published / Drafts / Rented) and search.  
- **Create**: FAB opens a form (title, city, monthly rent, beds/baths, status, cover icon); save creates an LDListing.  
- **Edit / Delete**: Tap a card to edit; long-press context menu to edit or delete.

**2. Notices**  
- “Send Notice” from the bell icon on Home.  
- Scope: All apartments or multiple selected; title and body are saved via NoticeService and pushed to relevant conversations.

**3. Schedules**  
- Scheduler shows real events from Core Data; FAB adds a new event.  
- New event: scope (all or selected apartments), title, date/time (including all-day), notes; saved via ScheduleEventService and pushed to conversations.  
- **Sync with tenant**: Tenant sees events that apply to them (scope “all” or their tenancy’s listing) via TenantScheduleService.

**4. Tasks**  
- Home “Tasks” section uses Core Data (LDTask) instead of static data.  
- **CRUD**: Add (+), toggle done, tap row or context menu to edit, long-press to delete; optional due date and related listing.

**5. Messages**  
- Conversation list is loaded from LDConversation (sorted by last message).  
- Tapping a row opens the chat: messages from LDMessage (text + system notice/schedule), send new text and update conversation summary and unread.

**6. Other**  
- Resolved ContentView and QuartierApp merge conflicts; kept role-based routing and injected Core Data context.  
- Added missing imports (AuthService + Combine, ContentView + CoreData, LandlordProfile + FirebaseAuth).  
- Fixed NewTaskView: LDTask.listing is to-many (NSSet); fixed LandlordMessages by removing Hashable from LDConversation and using `NavigationLink(destination:)` to avoid compile errors.

## Tech Notes

- **Data**: Firebase (Auth + user role), Core Data (LDListing, LDConversation, LDMessage, LDTask, LDNotice, LDScheduleEvent, etc.).  
- Listings, notices, schedules, tasks, and messages all use Core Data and existing services (e.g. NoticeService, ScheduleEventService); no hardcoded mock data.
