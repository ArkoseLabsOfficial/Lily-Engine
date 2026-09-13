#pragma header

uniform float lightX[16];
uniform float lightY[16];
uniform float lightRad[16];
uniform float lightCount;

void main() {
    vec2 uv = openfl_TextureCoordv;
    vec4 baseColor = flixel_texture2D(bitmap, uv);
    vec2 screenPos = uv * openfl_TextureSize;

    float visibility = 0.0;

    for (int i = 0; i < 16; i++) {
        if (float(i) >= lightCount)
            break;

        vec2 lightPosition = vec2(lightX[i], lightY[i]);
        float radius = lightRad[i];

        float distanceToLight = distance(screenPos, lightPosition);
        
        float intensity = 1.0 - smoothstep(radius * 0.2, radius, distanceToLight);
        visibility = max(visibility, intensity);
    }

    vec3 darkScene = baseColor.rgb * 0.02;
    vec3 finalColor = mix(darkScene, baseColor.rgb, visibility);

    gl_FragColor = vec4(finalColor, baseColor.a);
}