import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Body = {
  user_id: string;
  role: string; // contoh: "admin"
};

Deno.serve(async (req) => {
  try {
    // 1) Ambil JWT user yang memanggil function (supaya bisa kita cek siapa pemanggilnya)
    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "").trim();

    if (!jwt) {
      return new Response(JSON.stringify({ error: "Missing Authorization Bearer token" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 2) Client untuk verifikasi user pemanggil (pakai anon key)
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabaseUser = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: `Bearer ${jwt}` } },
    });

    const { data: userData, error: userErr } = await supabaseUser.auth.getUser();
    if (userErr || !userData?.user) {
      return new Response(JSON.stringify({ error: "Invalid user token" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 3) Cek apakah pemanggil adalah admin (role ada di app_metadata JWT)
    const callerRole = userData.user.app_metadata?.role;
    if (callerRole !== "admin") {
      return new Response(JSON.stringify({ error: "Forbidden: admin only" }), {
        status: 403,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 4) Ambil body request
    const { user_id, role } = (await req.json()) as Body;
    if (!user_id || !role) {
      return new Response(JSON.stringify({ error: "user_id and role are required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 5) Client admin (service role) untuk update app_metadata target user
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    const { data, error } = await supabaseAdmin.auth.admin.updateUserById(user_id, {
      app_metadata: { role },
    });

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true, user: data.user }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
