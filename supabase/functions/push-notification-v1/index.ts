import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as djwt from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  try {
    // 1. Ambil Env (Gunakan bawaan Supabase jika memungkinkan)
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const FB_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")!;
    const FB_EMAIL = Deno.env.get("FIREBASE_CLIENT_EMAIL")!;
    const FB_PRIVATE_KEY = Deno.env.get("FIREBASE_PRIVATE_KEY")?.replace(/\\n/g, "\n")!;

    const supabase = createClient(SUPABASE_URL, SERVICE_KEY);
    const { user_id, title, body: message, data = {} } = await req.json();

    // 2. Ambil Token FCM dari DB
    const { data: devices } = await supabase
      .from("user_devices")
      .select("fcm_token")
      .eq("user_id", user_id);

    if (!devices || devices.length === 0) {
      return new Response(JSON.stringify({ ok: true, sent: 0 }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    // 3. Generate Access Token via djwt (Lebih aman untuk Deno)
    const pemKey = await crypto.subtle.importKey(
      "pkcs8",
      Uint8Array.from(atob(FB_PRIVATE_KEY.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\n/g, "")), (c) => c.charCodeAt(0)),
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const jwt = await djwt.create(
      { alg: "RS256", typ: "JWT" },
      {
        iss: FB_EMAIL,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: "https://oauth2.googleapis.com/token",
        exp: djwt.getNumericDate(3600),
        iat: djwt.getNumericDate(0),
      },
      pemKey
    );

    const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: jwt }),
    });
    const { access_token } = await tokenRes.json();

    // 4. Kirim secara Paralel (Promise.all) agar tidak lambat jika device banyak
    const sendRequests = devices.map(async (d) => {
      // Pastikan semua data adalah STRING
      const stringData: Record<string, string> = {};
      Object.keys(data).forEach(key => stringData[key] = String(data[key]));

      return fetch(`https://fcm.googleapis.com/v1/projects/${FB_PROJECT_ID}/messages:send`, {
        method: "POST",
        headers: { Authorization: `Bearer ${access_token}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          message: {
            token: d.fcm_token,
            notification: { title, body: message },
            data: stringData
          }
        }),
      });
    });

    const results = await Promise.all(sendRequests);
    const success = results.filter(r => r.ok).length;

    return new Response(JSON.stringify({ ok: true, success, failed: devices.length - success }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    });

  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: corsHeaders });
  }
});