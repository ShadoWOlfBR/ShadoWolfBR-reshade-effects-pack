#include "ReShade.fxh"

// ==========================================
// 🎛️ PARÂMETROS DA INTERFACE (UI)
// ==========================================
uniform float curvature <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Curvatura Simétrica";
    ui_tooltip = "Controla a curvatura mantendo simetria perfeita acima e abaixo do centro.";
> = 0.35;

// ==========================================
// 🔄 VERTEX SHADER
// ==========================================
void VS_Simetrica(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

// ==========================================
// 🎨 PIXEL SHADER
// ==========================================
float4 PS_Simetrica(float4 vpos : SV_Position, float2 vTexCoord : TEXCOORD0) : SV_Target
{
    // 📍 Normaliza o centro (-1.0 a 1.0)
    float2 p = vTexCoord * 2.0 - 1.0;
    float2 pw = p;

    // 📐 CRIAÇÃO DA ZONA PLANA NAS LATERAIS
    float absX = abs(pw.x);
    
    // 0.75 controla onde a curva começa
    float curveFactor = 1.0 - smoothstep(0.0, 0.75, absX);

    // 🧱 MÁSCARA DE CORTE (PERFEITAMENTE SIMÉTRICA)
    float topBottom = 1.0 - (curvature * 0.5) * curveFactor;
    float sides = 1.0; 

    // Se estiver fora do limite vertical curvado, pinta de preto
    if (abs(pw.y) > topBottom || abs(pw.x) > sides)
    {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    // 🎯 ENCAIXE E DISTORÇÃO DO UV (CORRIGIDO PARA RE-SHADE)
    float2 pu;
    pu.x = pw.x;              
    
    // HLSL aceita sign() e abs() perfeitamente da mesma forma que o GLSL
    pu.y = sign(pw.y) * (abs(pw.y) / topBottom);  

    // 🔄 UV final e Render
    float2 uv = pu * 0.5 + 0.5;

    // Trava as bordas para eliminar qualquer linha ou artefato residual
    uv = clamp(uv, 0.0, 1.0);

    return tex2D(ReShade::BackBuffer, uv);
}

// ==========================================
// ⚙️ TÉCNICA (PIPELINE DO RESHADE)
// ==========================================
technique CurvaturaSimetrica
{
    pass
    {
        VertexShader = VS_Simetrica;
        PixelShader = PS_Simetrica;
    }
}