#pragma header
        
        uniform sampler2D alpha_mask;
        void main() {
            vec4 color = texture2D(bitmap, openfl_TextureCoordv);
            
            color.rgb *= color.a;
            
            gl_FragColor = color;
        }