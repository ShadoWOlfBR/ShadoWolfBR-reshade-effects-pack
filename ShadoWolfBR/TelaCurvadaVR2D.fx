#include "ReShade.fxh"

// ==========================================
// 🎛️ PARÂMETROS DA INTERFACE (UI)
// ==========================================
uniform float curvature <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 0.5;
    ui_step = 0.01;
    ui_label = "Curvatura Geométrica";
    ui_tooltip = "Controla a distorção senoidal e o arredondamento da tela.";
> = 0.28;

// ==========================================
// 🔄 VERTEX SHADER
// ==========================================
void VS_Geometria(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

// ==========================================
// 🎨 PIXEL SHADER
// ==========================================
float4 PS_Geometria(float4 vpos : SV_Position, float2 vTexCoord : TEXCOORD0) : SV_Target
{
    // 📍 Normaliza o centro (-1.0 a 1.0)
    float2 p = vTexCoord * 2.0 - 1.0;

    // Equivalente ao max(0.001, sin(...)) do GLSL
    float s = max(0.001, sin(curvature));

    // 🔁 GERAR A GEOMETRIA
    float2 pw = p;

    pw.x = sin(p.x * curvature) / s;

    // Aplica a distorção cruzada nos eixos
    pw.x = pw.x * (1.0 + pw.y * pw.y * 0.06);
    pw.y = pw.y * (1.0 + pw.x * pw.x * 0.04);

    // 🧱 MÁSCARA DE CORTE (BORDAS CURVADAS)
    float topBottom = 1.0 - 0.22 * (1.0 - pw.x * pw.x);
    float sides     = 1.0 - 0.12 * (1.0 - pw.y * pw.y);

    // Se estiver fora do formato estilizado, pinta de preto
    if (abs(pw.y) > topBottom || abs(pw.x) > sides)
    {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    // 🎯 ENCAIXE PERFEITO
    float2 pu;
    pu.x = pw.x / sides;      // Espreme horizontalmente seguindo a curva lateral
    pu.y = pw.y / topBottom;  // Espreme verticalmente seguindo a curva superior/inferior

    // 🔄 UV final e Render
    float2 uv = pu * 0.5 + 0.5;

    // Segurança para evitar artefatos nas bordas extremas
    uv = clamp(uv, 0.0, 1.0);

    // Renderiza a imagem do jogo com as novas coordenadas calculadas
    return tex2D(ReShade::BackBuffer, uv);
}

// ==========================================
// ⚙️ TÉCNICA (PIPELINE DO RESHADE)
// ==========================================
technique GeometriaCurva
{
    pass
    {
        VertexShader = VS_Geometria;
        PixelShader = PS_Geometria;
    }
}