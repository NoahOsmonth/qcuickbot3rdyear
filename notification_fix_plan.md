# Plan: Fix Notification Read Status and Count

## Summary of Findings

1.  **Missing State:** The `notifications` table and the `NotificationItem` model lack an `is_read` field to track the read status.
2.  **Incorrect Action:** The "Mark as read" action in `NotificationDetailScreen` deletes the notification instead of updating its status.
3.  **Incorrect Count Calculation:** `NotificationIconButton` counts *all* notifications fetched by the service, not just unread ones, because the service fetches everything without filtering by read status.

## Proposed Plan Steps

1.  **Database (`supabase_tables.sql`):**
    *   Add an `is_read` column (boolean, default `false`) to the `notifications` table.
    *   Add the following SQL:
        ```sql
        -- Add is_read column to notifications table
        alter table notifications
        add column is_read boolean default false not null;

        -- Optional: Create an index for faster querying of unread notifications
        create index ix_notifications_user_id_is_read on notifications (user_id, is_read);

        -- Update RLS policy for update (if needed, depends on requirements)
        -- Example: Allow users to update their own notifications (specifically is_read)
        create policy notifications_update on notifications
          for update using ( auth.uid() = user_id ) with check ( auth.uid() = user_id );
        ```
2.  **Model (`lib/models/notification_model.dart`):**
    *   Add an `is_read` field to the `NotificationItem` class.
    *   Update `fromMap` and `toMap` to handle the new field.
3.  **Service (`lib/services/notification_service.dart`):**
    *   Modify `_fetchNotifications` to fetch *all* notifications but include the `is_read` status.
    *   Add a new method `markNotificationAsRead(String notificationId)` that updates the `is_read` field to `true` for a given notification ID in the database.
    *   Adjust the real-time subscription (`subscribeNotifications`) to listen for `UPDATE` events as well, so the stream updates when `is_read` changes.
4.  **Provider (`lib/providers/notification_provider.dart`):**
    *   Introduce a new provider `unreadNotificationCountProvider` that filters the main notification stream (`notificationsProvider`) to count only items where `is_read` is `false`.
    *   Provide a way to call the `markNotificationAsRead` service method (e.g., by exposing the `NotificationService` instance or creating a dedicated function within a `StateNotifier`).
5.  **UI Widgets:**
    *   `NotificationIconButton`: Change it to watch `unreadNotificationCountProvider` to display the count of *unread* notifications.
    *   `NotificationDetailScreen`: Modify the action button's `onPressed` handler (`_markAsRead`) to call the new `markNotificationAsRead` service method instead of deleting the notification. Consider calling this automatically when the screen is opened (`initState` or similar).
    *   `NotificationScreen`: Optionally, use the `is_read` flag to visually differentiate read/unread items in the list (e.g., grey out read items).

## Visual Plan

```mermaid
graph TD
    subgraph Database (Supabase)
        A[notifications Table] -- 1. Add is_read column --> B(Updated notifications Table: +is_read BOOLEAN DEFAULT false)
    end

    subgraph Backend Logic (Dart/Flutter)
        C[NotificationItem Model] -- 2. Add is_read field --> D(Updated NotificationItem Model)
        E[NotificationService] -- 3a. Modify fetch logic --> F(Fetch includes is_read)
        E -- 3b. Add markAsRead method --> G(Update is_read=true in DB)
        E -- 3c. Listen for UPDATE events --> H(Real-time updates for is_read)
        I[NotificationProvider] -- 4a. Create unread count provider --> J(Unread Count Stream)
        I -- 4b. Expose markAsRead --> K(Mark As Read Action Trigger)
    end

    subgraph UI (Flutter Widgets)
        L[NotificationIconButton] -- 5a. Use Unread Count Stream --> M(Display Correct Unread Count)
        N[NotificationDetailScreen] -- 5b. Call Mark As Read Action --> O(Mark notification as read via Service)
        P[NotificationScreen] -- 5c. Optional: Differentiate read/unread --> Q(Updated List UI)
    end

    B --> D
    B --> F
    B --> G
    D --> F
    F & H --> J
    G --> K
    J --> M
    K --> O

    User --> N -- Taps 'Mark as Read' / Screen Opens --> O
    User --> L -- Sees count --> M