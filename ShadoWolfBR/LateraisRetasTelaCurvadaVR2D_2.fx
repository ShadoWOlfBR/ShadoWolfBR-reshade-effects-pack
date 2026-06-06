#include "ReShade.fxh"

// ==========================================
// 🎛️ PARÂMETROS DA INTERFACE (UI)
// ==========================================
uniform float curvature <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Curvatura por Cosseno";
    ui_tooltip = "Usa uma onda de cosseno para suavizar a curva nas bordas e acentuar no centro.";
> = 0.35;

// ==========================================
// 🔄 VERTEX SHADER
// ==========================================
void VS_Cosseno(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

// ==========================================
// 🎨 PIXEL SHADER
// ==========================================
float4 PS_Cosseno(float4 vpos : SV_Position, float2 vTexCoord : TEXCOORD0) : SV_Target
{
    // 📍 Normaliza o centro (-1.0 a 1.0)
    float2 p = vTexCoord * 2.0 - 1.0;
    float2 pw = p;

    // 🔁 GEOMETRIA E CURVATURA DINÂMICA
    // Fator que suaviza a curva perto das bordas (X = -1 ou 1) e intensifica no centro (X = 0)
    // 1.5707963 é o equivalente a PI / 2
    float curveFactor = cos(pw.x * 1.5707963); 

    // 🧱 MÁSCARA DE CORTE (FORMATO DA FOTO)
    float topBottom = 1.0 - (curvature * 0.6) * curveFactor;
    float sides = 1.0; 

    // Se estiver fora do limite vertical curvado, pinta de preto
    if (abs(pw.y) > topBottom || abs(pw.x) > sides)
    {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    // 🎯 ENCAIXE E DISTORÇÃO DO UV
    float2 pu;
    pu.x = pw.x;              // Mantém as laterais retas preenchendo tudo
    pu.y = pw.y / topBottom;  // Adapta o plano vertical para achatar/esticar seguindo o curveFactor

    // 🔄 UV final e Render
    float2 uv = pu * 0.5 + 0.5;

    // Trava as bordas para evitar vazamento de pixels indesejados
    uv = clamp(uv, 0.0, 1.0);

    return tex2D(ReShade::BackBuffer, uv);
}

// ==========================================
// ⚙️ TÉCNICA (PIPELINE DO RESHADE)
// ==========================================
technique CurvaturaCosseno
{
    pass
    {
        VertexShader = VS_Cosseno;
        PixelShader = PS_Cosseno;
    }
}