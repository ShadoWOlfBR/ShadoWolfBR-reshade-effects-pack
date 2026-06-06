#include "ReShade.fxh"

// ==========================================
// 🎛️ PARÂMETROS DA INTERFACE (UI)
// ==========================================
uniform float curvature <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Curvatura";
    ui_tooltip = "Controla a intensidade da curvatura no topo e na base.";
> = 0.35;

// ==========================================
// 🔄 VERTEX SHADER
// ==========================================
// O ReShade possui um Vertex Shader padrão (PostProcessVS), 
// mas mantivemos a lógica padrão para garantir compatibilidade.
void VS_Curvatura(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

// ==========================================
// 🎨 PIXEL SHADER
// ==========================================
float4 PS_Curvatura(float4 vpos : SV_Position, float2 vTexCoord : TEXCOORD0) : SV_Target
{
    // 📍 Normaliza o centro (-1.0 a 1.0)
    float2 p = vTexCoord * 2.0 - 1.0;
    float2 pw = p;

    // 📐 CRIAÇÃO DA ZONA PLANA NAS LATERAIS
    // Tomamos o valor absoluto de X para tratar os lados esquerdo e direito igual.
    float absX = abs(pw.x);
    
    // smoothstep(A, B, absX) diz: 
    // Se estiver entre 0.0 (centro) e 0.75, calcula a curva.
    // Se estiver entre 0.75 e 1.0 (as pontas), o resultado trava em 0.0 (fica plano/reto).
    float curveFactor = 1.0 - smoothstep(0.0, 0.75, absX);

    // 🧱 MÁSCARA DE CORTE (COM PLATÔ NAS PONTAS)
    // Multiplicamos pelo curveFactor suavizado pelo smoothstep
    float topBottom = 1.0 - (curvature * 0.5) * curveFactor;
    float sides = 1.0; // Laterais coladas na borda da tela

    // Se estiver fora do limite vertical curvado, pinta de preto
    if (abs(pw.y) > topBottom || abs(pw.x) > sides)
    {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    // 🎯 ENCAIXE E DISTORÇÃO DO UV
    float2 pu;
    pu.x = pw.x;              
    pu.y = pw.y / topBottom;  // Encaixa a imagem seguindo a nova transição do smoothstep

    // 🔄 UV final e Render
    float2 uv = pu * 0.5 + 0.5;
    uv = clamp(uv, 0.0, 1.0);

    // No ReShade, usamos tex2D com o sampler padrão do BackBuffer
    return tex2D(ReShade::BackBuffer, uv);
}

// ==========================================
// ⚙️ TÉCNICA (PIPELINE DO RESHADE)
// ==========================================
technique CurvaturaTela
{
    pass
    {
        VertexShader = VS_Curvatura;
        PixelShader = PS_Curvatura;
    }
}