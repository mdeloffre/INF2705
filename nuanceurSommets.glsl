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

uniform mat4 matrModel;
uniform mat4 matrVisu;
uniform mat4 matrProj;
uniform mat3 matrNormale;

/////////////////////////////////////////////////////////////////

layout(location=0) in vec4 Vertex;
layout(location=2) in vec3 Normal;
layout(location=3) in vec4 Color;
layout(location=8) in vec4 TexCoord;

out Attribs {
    vec4 couleur;
    vec3 normale, lumiDir[3], obsVec;
    vec2 texCoord;
} AttribsOut;

uniform float temps;

vec4 calculerReflexion( in int j, in vec3 L, in vec3 N, in vec3 O ) // pour la lumière j
{

    float d = length( L );

    float d2 = d * d;

    // float attenuation = 1.0 / d2; // Ne semble pas fonctionner
    
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
    // transformation standard du sommet
    gl_Position = matrProj * matrVisu * matrModel * Vertex;

    // Normale
    vec3 normale = matrNormale * Normal;
    AttribsOut.normale = normale;

    // calcul de la position du sommet dans le repère de la caméra
    vec3 pos = (matrVisu * matrModel * Vertex).xyz;

    vec3 L[3];

    // Direction de la lumière
    for (int i = 0; i < 3; i++) {
        AttribsOut.lumiDir[i] = L[i] = (matrVisu * LightSource.position[i]).xyz - pos;
        L[i] = normalize(L[i]);
    }

     // Position de l'observateur
     AttribsOut.obsVec = vec3( 0.0, 0.0, 1.0 );

    // typeIllumination = 0 correspond à Gouraud.
    if(typeIllumination == 0) {

        // Normale
        vec3 N = normalize( normale ); 

        // Position de l'observateur
        vec3 O = vec3( 0.0, 0.0, 1.0 );

        // On transmet les couleur de sortie en fonction des paramètres de reflexion calculés
        int j = 0;
        AttribsOut.couleur = calculerReflexion( j, L[j], N, O );
        for (j = 1; j < 3; j++) {
           AttribsOut.couleur += calculerReflexion( j, L[j], N, O );
        }
    }

    // Coordonnées des textures 
    AttribsOut.texCoord = TexCoord.st+vec2(-0.1*temps,0);

}
