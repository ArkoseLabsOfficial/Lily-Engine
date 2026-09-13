#pragma header

#define MAX_LIGHTS 32

uniform float u_time;
uniform int u_numLights;
uniform vec2 u_lightPos[MAX_LIGHTS];
uniform float u_lightEnergy[MAX_LIGHTS];
uniform float u_lightScale[MAX_LIGHTS];
uniform vec3 u_lightColor[MAX_LIGHTS];

uniform vec3 u_nightTint;
uniform float u_desaturation;

void main() {
    vec4 baseColor = flixel_texture2D(bitmap, openfl_TextureCoordv);

    vec3 tintShift = vec3(
        sin(u_time * 0.2) * 0.02,
        cos(u_time * 0.15) * 0.02,
        sin(u_time * 0.25) * 0.04
    );
    vec3 currentTint = clamp(u_nightTint + tintShift, 0.0, 1.0);

    float gray = dot(baseColor.rgb, vec3(0.299, 0.587, 0.114));
    vec3 desaturated = mix(baseColor.rgb, vec3(gray), u_desaturation);
    vec3 nightRgb = desaturated * currentTint;

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

    vec3 finalRgb = nightRgb + (baseColor.rgb * totalLight);
    gl_FragColor = vec4(clamp(finalRgb, 0.0, 1.0), baseColor.a);
}