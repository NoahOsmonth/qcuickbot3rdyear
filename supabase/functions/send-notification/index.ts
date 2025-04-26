// supabase/functions/send-push-notification/index.ts

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { GoogleAuth } from 'npm:google-auth-library@8.8.0' // Using v0.4.0 as an example, check for latest compatible version

// --- Interfaces matching your table structure ---
interface NotificationRecord {
  id: string; // uuid
  user_id: string; // uuid - The user this notification is for
  title: string; // text
  body: string; // text
  created_at: string; // timestamptz
  is_read: boolean; // bool
  // Add any other columns from your notification table if needed
}

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE'; // We only care about INSERT
  table: string;
  schema: string;
  record: NotificationRecord;
  old_record: null | NotificationRecord;
}

interface UserDevice {
    fcm_token: string;
}

// --- Main Function ---
serve(async (req) => {
  console.log("--- send-push-notification function invoked ---");

  // --- 1. Initialize Supabase Client ---
  // IMPORTANT: Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY (recommended for backend functions)
  // or SUPABASE_ANON_KEY in your function's environment variables in the Supabase dashboard.
  // Service Role Key bypasses RLS, which might be needed to query fcm_tokens for any user. Use with caution.
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'); // Preferred for backend functions

  if (!supabaseUrl || !supabaseServiceRoleKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env variables.");
    return new Response(JSON.stringify({ error: 'Internal configuration error (Supabase client)' }), { status: 500, headers: { 'Content-Type': 'application/json' } });
  }

  // Note: We don't need to pass the Authorization header from the original request
  // when using the service role key, as it has full access.
  const supabaseClient: SupabaseClient = createClient(supabaseUrl, supabaseServiceRoleKey);
  console.log("Supabase client initialized.");

  // --- 2. Retrieve and Parse Firebase Service Account JSON from Secrets ---
  const serviceAccountJsonString = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (!serviceAccountJsonString) {
    console.error("FCM_SERVICE_ACCOUNT_JSON secret not found in environment variables.");
    return new Response(JSON.stringify({ error: 'Internal configuration error (FCM credentials)' }), { status: 500, headers: { 'Content-Type': 'application/json' } });
  }

  let serviceAccountCredentials;
  let projectId: string | undefined;
  try {
    serviceAccountCredentials = JSON.parse(serviceAccountJsonString);
    projectId = serviceAccountCredentials.project_id;
    if (!projectId) {
        throw new Error("project_id not found in service account credentials.");
    }
    console.log(`Parsed service account credentials for project: ${projectId}`);
  } catch (e) {
    console.error("Failed to parse FCM_SERVICE_ACCOUNT_JSON:", e);
    return new Response(JSON.stringify({ error: 'Internal configuration error (FCM credential parsing)' }), { status: 500, headers: { 'Content-Type': 'application/json' } });
  }

  // --- 3. Process Incoming Webhook Payload ---
  try {
    const payload = await req.json() as WebhookPayload;
    console.log("Received webhook payload:", JSON.stringify(payload, null, 2));

    // Only process new rows inserted into the notification table
    if (payload.type !== 'INSERT' || !payload.record) {
      console.log(`Payload type is ${payload.type}, not INSERT or record is null. Skipping.`);
      return new Response(JSON.stringify({ message: "Skipped, not an INSERT operation or no record." }), { status: 200, headers: { 'Content-Type': 'application/json' } });
    }

    const newNotification = payload.record;
    const targetUserId = newNotification.user_id;
    const notificationTitle = newNotification.title;
    const notificationBody = newNotification.body;

    if (!targetUserId) {
      console.error("Notification record is missing the 'user_id'. Cannot determine target.");
      // Acknowledge receipt but indicate error client-side if possible
      return new Response(JSON.stringify({ error: "Notification record missing user_id" }), { status: 400, headers: { 'Content-Type': 'application/json' } });
    }
    console.log(`Processing notification for user: ${targetUserId}`);

    // --- 4. Fetch FCM Tokens for the Target User ---
    console.log(`Querying 'user_devices' table for user_id: ${targetUserId}`);
    const { data: devices, error: deviceError } = await supabaseClient
      .from('user_devices')
      .select('fcm_token') // Select only the token column
      .eq('user_id', targetUserId); // Filter by the user_id from the notification

    if (deviceError) {
      console.error(`Database error fetching devices for user ${targetUserId}:`, deviceError);
      throw new Error(`Database error: ${deviceError.message}`);
    }

    if (!devices || devices.length === 0) {
      console.log(`No devices/tokens found for user ${targetUserId} in 'user_devices' table.`);
      // No devices to send to, so the operation is technically "successful" in that there's nothing more to do.
      return new Response(JSON.stringify({ message: `No registered devices found for user ${targetUserId}.` }), { status: 200, headers: { 'Content-Type': 'application/json' } });
    }

    // Filter out any null/empty tokens just in case
    const validTokens = devices
        .map((d: UserDevice) => d.fcm_token)
        .filter((token): token is string => token !== null && token !== '');

    if (validTokens.length === 0) {
        console.log(`No *valid* FCM tokens found for user ${targetUserId} after filtering.`);
        return new Response(JSON.stringify({ message: `No valid devices found for user ${targetUserId}.` }), { status: 200, headers: { 'Content-Type': 'application/json' } });
    }

    console.log(`Found ${validTokens.length} valid FCM token(s) for user ${targetUserId}.`);

    // --- 5. Obtain Google OAuth Access Token ---
    console.log("Requesting Google OAuth access token...");
    const scopes = ["https://www.googleapis.com/auth/firebase.messaging"];
    const auth = new GoogleAuth({
      credentials: serviceAccountCredentials,
      scopes: scopes,
    });
    const accessToken = await auth.getAccessToken();

    if (!accessToken) {
      console.error("Failed to obtain Google OAuth access token.");
      throw new Error("Could not get access token from Google.");
    }
    console.log("Successfully obtained Google OAuth access token.");

    // --- 6. Send Notification to Each Token ---
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
    const results = [];

    console.log(`Attempting to send notifications to ${validTokens.length} token(s)...`);
    for (const token of validTokens) {
      const fcmMessage = {
        message: {
          token: token, // Target specific device token
          notification: {
            title: notificationTitle,
            body: notificationBody,
          },
          // Optional: Android specific config
          // android: {
          //   notification: {
          //     sound: 'default' // Example
          //   }
          // },
          // Optional: APNS specific config (iOS)
          // apns: {
          //   payload: {
          //     aps: {
          //       sound: 'default' // Example
          //     }
          //   }
          // }
        },
      };

      try {
        console.log(`Sending FCM message to token: ...${token.slice(-10)}`); // Log last part of token for privacy
        const response = await fetch(fcmEndpoint, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(fcmMessage),
        });

        const responseData = await response.json(); // Try to parse JSON regardless of status

        if (!response.ok) {
          console.warn(`FCM send failed for token ...${token.slice(-10)} (${response.status}):`, JSON.stringify(responseData));
          results.push({ token: `...${token.slice(-10)}`, status: 'failed', error: responseData });
          // Potentially handle specific errors like "Unregistered" or "InvalidRegistration"
          // to clean up stale tokens from the user_devices table later.
        } else {
          console.log(`FCM send successful for token ...${token.slice(-10)}:`, JSON.stringify(responseData));
          results.push({ token: `...${token.slice(-10)}`, status: 'success', response: responseData });
        }
      } catch (fetchError) {
        console.error(`Error during fetch for token ...${token.slice(-10)}:`, fetchError);
        results.push({ 
          token: `...${token.slice(-10)}`, 
          status: 'error', 
          error: (fetchError && typeof fetchError === 'object' && 'message' in fetchError) ? (fetchError as { message: string }).message : String(fetchError)
        });
      }
    } // End loop through tokens

    console.log("Finished sending notifications. Summary:", JSON.stringify(results));
    // Determine overall success - could be more nuanced
    const allSucceeded = results.every(r => r.status === 'success');

    return new Response(JSON.stringify({ success: allSucceeded, results: results }), {
      status: 200, // Return 200 even if some sends failed, as the function itself completed.
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (error) {
    // --- 7. Catch-All Error Handling ---
    console.error("Unhandled error in Edge Function:", error);
    const errorMessage = (error && typeof error === 'object' && 'message' in error)
      ? (error as { message: string }).message
      : 'An unexpected error occurred.';
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
})

console.log("--- send-push-notification function script loaded ---");