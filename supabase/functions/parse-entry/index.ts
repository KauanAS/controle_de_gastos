// supabase/functions/parse-entry/index.ts
// Interpreta entrada (texto, áudio ou imagem) via OpenAI
// Retorna dados estruturados para o app confirmar antes de salvar

import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseClient } from "../_shared/supabase.ts";
import { chatCompletion, transcribeAudio } from "../_shared/openai.ts";

Deno.serve(async (req) => {
  // CORS preflight
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

    // ── Verificar limite diário (5 envios de áudio/imagem por dia) ──
    const body = await req.json();
    const { tipo_input, texto, audio_base64, audio_mime_type, image_base64 } = body;

    if (tipo_input === "audio" || tipo_input === "imagem") {
      const hoje = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
      const { count } = await supabase
        .from("ai_requests")
        .select("*", { count: "exact", head: true })
        .eq("user_id", user.id)
        .in("tipo", ["parse"])
        .gte("created_at", `${hoje}T00:00:00`)
        .lte("created_at", `${hoje}T23:59:59`);

      // Buscar limite configurado
      const { data: settings } = await supabase
        .from("app_settings")
        .select("value")
        .eq("key", "ai_daily_limit")
        .single();

      const limit = settings?.value?.audio_image ?? 5;

      if ((count ?? 0) >= limit) {
        return new Response(
          JSON.stringify({ error: "Limite diário de envios atingido", limite: limit }),
          { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // ── Buscar categorias do usuário ──
    const { data: categorias } = await supabase
      .from("categories")
      .select("nome_key, nome")
      .eq("user_id", user.id)
      .eq("tipo", "despesa")
      .eq("ativo", true);

    const categoriasDisponiveis = categorias?.map((c) => c.nome_key).join(", ") ?? "outros";

    // ── Buscar formas de pagamento do usuário ──
    const { data: pagamentos } = await supabase
      .from("payment_methods")
      .select("nome_key, nome")
      .eq("user_id", user.id)
      .eq("ativo", true);

    const pagamentosDisponiveis = pagamentos?.map((p) => p.nome_key).join(", ") ?? "outro";

    // ── Processar entrada ──
    let textoParaAnalisar = "";

    if (tipo_input === "texto") {
      textoParaAnalisar = texto ?? "";
    } else if (tipo_input === "audio") {
      if (!audio_base64 || !audio_mime_type) {
        return new Response(
          JSON.stringify({ error: "audio_base64 e audio_mime_type são obrigatórios" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      textoParaAnalisar = await transcribeAudio(audio_base64, audio_mime_type);
    } else if (tipo_input === "imagem") {
      // Para imagem, usamos GPT-4o vision direto
    } else {
      return new Response(
        JSON.stringify({ error: "tipo_input deve ser: texto, audio ou imagem" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── Montar prompt ──
    const systemPrompt = `Você é um assistente financeiro que extrai dados de gastos a partir de texto ou imagem.
Extraia as seguintes informações e retorne APENAS um JSON válido (sem markdown, sem \`\`\`):

{
  "descricao": "descrição curta do gasto",
  "categoria": "uma das categorias disponíveis",
  "valor": 0.00,
  "pagamento": "uma das formas disponíveis",
  "data_hora": "YYYY-MM-DDTHH:mm:ss",
  "confianca": 0.0 a 1.0,
  "observacoes": "notas adicionais ou null"
}

Categorias disponíveis: ${categoriasDisponiveis}
Formas de pagamento disponíveis: ${pagamentosDisponiveis}

Regras:
- Se não conseguir identificar a categoria, use "outros"
- Se não conseguir identificar a forma de pagamento, use "outro"
- Se não conseguir identificar a data, use a data/hora atual
- Se não conseguir identificar o valor, coloque 0 e confianca baixa
- O campo confianca indica de 0 a 1 o quão certo você está da interpretação
- Retorne SOMENTE o JSON, nada mais`;

    let resultado: string;

    if (tipo_input === "imagem") {
      if (!image_base64) {
        return new Response(
          JSON.stringify({ error: "image_base64 é obrigatório para tipo imagem" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      resultado = await chatCompletion([
        { role: "system", content: systemPrompt },
        {
          role: "user",
          content: [
            { type: "text", text: "Extraia os dados de gasto desta imagem:" },
            {
              type: "image_url",
              image_url: { url: `data:image/jpeg;base64,${image_base64}` },
            },
          ],
        },
      ]);
    } else {
      resultado = await chatCompletion([
        { role: "system", content: systemPrompt },
        { role: "user", content: `Extraia os dados de gasto deste texto: "${textoParaAnalisar}"` },
      ]);
    }

    // ── Parsear resposta ──
    let parsed;
    try {
      // Remove possíveis backticks markdown
      const limpo = resultado.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();
      parsed = JSON.parse(limpo);
    } catch {
      parsed = {
        descricao: textoParaAnalisar || "Não identificado",
        categoria: "outros",
        valor: 0,
        pagamento: "outro",
        data_hora: new Date().toISOString(),
        confianca: 0.1,
        observacoes: "IA não conseguiu interpretar corretamente",
      };
    }

    // ── Registrar na tabela ai_requests ──
    await supabase.from("ai_requests").insert({
      user_id: user.id,
      tipo: "parse",
      input_text: textoParaAnalisar || `[${tipo_input}]`,
      output_json: parsed,
      status: parsed.confianca >= 0.5 ? "ok" : "low_confidence",
    });

    // ── Retornar ──
    return new Response(
      JSON.stringify({
        sucesso: true,
        dados: parsed,
        texto_original: textoParaAnalisar || null,
        alerta: parsed.confianca < 0.5
          ? "A IA não conseguiu interpretar os dados com confiança. Verifique antes de salvar."
          : null,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: `Erro interno: ${err.message}` }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
