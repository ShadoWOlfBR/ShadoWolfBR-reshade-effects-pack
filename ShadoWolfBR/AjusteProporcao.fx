#include "ReShade.fxh"

// ==========================================
// 🎛️ PARÂMETROS DA INTERFACE (UI)
// ==========================================
uniform float fov_thinness <
    ui_type = "slider";
    ui_min = 0.5;
    ui_max = 1.5;
    ui_step = 0.01;
    ui_label = "Afinar Imagem (FOV X)";
    ui_tooltip = "Valores menores que 1.0 afinam a imagem (espremem horizontalmente). Valores maiores engordam.";
> = 0.85;

uniform float zoom <
    ui_type = "slider";
    ui_min = 0.5;
    ui_max = 2.0;
    ui_step = 0.01;
    ui_label = "Zoom da Tela";
    ui_tooltip = "Aumente o zoom (valores acima de 1.0) para expandir a imagem recortada e preencher a tela.";
> = 1.0;

// ==========================================
// 🔄 VERTEX SHADER
// ==========================================
void VS_Proporcao(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

// ==========================================
// 🎨 PIXEL SHADER
// ==========================================
float4 PS_Proporcao(float4 vpos : SV_Position, float2 vTexCoord : TEXCOORD0) : SV_Target
{
    // 📍 Normaliza o centro para (-1.0 a 1.0)
    float2 p = vTexCoord * 2.0 - 1.0;

    // Aplica o Zoom dividindo ambos os eixos (aproxima ou afasta do centro)
    p /= zoom;

    // Aplica o fator de estiramento/afinamento apenas no eixo X (Horizontal)
    p.x /= fov_thinness;

    // Retorna para o espaço UV padrão (0.0 a 1.0)
    float2 uv = p * 0.5 + 0.5;

    // Cria a máscara para deixar preto o que passar dos limites da tela original
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
    {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    return tex2D(ReShade::BackBuffer, uv);
}

// ==========================================
// ⚙️ TÉCNICA (PIPELINE DO RESHADE)
// ==========================================
technique AjusteProporcao
{
    pass
    {
        VertexShader = VS_Proporcao;
        PixelShader = PS_Proporcao;
    }
}