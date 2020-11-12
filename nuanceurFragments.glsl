#version 410

// Définition des paramètres des sources de lumière
layout (std140) uniform LightSourceParameters
{
    vec4 ambient[3];
    vec4 diffuse[3];
    vec4 specular[3];
    vec4 position[3];      // dans le repère du monde
} LightSource;

// Définition des paramètres des matériaux
layout (std140) uniform MaterialParameters
{
    vec4 emission;
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    float shininess;
} FrontMaterial;

// Définition des paramètres globaux du modèle de lumière
layout (std140) uniform LightModelParameters
{
    vec4 ambient;       // couleur ambiante globale
    bool twoSide;       // éclairage sur les deux côtés ou un seul?
} LightModel;

layout (std140) uniform varsUnif
{
    // partie 1: illumination
    int typeIllumination;     // 0:Gouraud, 1:Phong
    bool utiliseBlinn;        // indique si on veut utiliser modèle spéculaire de Blinn ou Phong
    bool afficheNormales;     // indique si on utilise les normales comme couleurs (utile pour le débogage)
    // partie 2: texture
    int iTexCoul;             // numéro de la texture de couleurs appliquée
    int iTexNorm;             // numéro de la texture de normales appliquée
};

uniform sampler2D laTextureCoul;
uniform sampler2D laTextureNorm;

/////////////////////////////////////////////////////////////////

in Attribs {
    vec4 couleur;
    vec3 normale, lumiDir[3], obsVec;
    vec2 texCoord;
} AttribsIn;

out vec4 FragColor;

float attenuation = 1.0;
vec4 calculerReflexion( in int j, in vec3 L, in vec3 N, in vec3 O ) // pour la lumière j
{
    vec4 coul = FrontMaterial.emission;

    coul += FrontMaterial.ambient * LightSource.ambient[j];

    float NdotL = max( 0.0, dot( N, L ) );
    if ( NdotL > 0.0 )
    {

        coul += LightSource.diffuse[j] * FrontMaterial.diffuse * NdotL;

        float spec = max( 0.0, ( utiliseBlinn ) ?
                          dot( normalize( L + O ), N ) : // dot( B, N )
                          dot( reflect( -L, N ), O ) ); // dot( R, O )
        if ( spec > 0 ) coul += LightSource.specular[j] * FrontMaterial.specular * pow( spec, FrontMaterial.shininess );
    }

    return(coul);
}

void main( void )
{
    // typeIllumination = 1 correspond à Phong
    if(typeIllumination == 1) {
        vec4 coul;

        // couleur du sommet
        if(typeIllumination == 1) {

            vec3 L[3];

            // Normale
            vec3 N = normalize(AttribsIn.normale);

            // Position de l'observateur
            vec3 O = vec3( 0.0, 0.0, 1.0 );

            // On trouve les couleurs à partir de la reflexion calculée
            int j = 0;
            L[j] = normalize(AttribsIn.lumiDir[j]);
            coul = calculerReflexion( j, L[j], N, O );
            for (j = 1; j < 3; j++) {
                L[j] = normalize(AttribsIn.lumiDir[j]);
                coul += calculerReflexion( j, L[j], N, O );
            }
        }

        //Et on finit par calculer puis envoyer la couleur de fragment résultante
        FragColor = clamp( coul, 0.0, 1.0 );
    }
    // Sinon on utilise Gouraud
    else {

        // Pour Gouraud on envoie directement la couleur de fragment sans étape intermédiaire
        FragColor = clamp( AttribsIn.couleur, 0.0, 1.0 );    
    }

    // Aller chercher (échantilloner) la couleur du fragment dans la texture
    if( iTexCoul != 0 )
    {
        vec4 couleurTexture = texture( laTextureCoul, AttribsIn.texCoord.st );
        if( length(couleurTexture.rgb) < 0.5 ){
            discard;
        } else {
            FragColor *= couleurTexture;
        }
    }

}