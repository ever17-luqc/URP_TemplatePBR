#ifndef PBR_TEMPLATE_FORWARD_PASS_INCLUDED
#define PBR_TEMPLATE_FORWARD_PASS_INCLUDED
 
           #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        //Struct===============================================================================
            struct PBRTemplateAttributes   
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
                float2 lightmapUV   : TEXCOORD1;  
            };
 
            struct PBRTemplateVaryings
            {
                float2 uv                       : TEXCOORD0;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, SHLight, 1);   //如果lightmap开启也就是烘焙了场景lightmap会声明lightmapUV：TEXCOORD1;实时不能用静态的lightmap用球谐光照
                float3 positionWS               : TEXCOORD2;
                float3 normalWS                 : TEXCOORD3;
                float4 tangentWS                : TEXCOORD4; 
                float3 viewDirWS                : TEXCOORD5;
                float4 positionCS               : SV_POSITION;
            };

            struct PBRTemplateSurfaceData
            {
                half3 albedo;
                half  metallic;
                half  roughness;
                half3 normalTS;
                half3 emission;
                half  occlusion;
                half  alpha;
                half2 skinData;
                half  clearcoatRoughness;
           

            };

            struct PBRTemplateInputData
            {
                float3  positionWS;
                half3   normalWS;
                half3   viewDirectionWS;
                float4  shadowCoord;
                //half    fogCoord;
                //half3   vertexLighting;
                half3   bakedGI;
                //float2  normalizedScreenSpaceUV;
                half4   shadowMask;
            };
            //Struct===============================================================================

             //CBuffer---------------------Start
            CBUFFER_START(UnityPerMaterial)
                //******base Prop*******//
            half4 _Tint;
            float4 _GlobalTilingAndOffset;
            half _MetallicStr;
            half _RoughnessStr;
            float _NormalScale;
            float4 _EmissionColor;
            half4  _Sheen;
            //half _FastSSWrap;
            //half4 _VelvetSSColor;
            half _SkinShadingStr;
            half _TransShift;
            half4 _TransColor;
            half _ClearCoatStr;
            half _ClearCoatRoughness;
            half4 _EdgeFalloffColor;
            float _EdgeFalloffRange;
            CBUFFER_END
            //CBuffer---------------------End

       
            TEXTURE2D(_BaseTexture);                    SAMPLER(sampler_BaseTexture);
            TEXTURE2D(_AOMetallicRoughnessMap);         SAMPLER(sampler_AOMetallicRoughnessMap);
            TEXTURE2D(_EmissionMap);                    SAMPLER(sampler_EmissionMap);
            TEXTURE2D(_NormalMap);                      SAMPLER(sampler_NormalMap);
            TEXTURE2D(_SkinLUT);                        SAMPLER(sampler_SkinLUT);
            TEXTURE2D(_SkinInfoTexture);                SAMPLER(sampler_SkinInfoTexture);


             //hlsl Include 
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #include "PBRTemplateMain.hlsl"
       
           
    
            ////////////////////////////////////////////////////////////////////////////////

            //                           frag Function                                    //

            ///////////////////////////////////////////////////////////////////////////////
            half3 SampleNormal(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), half scale = 1.0h)
            {
                #ifdef _NORMALMAP
                    half4 n = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
                    #if BUMP_SCALE_NOT_SUPPORTED
                        return UnpackNormal(n);
                    #else
                        return UnpackNormalScale(n, scale);
                    #endif
                #else
                    return half3(0.0h, 0.0h, 1.0h);
                #endif
            }

            half3 SampleEmission(float2 uv, half3 emissionColor, TEXTURE2D_PARAM(emissionMap, sampler_emissionMap))
            {
                #ifndef EMISSION_ON
                    return 0;
                #else
                    return SAMPLE_TEXTURE2D(emissionMap, sampler_emissionMap, uv).rgb * emissionColor;
                #endif
                }
              

            inline void InitializePBRTemplateSurfaceData(float2 uv,out PBRTemplateSurfaceData surfaceData)
            {
                   half4 albedo = SAMPLE_TEXTURE2D(_BaseTexture,sampler_BaseTexture,uv);
                    surfaceData.alpha =albedo.a;

                    half4 AMR = SAMPLE_TEXTURE2D(_AOMetallicRoughnessMap, sampler_AOMetallicRoughnessMap,uv);
                    surfaceData.albedo = albedo.rgb ;

                #ifdef AMR_MAP
                    surfaceData.metallic = AMR.g;
                    surfaceData.roughness = AMR.a*_RoughnessStr;
                #else
                    surfaceData.metallic = _MetallicStr;
                    surfaceData.roughness = _RoughnessStr;

                #endif
                
                #ifdef SUBSURFACE_SCATTERING
                    surfaceData.skinData=SAMPLE_TEXTURE2D(_SkinInfoTexture,sampler_SkinInfoTexture,uv).rg;
                #else 
                    surfaceData.skinData=0;
                #endif


                    
                    surfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_NormalMap, sampler_NormalMap), _NormalScale);
                    surfaceData.occlusion = AMR.r;
                    surfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));

                #ifdef CLEAR_COAT
                    surfaceData.clearcoatRoughness=_ClearCoatRoughness;
                #else
                    surfaceData.clearcoatRoughness=0;
                #endif 


            }
            inline void InitializePBRTemplateInputData(PBRTemplateVaryings input, half3 normalTS, out PBRTemplateInputData inputData)
            {
                inputData = (PBRTemplateInputData)0;

                inputData.positionWS = input.positionWS;
            
                half3 viewDirWS = SafeNormalize(input.viewDirWS);
            #if defined(_NORMALMAP)
                float sgn = input.tangentWS.w;      // should be either +1 or -1
                float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
            #else
                inputData.normalWS = input.normalWS;
            #endif
               
            
                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                inputData.viewDirectionWS = viewDirWS;

                inputData.shadowCoord=TransformWorldToShadowCoord(input.positionWS);
                inputData.shadowMask=SAMPLE_SHADOWMASK(input.lightmapUV);            //shadowmask烘焙返回shadowmask，否则返回探针阴影数据，如果都没开启就返回1
            #ifdef LIGHTMAP_ON
                inputData.bakedGI=SampleLightmap(input.lightmapUV,inputData.normalWS);
            #else
                inputData.bakedGI=SampleSH(inputData.normalWS);                      //这里直接用SampleSH在片元做全阶球谐，unity的做法有只算顶点低阶的球谐，和顶点低阶片元高阶结合的球谐，这里这么写仅仅是方便起见（排除过多分支写起来麻烦）。
            #endif
            

            
            }
            



            ////////////////////////////////////////////////////////////////////////////////

            //                           vertex and fragment shader                      //

            ///////////////////////////////////////////////////////////////////////////////
            PBRTemplateVaryings vert (PBRTemplateAttributes v)
            {
                
                PBRTemplateVaryings output = (PBRTemplateVaryings)0;
                
                output.uv = v.texcoord*_GlobalTilingAndOffset.xy+_GlobalTilingAndOffset.zw;
                output.positionWS=TransformObjectToWorld(v.positionOS);
                output.viewDirWS=normalize( GetCameraPositionWS()-output.positionWS);
                output.normalWS=TransformObjectToWorldNormal(v.normalOS);
                output.tangentWS=half4(TransformObjectToWorldDir(v.tangentOS),v.tangentOS.w);;
                output.positionCS=TransformObjectToHClip(v.positionOS);
           
               
                return output;
            }

             half4 frag (PBRTemplateVaryings input) : SV_Target
            {
                PBRTemplateSurfaceData surfaceData;
                InitializePBRTemplateSurfaceData(input.uv, surfaceData);


                PBRTemplateInputData inputData;
                InitializePBRTemplateInputData(input, surfaceData.normalTS, inputData);

                half4 color = CustomUniversalFragmentPBR(inputData, surfaceData);
                 
                
                color.a = 1;

                return color;
            }
            

#endif