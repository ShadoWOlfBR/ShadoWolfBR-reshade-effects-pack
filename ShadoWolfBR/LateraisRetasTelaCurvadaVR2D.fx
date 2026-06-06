#include "ReShade.fxh"

// ==========================================
// 🎛️ PARÂMETROS DA INTERFACE (UI)
// ==========================================
uniform float curvature <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 0.5;
    ui_step = 0.01;
    ui_label = "Curvatura Cilíndrica";
    ui_tooltip = "Controla o arco superior e inferior mantendo as laterais retas.";
> = 0.28;

// ==========================================
// 🔄 VERTEX SHADER
// ==========================================
void VS_Cilindrico(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

// ==========================================
// 🎨 PIXEL SHADER
// ==========================================
float4 PS_Cilindrico(float4 vpos : SV_Position, float2 vTexCoord : TEXCOORD0) : SV_Target
{
    // 📍 Normaliza o centro (-1.0 a 1.0)
    float2 p = vTexCoord * 2.0 - 1.0;

    float s = max(0.001, sin(curvature));

    // 🔁 GERAR A GEOMETRIA (CILÍNDRICA VERTICAL)
    float2 pw = p;

    // Aplica a curvatura horizontal para criar a base do arco
    pw.x = sin(p.x * curvature) / s;
    
    // Distorção apenas no eixo Y para manter as laterais perfeitamente retas
    pw.y = pw.y * (1.0 + pw.x * pw.x * 0.04);

    // 🧱 MÁSCARA DE CORTE (ABAS LATERAIS RETAS)
    float topBottom = 1.0 - 0.22 * (1.0 - pw.x * pw.x);
    float sides = 1.0; 

    // Se estiver fora da tela ou da curva, pinta de preto
    if (abs(pw.y) > topBottom || abs(pw.x) > sides)
    {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    // 🎯 ENCAIXE PERFEITO (MATEAR UV NA CURVA)
    float2 pu;
    pu.x = pw.x;               // Sem compressão lateral (mantém reto nas pontas)
    pu.y = pw.y / topBottom;   // Estica verticalmente acompanhando o arco superior/inferior

    // 🔄 UV final e Render
    float2 uv = pu * 0.5 + 0.5;

    // Garante que o clamp não crie linhas esticadas nas bordas
    uv = clamp(uv, 0.0, 1.0);

    return tex2D(ReShade::BackBuffer, uv);
}

// ==========================================
// ⚙️ TÉCNICA (PIPELINE DO RESHADE)
// ==========================================
technique CilindricoVertical
{
    pass
    {
        VertexShader = VS_Cilindrico;
        PixelShader = PS_Cilindrico;
    }
}