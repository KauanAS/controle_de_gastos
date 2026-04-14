// supabase/functions/confirm-entry/index.ts
// Confirma e salva o lançamento após revisão do usuário
// Gera log de auditoria

import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    // ── Autenticação ──
    const supabase = getSupabaseClient(req);
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Não autorizado" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json();
    const {
      tipo_lancamento, // "despesa" ou "receita"
      id_local,
      descricao,
      categoria,
      valor,
      pagamento,
      data_hora,
      texto_original,
      origem_input,     // "manual", "texto", "audio", "imagem"
      ai_confidence,
      ai_raw_response,
      observacao,
    } = body;

    // ── Validações ──
    if (!descricao || !valor || !id_local) {
      return new Response(
        JSON.stringify({ error: "descricao, valor e id_local são obrigatórios" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let resultado;

    if (tipo_lancamento === "receita") {
      // ── Inserir receita ──
      const { data, error } = await supabase
        .from("receitas")
        .insert({
          user_id: user.id,
          id_local,
          descricao,
          valor,
          categoria: categoria ?? "outros",
          data_ocorrencia: data_hora ?? new Date().toISOString(),
          observacao: observacao ?? null,
        })
        .select("id")
        .single();

      if (error) throw error;
      resultado = data;
    } else {
      // ── Inserir despesa (padrão) ──
      const { data, error } = await supabase
        .from("gastos")
        .insert({
          user_id: user.id,
          id_local,
          data_hora: data_hora ?? new Date().toISOString(),
          categoria: categoria ?? "outros",
          valor,
          pagamento: pagamento ?? "outro",
          texto_original: texto_original ?? null,
        })
        .select("id")
        .single();

      if (error) throw error;
      resultado = data;
    }

    // ── Log de auditoria ──
    await supabase.from("audit_logs").insert({
      user_id: user.id,
      acao: "criar",
      entidade: tipo_lancamento === "receita" ? "receita" : "despesa",
      entidade_id: id_local,
      after_data: {
        descricao,
        categoria,
        valor,
        pagamento,
        origem_input,
        ai_confidence,
      },
      origem: origem_input ?? "manual",
      status: "ok",
    });

    return new Response(
      JSON.stringify({
        sucesso: true,
        id: resultado.id,
        tipo: tipo_lancamento ?? "despesa",
      }),
      { status: 201, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: `Erro ao salvar: ${err.message}` }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
