# Plan: Implement Chat Management & Voice Input

## Phase 1: Database & Backend Setup

1.  **Modify `chat_sessions` Table (Supabase SQL):**
    *   Add `is_pinned` column (BOOLEAN, default FALSE, NOT NULL).
    *   Add `is_archived` column (BOOLEAN, default FALSE, NOT NULL).
    *   *(Deletion remains handled by cascade).*
2.  **Update/Create `ChatSessionService` (`lib/services/chat_session_service.dart`):**
    *   Create functions:
        *   `updatePinStatus(sessionId, isPinned)`
        *   `updateArchiveStatus(sessionId, isArchived)`
        *   `deleteSession(sessionId)`
3.  **Update `ChatHistoryProvider` (`lib/providers/chat_history_provider.dart`):**
    *   Modify `ChatHistoryState` to hold separate lists or filter logic for pinned, active, and archived chats.
    *   Adjust `fetchSessions` to retrieve `is_pinned` and `is_archived`, ordering by `is_pinned` descending, then `created_at` descending.
    *   Add methods in `ChatHistoryNotifier` (e.g., `pinSession`, `archiveSession`, `deleteSession`) to call service functions and update state.

## Phase 2: UI Implementation - Chat Management

1.  **Modify `ChatHistoryList` (`lib/widgets/drawer/chat_history_list.dart`):**
    *   Update list building logic:
        *   Display pinned chats first (already handled by fetch order).
        *   Display active (non-archived) chats next.
        *   Add a separate, potentially expandable, section at the bottom for archived chats.
    *   Add UI interactions (e.g., long-press menu or swipe actions) to trigger `pinSession`, `archiveSession`, `deleteSession`.

## Phase 3: UI Implementation - Voice Input

1.  **Add Dependencies:**
    *   Add `speech_to_text` package to `pubspec.yaml`.
2.  **Configure Permissions:**
    *   Add microphone usage descriptions to `Info.plist` (iOS) and `AndroidManifest.xml` (Android).
3.  **Modify `ChatInputBar` (`lib/widgets/chat_input_bar.dart`):**
    *   Convert to `ConsumerStatefulWidget`.
    *   Add state for speech recognition status.
    *   Add a microphone `IconButton`.
    *   Initialize `speech_to_text`, request permissions.
    *   Implement functions to start/stop listening.
    *   On result, **replace** text in `_controller` with recognized speech.
    *   Add visual feedback for listening state.

## Phase 4: Testing & Refinement

1.  Test pinning, archiving, deleting, voice input, and permissions.
2.  Refine UI/UX.
3.  Ensure modularity.

## Diagram: Feature Integration Points

```mermaid
graph LR
    subgraph Database (Supabase)
        D[chat_sessions table <br>+ is_pinned <br>+ is_archived]
    end

    subgraph Backend Services
        S[ChatSessionService <br>+ updatePinStatus <br>+ updateArchiveStatus <br>+ deleteSession]
    end

    subgraph State Management (Riverpod)
        P[ChatHistoryProvider <br>+ State updates <br>+ Action methods]
    end

    subgraph UI Widgets
        subgraph Drawer
            DL[ChatHistoryList <br>+ Display logic (pinned/active/archived) <br>+ Action triggers (long-press/icons)]
        end
        subgraph Chat Screen
            CI[ChatInputBar <br>+ Mic Button <br>+ Speech-to-text logic <br>+ Permission handling]
        end
    end

    subgraph External Dependencies
        STT[speech_to_text package]
        Perm[Platform Permissions (Mic)]
    end

    D --> S;
    S --> P;
    P --> DL;
    DL --> P;
    CI --> P;
    CI --> STT;
    CI --> Perm;