// supabase/functions/ai-chat/index.ts
// Chat analítico: responde perguntas sobre os dados financeiros do usuário

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
    const { pergunta, periodo } = body;
    // periodo opcional: "2026-04" ou "2026-01:2026-04" (intervalo)

    if (!pergunta) {
      return new Response(
        JSON.stringify({ error: "Campo 'pergunta' é obrigatório" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── Determinar período de busca ──
    let inicioFiltro: string;
    let fimFiltro: string;

    if (periodo && periodo.includes(":")) {
      // Intervalo: "2026-01:2026-04"
      const [ini, fim] = periodo.split(":");
      inicioFiltro = `${ini}-01T00:00:00`;
      const [anoF, mesF] = fim.split("-").map(Number);
      const ultimoDia = new Date(anoF, mesF, 0).getDate();
      fimFiltro = `${fim}-${ultimoDia}T23:59:59`;
    } else if (periodo) {
      // Mês único: "2026-04"
      inicioFiltro = `${periodo}-01T00:00:00`;
      const [ano, mes] = periodo.split("-").map(Number);
      const ultimoDia = new Date(ano, mes, 0).getDate();
      fimFiltro = `${periodo}-${ultimoDia}T23:59:59`;
    } else {
      // Últimos 3 meses por padrão
      const agora = new Date();
      const tresMesesAtras = new Date(agora);
      tresMesesAtras.setMonth(tresMesesAtras.getMonth() - 3);
      inicioFiltro = tresMesesAtras.toISOString();
      fimFiltro = agora.toISOString();
    }

    // ── Buscar dados do usuário ──
    const { data: despesas } = await supabase
      .from("gastos")
      .select("categoria, valor, pagamento, texto_original, data_hora")
      .eq("user_id", user.id)
      .is("deleted_at", null)
      .gte("data_hora", inicioFiltro)
      .lte("data_hora", fimFiltro)
      .order("data_hora", { ascending: false })
      .limit(200);

    const { data: receitas } = await supabase
      .from("receitas")
      .select("categoria, valor, descricao, data_ocorrencia")
      .eq("user_id", user.id)
      .is("deleted_at", null)
      .gte("data_ocorrencia", inicioFiltro)
      .lte("data_ocorrencia", fimFiltro)
      .order("data_ocorrencia", { ascending: false })
      .limit(100);

    // ── Calcular totais para contexto ──
    const totalDespesas = (despesas ?? []).reduce((s, d) => s + Number(d.valor), 0);
    const totalReceitas = (receitas ?? []).reduce((s, r) => s + Number(r.valor), 0);

    const porCategoria: Record<string, number> = {};
    for (const d of despesas ?? []) {
      porCategoria[d.categoria] = (porCategoria[d.categoria] ?? 0) + Number(d.valor);
    }

    // ── Buscar histórico de conversa recente ──
    const { data: historico } = await supabase
      .from("ai_chat_messages")
      .select("role, content")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(10);

    const mensagensAnteriores = (historico ?? [])
      .reverse()
      .map((m) => ({ role: m.role, content: m.content }));

    // ── Montar contexto e perguntar à IA ──
    const contexto = `Dados financeiros do usuário (período: ${inicioFiltro.split("T")[0]} a ${fimFiltro.split("T")[0]}):

Total de receitas: R$ ${totalReceitas.toFixed(2)}
Total de despesas: R$ ${totalDespesas.toFixed(2)}
Saldo: R$ ${(totalReceitas - totalDespesas).toFixed(2)}

Gastos por categoria:
${Object.entries(porCategoria).map(([c, v]) => `- ${c}: R$ ${(v as number).toFixed(2)}`).join("\n")}

Últimas despesas:
${(despesas ?? []).slice(0, 20).map((d) => `- ${d.data_hora?.split("T")[0]} | ${d.categoria} | R$ ${Number(d.valor).toFixed(2)} | ${d.texto_original ?? ""}`).join("\n")}

Receitas:
${(receitas ?? []).slice(0, 10).map((r) => `- ${r.data_ocorrencia?.split("T")[0]} | ${r.categoria} | R$ ${Number(r.valor).toFixed(2)} | ${r.descricao}`).join("\n")}`;

    const systemPrompt = `Você é um assistente financeiro pessoal. Responda APENAS com base nos dados fornecidos abaixo. Nunca invente dados. Se não tiver informação suficiente, diga que não há dados para responder. Responda em português do Brasil de forma clara e direta.

${contexto}`;

    const messages = [
      { role: "system", content: systemPrompt },
      ...mensagensAnteriores,
      { role: "user", content: pergunta },
    ];

    const resposta = await chatCompletion(messages, {
      temperature: 0.4,
      max_tokens: 768,
    });

    // ── Salvar mensagens no histórico ──
    await supabase.from("ai_chat_messages").insert([
      {
        user_id: user.id,
        role: "user",
        content: pergunta,
        related_period: periodo ?? null,
      },
      {
        user_id: user.id,
        role: "assistant",
        content: resposta,
        related_period: periodo ?? null,
      },
    ]);

    // ── Log ──
    await supabase.from("ai_requests").insert({
      user_id: user.id,
      tipo: "chat",
      input_text: pergunta,
      output_json: { resposta: resposta.substring(0, 500) },
      status: "ok",
    });

    return new Response(
      JSON.stringify({
        sucesso: true,
        resposta,
        periodo_consultado: {
          inicio: inicioFiltro.split("T")[0],
          fim: fimFiltro.split("T")[0],
        },
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: `Erro no chat: ${err.message}` }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
