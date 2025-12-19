import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  // CORS
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
        JSON.stringify({
          error: "Missing env: PROJECT_URL/SERVICE_ROLE_KEY/ANON_KEY",
        }),
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

    // Client pemanggil (admin login) untuk cek role
    const supabaseUserClient = createClient(PROJECT_URL, ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userData, error: userErr } =
      await supabaseUserClient.auth.getUser();

    if (userErr || !userData?.user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const callerId = userData.user.id;

    // Cek role caller = admin
    const { data: callerProfile, error: callerProfileErr } =
      await supabaseUserClient
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

    // Input
    const body = await req.json();
    const user_id = (body?.user_id ?? "").toString().trim();
    const email = body?.email != null ? body.email.toString().trim().toLowerCase() : null;
    const password = body?.password != null ? body.password.toString() : null;

    const nama_lengkap =
      body?.nama_lengkap != null ? body.nama_lengkap.toString().trim() : null;

    const no_hp =
      body?.no_hp != null ? body.no_hp.toString().trim() : null;

    const foto_profile =
      body?.foto_profile !== undefined ? body.foto_profile : undefined;

    if (!user_id) {
      return new Response(JSON.stringify({ error: "user_id is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (email !== null && (!email.includes("@") || email.length < 5)) {
      return new Response(JSON.stringify({ error: "Invalid email" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (password !== null && password.length > 0 && password.length < 6) {
      return new Response(JSON.stringify({ error: "Password minimal 6 karakter" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(PROJECT_URL, SERVICE_ROLE_KEY);

    // 1) Update AUTH (email/password) kalau ada
    if (email !== null || (password !== null && password.length > 0)) {
      const payload: { email?: string; password?: string } = {};
      if (email !== null) payload.email = email;
      if (password !== null && password.length > 0) payload.password = password;

      const { error: authUpdErr } =
        await supabaseAdmin.auth.admin.updateUserById(user_id, payload);

      if (authUpdErr) {
        return new Response(JSON.stringify({ error: authUpdErr.message }), {
          status: 400,
          headers: { "Content-Type": "application/json" },
        });
      }
    }

    // 2) Update PROFILES (nama/no_hp/foto) kalau ada
    const upd: Record<string, unknown> = {};
    if (email !== null) upd["email"] = email; // sync ke profiles.email
    if (nama_lengkap !== null) upd["nama_lengkap"] = nama_lengkap;
    if (no_hp !== null) upd["no_hp"] = no_hp;

    // foto_profile: kalau kamu kirim null -> set null, kalau undefined -> jangan diubah
    if (foto_profile !== undefined) {
      upd["foto_profile"] = foto_profile;
    }

    if (Object.keys(upd).length > 0) {
      const { error: profErr } = await supabaseAdmin
        .from("profiles")
        .update(upd)
        .eq("id", user_id);

      if (profErr) {
        return new Response(JSON.stringify({ error: profErr.message }), {
          status: 400,
          headers: { "Content-Type": "application/json" },
        });
      }
    }

    return new Response(JSON.stringify({ ok: true }), {
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
