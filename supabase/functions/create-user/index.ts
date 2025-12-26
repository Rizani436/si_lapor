import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, content-type",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
      },
    });
  }

  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }

    const PROJECT_URL = Deno.env.get("PROJECT_URL");
    const SERVICE_ROLE_KEY = Deno.env.get("SERVICE_ROLE_KEY");
    const ANON_KEY = Deno.env.get("ANON_KEY");

    if (!PROJECT_URL || !SERVICE_ROLE_KEY || !ANON_KEY) {
      return new Response(
        JSON.stringify({ error: "Missing env: PROJECT_URL/SERVICE_ROLE_KEY/ANON_KEY" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    if (!authHeader.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Missing bearer token" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabaseUserClient = createClient(PROJECT_URL, ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userData, error: userErr } = await supabaseUserClient.auth.getUser();
    if (userErr || !userData?.user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const callerId = userData.user.id;

    const { data: callerProfile, error: callerProfileErr } = await supabaseUserClient
      .from("profiles")
      .select("role")
      .eq("id", callerId)
      .maybeSingle();

    if (callerProfileErr) {
      return new Response(JSON.stringify({ error: callerProfileErr.message }), {
        status: 403,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (callerProfile?.role !== "admin") {
      return new Response(JSON.stringify({ error: "Forbidden: admin only" }), {
        status: 403,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const email = (body?.email ?? "").toString().trim().toLowerCase();
    const password = (body?.password ?? "").toString();
    const nama_lengkap = (body?.nama_lengkap ?? "").toString().trim();
    const no_hp = (body?.no_hp ?? "").toString().trim();
    const role = (body?.role ?? "parent").toString().trim();

    const allowedRoles = new Set(["admin", "guru", "kepsek", "parent"]);

    if (!email || !email.includes("@")) {
      return new Response(JSON.stringify({ error: "Invalid email" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }
    if (!nama_lengkap) {
      return new Response(JSON.stringify({ error: "nama_lengkap is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }
    if (!no_hp) {
      return new Response(JSON.stringify({ error: "no_hp is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }
    if (!password || password.length < 6) {
      return new Response(JSON.stringify({ error: "Password minimal 6 karakter" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }
    if (!allowedRoles.has(role)) {
      return new Response(JSON.stringify({ error: "Invalid role" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(PROJECT_URL, SERVICE_ROLE_KEY);

    const { data: created, error: createErr } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      phone: no_hp,          
      email_confirm: true, 
      user_metadata: {
        nama_lengkap,
        role,
      },
    });

    if (createErr || !created?.user) {
      return new Response(JSON.stringify({ error: createErr?.message ?? "Create user failed" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const newUserId = created.user.id;

    const { error: upsertErr } = await supabaseAdmin.from("profiles").upsert({
      id: newUserId,
      email,
      nama_lengkap,
      no_hp,
      role,
      is_active: true,
      foto_profile: null,
    });

    if (upsertErr) {
      await supabaseAdmin.auth.admin.deleteUser(newUserId);
      return new Response(JSON.stringify({ error: upsertErr.message }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true, user_id: newUserId }), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }
});
