Shader "Ever17_PBR/PBR_Template"
{
    Properties
    {  
    //Surface Options Props
        
        [Foldout]_SurfaceOpFoldout("Surface Options",Float)=1
        [if(_SurfaceOpFoldout)] [Enum(UnityEngine.Rendering.CullMode)]_CullMode("Render Face",Float)=0
        [if(_SurfaceOpFoldout)][SurfaceType][Enum(Opaque,0,Transparent,1)]_Surface("Surface Type",Int)=1
    //Surface input Props   
        [Foldout]_SurfaceIpFoldout("Surface Inputs",Float)=1
        [if(_SurfaceIpFoldout)][NoScaleOffset][SingleLine]_BaseTexture ("Base Texture(Diffuse Texture)", 2D) = "white" {}
        [if(_SurfaceIpFoldout)]_Tint("Tint ",Color)=(1,1,1,1)
        //默认压缩格式DXT5 G、A通道精度相比RB通道精度更加高，同时A通道比G通道更加高,A通道适合存放更加高频的高密度的粗糙度   贴图需要取消sRGB，因为是线性的数据并非srgb的贴图颜色信息不需要degamma
        [if(_SurfaceIpFoldout)][SingleLine][NoScaleOffset][IfDef(AMR_MAP)]_AOMetallicRoughnessMap("AO:R Metallic:G Roughness:A Map(Gamma Space needed)",2D)="white"{}
        
        [if(_SurfaceIpFoldout)][HideWithoutTex(_AOMetallicRoughnessMap)]_MetallicStr("Metallic Strength(without Tex)",Range(0,1))=0
        [if(_SurfaceIpFoldout)]_RoughnessStr("Roughness Strength(without Tex)",Range(0,1))=0
        

        [if(_SurfaceIpFoldout)][SingleLine][IfDef(_NORMALMAP)][NoScaleOffset]_NormalMap("Normal Map",2D)="bump"{}
        [if(_SurfaceIpFoldout)]_NormalScale("Normal Scale",Range(0,10))=1

        [if(_SurfaceIpFoldout)][Toggle(EMISSION_ON)][NoScaleOffset]_Emission("Emission",Float)=0
        [if(_SurfaceIpFoldout)][SingleLine]_EmissionMap("Emission Map",2D)="white"{}
        [if(_SurfaceIpFoldout)][HDR]_EmisssionColor("EmissionColor",Color)=(0,0,0,0)
        [Space(10)][Line]
        [if(_SurfaceIpFoldout)]_GlobalTilingAndOffset("Global Texture Tiling And Offset",Vector)=(1,1,0,0)
    //Advanced Features
        [Space(10)]
        [Foldout]_FeaturesFoldout("Advanced Features ",Float)=1
        [Header(multiple choice)]
        [Space(10)]
        [if(_FeaturesFoldout)][Toggle(CLOTH_VELVET)]_VelvetToggle("Cloth Shading Velvet",Float)=0
        [if(_FeaturesFoldout)][HideSwitch(_VelvetToggle)]_Sheen("Sheen Color",Color)=(1,1,1,1)
        //https://google.github.io/filament/Filament.html#materialsystem/anisotropicmodel/anisotropicspecularbrdf 中的快速SS染色太严重，弃用
        //[if(_FeaturesFoldout)][HideSwitch(_VelvetToggle)]_FastSSWrap("warp for approximating SS",Range(0,1))=0
        //[if(_FeaturesFoldout)][HideSwitch(_VelvetToggle)]_VelvetSSColor("Velvet SS Color",Color)=(1,1,1,1)
        [Space(10)]
        [if(_FeaturesFoldout)][Toggle(SUBSURFACE_SCATTERING)]_SSToggle("Mobile Subsurface Scattering",Float)=0
        [if(_FeaturesFoldout)][HideSwitch(_SSToggle)]_SkinLUT("Skin LUT",2D)="white"{}
        [if(_FeaturesFoldout)][HideSwitch(_SSToggle)]_SkinInfoTexture("Curvature:R Thickness:G",2D)="black"{}
        [if(_FeaturesFoldout)][HideSwitch(_SSToggle)]_SkinShadingStr("Skin Shading Strength",Range(0,1))=0
        [if(_FeaturesFoldout)][HideSwitch(_SSToggle)]_TransShift("Transmission Shift ",Range(0,1))=0.1
        [if(_FeaturesFoldout)][HideSwitch(_SSToggle)]_TransColor("Transmission Color ",Color)=(0.5,0,0)

        [Space(10)]
        [if(_FeaturesFoldout)][Toggle(CLEAR_COAT)]_ClearCoatToggle("Clear Coat",Float)=0
        [if(_FeaturesFoldout)][HideSwitch(_ClearCoatToggle)]_ClearCoatStr("Clear Coat Strength",Range(0,1))=1
        [if(_FeaturesFoldout)][HideSwitch(_ClearCoatToggle)]_ClearCoatRoughness("Clear Coat Roughness",Range(0,1))=0.1
        [if(_FeaturesFoldout)][HideSwitch(_ClearCoatToggle)]_EdgeFalloffColor("Edge Fall Off Color",Color)=(0,0,0,1)
        [if(_FeaturesFoldout)][HideSwitch(_ClearCoatToggle)]_EdgeFalloffRange("Edge Fall Off Range",Range(0,1))=1
        

    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue" = "Geometry"}
        LOD 100
        

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}


            Cull [_CullMode] 


            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //shader feature 
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature AMR_MAP
            #pragma shader_feature EMISSION_ON
                          /*Surface Features*/
            #pragma shader_feature CLOTH_VELVET
            #pragma shader_feature SUBSURFACE_SCATTERING
            #pragma shader_feature CLEAR_COAT
            //multi compile 
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ LIGHTMAP_ON




            
         #include "PBRTemplateForwardPass.hlsl"
            

            

           
            ENDHLSL
        }
    }
    CustomEditor "UniversalShaderGUI"
}
