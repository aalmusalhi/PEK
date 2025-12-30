extern number time;

/*
notes for effect inputs:
- colour: this is current the LOVE2D setColor(), {1, 1, 1, 1} by default
- texture: the current image being drawn (i.e. the sprite)
- texture_coords: (x, y) coordinates of where we are in the provided texture
- screen_coords: where we are in the screen (specific pixels)
*/
vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Texel (texture element) is LOVE2D's method for sampling
    // textures (gives texture colour at some coordinates)
    vec4 texcolour = Texel(texture, texture_coords);

    // make different intensity waves in (x, y) and combine them 
    // for a diagonal shader (the result must be between 0 and 1)
    float wavex = sin(texture_coords.x * 3.14159 * 3.0 + time) * 0.5 + 0.5;
    float wavey = cos(texture_coords.y * 3.14159 * 3.0 - time) * 0.5 + 0.5;
    float intensity = wavex + wavey;

    // calculate a hue based on position, then fluctuate it with time
    // (fract forces values to be between 0 and 1, but also wraps around to repeat)
    float hue = fract(texture_coords.x * 0.5 + texture_coords.y * 0.5 + time);

    // convert the hue to RGB
    float R = abs(hue * 6.0 - 3.0) - 1.0;
    float G = 2.0 - abs(hue * 6.0 - 2.0);
    float B = 2.0 - abs(hue * 6.0 - 4.0);
    vec3 rainbow = clamp(vec3(R, G, B), 0.0, 1.0); // restrict to values between (0, 1)

    // apply the rainbow colour with some intensity to the texture RGB
    vec3 result = texcolour.rgb + rainbow * intensity;

    // combines 3 things:
    // - shader result (which is an RGB vec3)
    // - alpha of original texture
    // - existing setColor from LOVE2D
    return vec4(result, texcolour.a) * colour;
}