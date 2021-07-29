#ifndef PBR_TEMPLATE_BXDF_INCLUDED
#define PBR_TEMPLATE_BXDF_INCLUDED
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/BSDF.hlsl"



 
 ////////////////////////////////////////////////////////////////////////////////////////////
 //                                   Cloth-Velvet                                         //
 //                                                                                        //
 //                                                                                        //
 ////////////////////////////////////////////////////////////////////////////////////////////
 
float CharlieD(float roughness, float ndoth)
{
    float invR = rcp(roughness);
    float cos2h = ndoth * ndoth;
    float sin2h = 1. - cos2h;
    return (2. + invR) * pow(sin2h, invR * .5) / (2. * PI);
}
float AshikhminV(float ndotv, float ndotl)
{
    return 1. / (4. * (ndotl + ndotv - ndotl * ndotv));
}
#endif
