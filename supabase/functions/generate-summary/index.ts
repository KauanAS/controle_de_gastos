// supabase/functions/generate-summary/index.ts
// Gera resumo mensal com totais + análise por IA

import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseClient } from "../_shared/supabase.ts";
import { chatCompletion } from "../_shared/openai.ts";

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
    const { mes } = body; // formato "YYYY-MM"

    if (!mes || !/^\d{4}-\d{2}$/.test(mes)) {
      return new Response(
        JSON.stringify({ error: "Campo 'mes' obrigatório no formato YYYY-MM" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const inicioMes = `${mes}-01T00:00:00`;
    const [ano, mesNum] = mes.split("-").map(Number);
    const ultimoDia = new Date(ano, mesNum, 0).getDate();
    const fimMes = `${mes}-${ultimoDia}T23:59:59`;

    // ── Buscar despesas do mês ──
    const { data: despesas } = await supabase
      .from("gastos")
      .select("categoria, valor, pagamento, texto_original, data_hora")
      .eq("user_id", user.id)
      .is("deleted_at", null)
      .gte("data_hora", inicioMes)
      .lte("data_hora", fimMes)
      .order("data_hora", { ascending: true });

    // ── Buscar receitas do mês ──
    const { data: receitas } = await supabase
      .from("receitas")
      .select("categoria, valor, descricao, data_ocorrencia")
      .eq("user_id", user.id)
      .is("deleted_at", null)
      .gte("data_ocorrencia", inicioMes)
      .lte("data_ocorrencia", fimMes);

    // ── Calcular totais ──
    const totalDespesas = (despesas ?? []).reduce((sum, d) => sum + Number(d.valor), 0);
    const totalReceitas = (receitas ?? []).reduce((sum, r) => sum + Number(r.valor), 0);
    const saldo = totalReceitas - totalDespesas;

    // ── Agrupar por categoria ──
    const porCategoria: Record<string, number> = {};
    for (const d of despesas ?? []) {
      porCategoria[d.categoria] = (porCategoria[d.categoria] ?? 0) + Number(d.valor);
    }

    // ── Agrupar por pagamento ──
    const porPagamento: Record<string, number> = {};
    for (const d of despesas ?? []) {
      porPagamento[d.pagamento] = (porPagamento[d.pagamento] ?? 0) + Number(d.valor);
    }

    // ── Gerar resumo com IA ──
    let resumoIA = "";
    if ((despesas ?? []).length > 0 || (receitas ?? []).length > 0) {
      const prompt = `Você é um consultor financeiro pessoal. Analise os dados abaixo e gere um resumo em português do Brasil, com no máximo 200 palavras.

Mês: ${mes}
Total de receitas: R$ ${totalReceitas.toFixed(2)}
Total de despesas: R$ ${totalDespesas.toFixed(2)}
Saldo: R$ ${saldo.toFixed(2)}

Gastos por categoria:
${Object.entries(porCategoria).map(([cat, val]) => `- ${cat}: R$ ${(val as number).toFixed(2)}`).join("\n")}

Gastos por forma de pagamento:
${Object.entries(porPagamento).map(([pag, val]) => `- ${pag}: R$ ${(val as number).toFixed(2)}`).join("\n")}

Quantidade de despesas: ${(despesas ?? []).length}
Quantidade de receitas: ${(receitas ?? []).length}

Dê um resumo geral, destaque a maior categoria de gasto, e dê uma dica prática para economizar.`;

      resumoIA = await chatCompletion([
        { role: "system", content: "Você é um consultor financeiro pessoal brasileiro." },
        { role: "user", content: prompt },
      ], { temperature: 0.5, max_tokens: 512 });
    } else {
      resumoIA = "Nenhum lançamento encontrado para este mês.";
    }

    // ── Salvar/atualizar monthly_summaries ──
    const { data: existing } = await supabase
      .from("monthly_summaries")
      .select("id")
      .eq("user_id", user.id)
      .eq("referencia_mes", mes)
      .single();

    if (existing) {
      await supabase
        .from("monthly_summaries")
        .update({
          total_receitas: totalReceitas,
          total_despesas: totalDespesas,
          saldo,
          resumo_ia: resumoIA,
        })
        .eq("id", existing.id);
    } else {
      await supabase.from("monthly_summaries").insert({
        user_id: user.id,
        referencia_mes: mes,
        total_receitas: totalReceitas,
        total_despesas: totalDespesas,
        saldo,
        resumo_ia: resumoIA,
      });
    }

    // ── Log ──
    await supabase.from("ai_requests").insert({
      user_id: user.id,
      tipo: "resumo",
      input_text: mes,
      output_json: { totalReceitas, totalDespesas, saldo, porCategoria, porPagamento },
      status: "ok",
    });

    return new Response(
      JSON.stringify({
        sucesso: true,
        mes,
        total_receitas: totalReceitas,
        total_despesas: totalDespesas,
        saldo,
        por_categoria: porCategoria,
        por_pagamento: porPagamento,
        resumo_ia: resumoIA,
        qtd_despesas: (despesas ?? []).length,
        qtd_receitas: (receitas ?? []).length,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: `Erro ao gerar resumo: ${err.message}` }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
