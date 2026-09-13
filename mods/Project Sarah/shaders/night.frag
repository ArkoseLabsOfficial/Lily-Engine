#pragma header

uniform float iTime;
uniform float lightX[16];
uniform float lightY[16];
uniform float lightRad[16];
uniform float lightCount;

void main() {
    vec2 uv = openfl_TextureCoordv;
    vec4 baseColor = flixel_texture2D(bitmap, uv);
    vec2 screenPos = uv * openfl_TextureSize;

    vec3 nightColor1 = vec3(0.05, 0.08, 0.2); 
    vec3 nightColor2 = vec3(0.12, 0.05, 0.25); 
    vec3 nightColor3 = vec3(0.02, 0.15, 0.18); 
    
    float wave1 = sin(iTime * 0.5 + uv.x * 4.0) * 0.5 + 0.5;
    float wave2 = cos(iTime * 0.3 - uv.y * 4.0) * 0.5 + 0.5;
    
    vec3 ambientNight = mix(nightColor1, nightColor2, wave1);
    ambientNight = mix(ambientNight, nightColor3, wave2 * 0.5);

    float maxLightIntensity = 0.0;

    for (int i = 0; i < 16; i++) {
        if (float(i) >= lightCount)
            break;

        vec2 lightPosition = vec2(lightX[i], lightY[i]);
        float radius = lightRad[i];

        float distanceToLight = distance(screenPos, lightPosition);
        
        float intensity = 1.0 - smoothstep(radius * 0.2, radius, distanceToLight);
        maxLightIntensity = max(maxLightIntensity, intensity);
    }

    float vignette = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
    vignette = clamp(pow(16.0 * vignette, 0.25), 0.0, 1.0);
    
    vec3 tintedScene = baseColor.rgb * ambientNight * 2.5;
    vec3 litScene = mix(tintedScene, baseColor.rgb, maxLightIntensity);
    
    gl_FragColor = vec4(litScene * vignette, baseColor.a);
}