#pragma header

#define MAX_LIGHTS 32

uniform int u_numLights;
uniform vec2 u_lightPos[MAX_LIGHTS];
uniform float u_lightEnergy[MAX_LIGHTS];
uniform float u_lightScale[MAX_LIGHTS];
uniform vec3 u_lightColor[MAX_LIGHTS];
uniform vec3 u_darknessColor;

void main() {
    vec4 baseColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
    
    vec3 totalLight = vec3(0.0);
    vec2 fragPos = openfl_TextureCoordv * openfl_TextureSize;

    for (int i = 0; i < MAX_LIGHTS; i++) {
        if (i >= u_numLights) break;

        float dist = distance(fragPos, u_lightPos[i]);
        float radius = u_lightScale[i];
        
        if (dist < radius) {
            float falloff = pow(1.0 - (dist / radius), 2.0);
            totalLight += u_lightColor[i] * u_lightEnergy[i] * falloff;
        }
    }

    vec3 finalRgb = baseColor.rgb * (u_darknessColor + totalLight);
    gl_FragColor = vec4(clamp(finalRgb, 0.0, 1.0), baseColor.a);
}