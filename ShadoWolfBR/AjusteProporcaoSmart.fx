#include "ReShade.fxh"

// ==========================================
// 🎛️ PARÂMETROS DA INTERFACE (UI)
// ==========================================
uniform float smart_thinness <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Afinar Centro (Sem Bordas)";
    ui_tooltip = "Aumente para afinar o personagem no centro da tela sem gerar barras pretas nas laterais.";
> = 0.30; // Valor inicial padrão para já notar o efeito protetor no centro

// ==========================================
// 🔄 VERTEX SHADER
// ==========================================
void VS_Smart(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

// ==========================================
// 🎨 PIXEL SHADER
// ==========================================
float4 PS_Smart(float4 vpos : SV_Position, float2 vTexCoord : TEXCOORD0) : SV_Target
{
    // 📍 Normaliza o centro para (-1.0 a 1.0)
    float2 p = vTexCoord * 2.0 - 1.0;

    // Salva o sinal original para saber se estamos olhando para a esquerda (-) ou direita (+)
    float s = sign(p.x);
    float absX = abs(p.x);

    // LÓGICA SMART: 
    // Elevamos o valor absoluto de X a uma potência baseada no slider.
    // Isso faz com que quando X = 0 (centro), a distorção seja máxima (espremendo o boneco).
    // Quando X = 1 ou -1 (bordas), o resultado continua sendo 1 ou -1, eliminando as faixas pretas!
    if (smart_thinness > 0.0)
    {
        // Interpola a curva para criar uma transição suave entre o centro e as pontas
        absX = pow(absX, 1.0 - (smart_thinness * 0.5));
        p.x = absX * s;
    }

    // Retorna para o espaço UV padrão (0.0 a 1.0)
    float2 uv = p * 0.5 + 0.5;

    // Trava de segurança nas bordas absolutas
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
        VertexShader = VS_Smart;
        PixelShader = PS_Smart;
    }
}