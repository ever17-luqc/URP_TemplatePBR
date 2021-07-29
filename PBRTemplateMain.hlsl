#ifndef PBR_TEMPLATE_MAIN_INCLUDED
#define PBR_TEMPLATE_MAIN_INCLUDED
 
 #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
 #include "PBRTemplateFeatureShadingBXDF.hlsl"

struct PBRTemplateBRDFData
{
    half3 albedo;
    half3 diffuse;
    half3 specular;
    half reflectivity;
    half perceptualRoughness;
    half roughness;
    half roughness2;
    half grazingTerm;

    // We save some light invariant BRDF terms so we don't have to recompute
    // them in the light loop. Take a look at DirectBRDF function for detailed explaination.
    half normalizationTerm;     // roughness * 4.0 + 2.0
    half roughness2MinusOne;    // roughness^2 - 1.0
    //Skin
    half curvature;
    half thickness;

}; 

half3 SampleSkinLUT(float NdotL, float Curvature, TEXTURE2D_PARAM(Lut, sampler_Lut))
{
               
   return SAMPLE_TEXTURE2D(Lut, sampler_Lut, float2(NdotL*0.5+0.5,Curvature)).rgb ;
                
}


half3 PBRTemplateEnvironmentBRDFSpecular(PBRTemplateBRDFData brdfData, half fresnelTerm)
{
    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
    return surfaceReduction * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm);
}

half3 PBRTemplateEnvironmentBRDF(PBRTemplateBRDFData brdfData, half3 indirectDiffuse, half3 indirectSpecular, half fresnelTerm)
{
    half3 c = indirectDiffuse * brdfData.diffuse;
    c += indirectSpecular * PBRTemplateEnvironmentBRDFSpecular(brdfData, fresnelTerm);
    return c;
}
 half3 PBRTemplateGlobalIllumination(PBRTemplateBRDFData brdfData,PBRTemplateBRDFData clearcoatbrdfData, 
    half3 bakedGI, half occlusion,
    half3 normalWS, half3 viewDirectionWS)
 {
        half3 reflectVector = reflect(-viewDirectionWS, normalWS);
        half NoV = saturate(dot(normalWS, viewDirectionWS));
        half fresnelTerm = Pow4(1.0 - NoV);

        half3 indirectDiffuse = bakedGI * occlusion;        //球谐或者Lightmap的漫反射信息记录+环境光遮蔽作为漫反射基础项
        half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion);   //按粗糙度采样环境球探针的结果返回HDR解码的颜色值（如果有需求可以加一个宏用自己指定的cubemap）

        
    
    #ifdef CLEAR_COAT
        // clearCoat_NoV == shading_NoV if the clear coat layer doesn't have its own normal map
        float Fc = F_Schlick(0.04, 1.0, NoV) * _ClearCoatStr;
        // base layer attenuation for energy compensation
        indirectDiffuse  *= (1.0 - Fc)* brdfData.diffuse;
        indirectSpecular *= Sq(1.0 - Fc)*brdfData.specular;
        indirectSpecular += GlossyEnvironmentReflection(reflectVector, clearcoatbrdfData.roughness,occlusion) * Fc*brdfData.specular;
        //return 0;
        return indirectDiffuse+indirectSpecular;


    #endif

        half3 color = PBRTemplateEnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);  //漫反射+spec spec部分是unity自己拟合的公式
        return color;
    
 }
 inline void InitializePBRTemplateBRDFData(half3 albedo, half metallic,  half roughness, inout half alpha,half2 skinData, out PBRTemplateBRDFData outBRDFData,out PBRTemplateBRDFData clearcoatoutBRDFData,half clearcoatRoughness,
                                            PBRTemplateInputData inputData)
 {
     //metallic流程中为了节省贴图通道,由于非金属F0平均值在0.04左右所以取固定的0.04插值
     //LearnOpenglCN:Fresnel-Schlick近似接受一个参数F0，被称为0°入射角的反射(surface reflection at zero incidence)表示如果直接(垂直)观察表面的时候有多少光线会被反射。 
     //这个参数F0会因为材料不同而不同，而且会因为材质是金属而发生变色。在PBR金属流中我们简单地认为大多数的绝缘体在F0为0.04的时候看起来视觉上是正确的
     //我们同时会特别指定F0当我们遇到金属表面并且给定反射率的时候。 
    half oneMinusReflectivity = 1-lerp(0.04,1,metallic);
    half reflectivity = 1.0 - oneMinusReflectivity;
    
    //BRDFdata
    #ifdef CLEAR_COAT
    half NdotV=saturate(dot(inputData.normalWS,inputData.viewDirectionWS));
    outBRDFData.albedo=lerp(albedo*_EdgeFalloffColor.rgb,albedo*_Tint,pow(NdotV,_EdgeFalloffRange));
    #else
    outBRDFData.albedo              = albedo*_Tint.rgb;
    #endif
    outBRDFData.diffuse             = outBRDFData.albedo * oneMinusReflectivity;   //漫反射基础色
    outBRDFData.specular            = lerp(0.04, albedo, metallic);   //镜面反射基础色
    outBRDFData.reflectivity        = reflectivity;

    outBRDFData.perceptualRoughness = roughness;
    outBRDFData.roughness           = max(outBRDFData.perceptualRoughness*outBRDFData.perceptualRoughness, HALF_MIN_SQRT);  //DisneyPBR原则,为了让PBR结果更加美术友好，粗糙度调节更加符合直觉
    outBRDFData.roughness2          = max(outBRDFData.roughness * outBRDFData.roughness, HALF_MIN);
    outBRDFData.grazingTerm         = saturate(1-roughness + reflectivity);
    outBRDFData.normalizationTerm   = outBRDFData.roughness * 4.0h + 2.0h;
    outBRDFData.roughness2MinusOne  = outBRDFData.roughness2 - 1.0h;
    
    #ifdef SUBSURFACE_SCATTERING
    outBRDFData.curvature                =skinData.r;
    outBRDFData.thickness                =skinData.g;
    #else
    outBRDFData.curvature                =0;
    outBRDFData.thickness                =0;
    #endif 
    //clear coat
    #ifdef CLEAR_COAT
    clearcoatoutBRDFData.albedo              = 0;
    clearcoatoutBRDFData.diffuse             = 0;  
    clearcoatoutBRDFData.specular            = 0;   

    clearcoatoutBRDFData.reflectivity        = reflectivity;

    clearcoatoutBRDFData.perceptualRoughness = clearcoatRoughness;
    clearcoatoutBRDFData.roughness           = max(clearcoatoutBRDFData.perceptualRoughness*clearcoatoutBRDFData.perceptualRoughness, HALF_MIN_SQRT);  
    clearcoatoutBRDFData.roughness2          = max(clearcoatoutBRDFData.roughness * clearcoatoutBRDFData.roughness, HALF_MIN);
    clearcoatoutBRDFData.grazingTerm         = saturate(1-roughness + reflectivity);
    clearcoatoutBRDFData.normalizationTerm   = clearcoatoutBRDFData.roughness * 4.0h + 2.0h;
    clearcoatoutBRDFData.roughness2MinusOne  = clearcoatoutBRDFData.roughness2 - 1.0h;
    clearcoatoutBRDFData.curvature                =0;
    clearcoatoutBRDFData.thickness                =0;
    #else
    clearcoatoutBRDFData=(PBRTemplateBRDFData)0;
    #endif 

 

 }
 
 half PBRTemplate_DirectBRDFSpecular(PBRTemplateBRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
    float3 halfDir = SafeNormalize(float3(lightDirectionWS) + float3(viewDirectionWS));

    float NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirectionWS, halfDir));

    // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
    // BRDFspec = (D * V * F) / 4.0
    // D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
    // V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
    // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
    // https://community.arm.com/events/1155

    // Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
    // We further optimize a few light invariant terms
    // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
    float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;

    half LoH2 = LoH * LoH;
    half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);

    // On platforms where half actually means something, the denominator has a risk of overflow
    // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
    // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif

return specularTerm;
}
 half3 PBRTemplate_LightingPhysicallyBased( PBRTemplateBRDFData brdfData,PBRTemplateBRDFData clearcoatbrdfData,
                                            half3 normalWS, half3 viewDirectionWS,Light mainLight)
{   
    //init
    half3 lightColor=mainLight.color;
    half3 lightDirectionWS=mainLight.direction;
    half  lightAttenuation=mainLight.distanceAttenuation*mainLight.shadowAttenuation;


    
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);     //出射光方向辐射亮度
    //
    half NdotV=saturate(dot(normalWS,viewDirectionWS));
    half LdotV=saturate(dot(lightDirectionWS,viewDirectionWS));
    half3 H=normalize(viewDirectionWS+lightDirectionWS);
    half NdotH=saturate(dot(normalWS,H));
    half LdotH=saturate(dot(lightDirectionWS,H));
    //Normal brdf
    half3 brdf = brdfData.diffuse;
     
    half3 specBrdf=brdfData.specular * PBRTemplate_DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);
        brdf += specBrdf;
    //Cloth-velvet=========================begin
    #ifdef CLOTH_VELVET
      /*velvet diff*/
      half DisneyDiffuse_Term=DisneyDiffuse( NdotV,  NdotL,  LdotV, brdfData.perceptualRoughness);
      half3 velvetDiff=DisneyDiffuse_Term*brdfData.diffuse;
      /*velvet spec*/
      half3 velvetSpec=CharlieD(brdfData.roughness, NdotH)*AshikhminV(NdotV,NdotL)*_Sheen.rgb;
      return (velvetSpec+velvetDiff)*radiance ;
      
      
    #endif
    //Cloth-velvet=========================end



    //Mobile Skin=========================begin
    
    #ifdef SUBSURFACE_SCATTERING
      float3 sssColor=lerp(NdotL,SampleSkinLUT(dot(normalWS, lightDirectionWS)/*NdotL前面saturate过了，这里需要未clamp的使得-1-1映射到0-1，否则是0-1映射到0.5-1*/,
                                    brdfData.curvature,TEXTURE2D_ARGS(_SkinLUT, sampler_SkinLUT)),_SkinShadingStr);
      
      half3 SkinDiff=brdfData.diffuse*sssColor*lightColor * lightAttenuation;
      half3 SkinSpec=specBrdf*radiance;
     
      /*Transmission(approximate)*/
      float3 backTransLight=-lightDirectionWS+normalWS*_TransShift;
      half backNdotL=saturate(dot(backTransLight,normalWS));
      half AreaStr=backNdotL*brdfData.thickness;
      half3 transColor=AreaStr*brdfData.diffuse*_TransColor;    

       return SkinDiff+SkinSpec+transColor;
    //Mobile Skin=========================End
      

        
    #endif


      //Clear Coat==========================begin
    // clear coat BRDF
    #ifdef CLEAR_COAT
    //f(v,l)=fd(v,l)(1−Fc)+fr(v,l)(1−Fc)+fc(v,l)
    //https://google.github.io/filament/Filament.html#materialsystem/anisotropicmodel/anisotropicspecularbrdf
        float  DcVc=DV_SmithJointGGX( NdotH,  NdotL,  NdotV,clearcoatbrdfData.roughness);
        
        float  Fc = F_Schlick(0.04, LdotH) * _ClearCoatStr; // clear coat strength  
        float Frc = (DcVc) * Fc;
        
        return ((1-Fc)*(brdfData.diffuse+specBrdf)+brdfData.specular *Frc)*radiance;
        
        
    
    #endif 
    //Clear Coat==========================Start
      

    

    return brdf * radiance;
}
 half4 CustomUniversalFragmentPBR(PBRTemplateInputData inputData, PBRTemplateSurfaceData surfaceData)
 {
      PBRTemplateBRDFData brdfData;
      PBRTemplateBRDFData clearcoatData;
    InitializePBRTemplateBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.roughness, surfaceData.alpha,surfaceData.skinData ,brdfData,clearcoatData,surfaceData.clearcoatRoughness,inputData);




    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS,inputData.shadowMask);

    //GI and PBR calculate
    half3 color = PBRTemplateGlobalIllumination( brdfData,clearcoatData,inputData.bakedGI,  surfaceData.occlusion , inputData.normalWS , inputData.viewDirectionWS);
    color+=PBRTemplate_LightingPhysicallyBased(brdfData,clearcoatData,inputData.normalWS, inputData.viewDirectionWS,mainLight);


    //Emission
    color += surfaceData.emission;

   

    return half4(color,1);

    
 }
        

#endif