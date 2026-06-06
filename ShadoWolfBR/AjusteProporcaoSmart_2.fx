#include "ReShade.fxh"

// ==========================================
// 🎛️ PARÂMETROS DA INTERFACE (UI)
// ==========================================
uniform float smart_thinness <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Afinar Centro Suave";
    ui_tooltip = "Ajuste para afinar o centro de forma arredondada e natural, sem criar linhas ou divisões.";
> = 0.25;

// ==========================================
// 🔄 VERTEX SHADER
// ==========================================
void VS_SmartSuave(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

// ==========================================
// 🎨 PIXEL SHADER
// ==========================================
float4 PS_SmartSuave(float4 vpos : SV_Position, float2 vTexCoord : TEXCOORD0) : SV_Target
{
    // 📍 Normaliza o centro para (-1.0 a 1.0)
    float2 p = vTexCoord * 2.0 - 1.0;

    // Guardamos o X original para a interpolação
    float x_original = p.x;

    // 📐 MATEMÁTICA DA CURVA ARREDONDADA (SENOIDAL)
    // 1.5707963 é PI / 2. O seno cria uma transição perfeitamente suave (arredondada) no centro
    float x_suave = sin(p.x * 1.5707963);

    // Fazemos uma transição linear (lerp) entre o X original e o X suavizado 
    // baseada no slider. Isso elimina a sensação de "fenda" ou listra no meio.
    p.x = lerp(x_original, x_suave, smart_thinness * 0.5);

    // Retorna para o espaço UV padrão (0.0 a 1.0)
    float2 uv = p * 0.5 + 0.5;

    // Trava de segurança para evitar qualquer artefato nas bordas absolutas
    uv = clamp(uv, 0.0, 1.0);

    return tex2D(ReShade::BackBuffer, uv);
}

// ==========================================
// ⚙️ TÉCNICA (PIPELINE DO RESHADE)
// ==========================================
technique AjusteProporcaoSmart
{
    pass
    {
        VertexShader = VS_SmartSuave;
        PixelShader = PS_SmartSuave;
    }
}