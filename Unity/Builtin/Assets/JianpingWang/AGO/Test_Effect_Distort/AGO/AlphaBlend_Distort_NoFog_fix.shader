﻿//JianpingWang      //20200806

Shader "Dodjoy/Effect/AlphaBlend_Distort_NoFog_fix" 
{
    Properties 
    {
        _TintColor ("Tint Color", Color) = (1,1,1,1)
        _MainTex ("MainTex", 2D) = "white" {}
        _DisortTex ("niuqu_tex", 2D) = "white" {}
        _DistortStrangth ("QD", Float ) = 0.05
        _GLOW ("GLOW", Float ) = 2
        _SpeedV ("V速度", Float ) = 0
        _SpeedU ("U速度", Float ) = 0


        _DisortMaskTex ("niuqu_tex_Mask(R)", 2D) = "white" {}
        _DisortTexMaskStrangth ("niuqu_tex_MaskStrangth", Float ) = 0.05
    }
    SubShader 
    {
        Tags 
        {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
		
		Fog {Mode Off}
		
        LOD 100
        Pass 
        {
            Name "FORWARD"
            Tags {  "LightMode"="ForwardBase"  }

            Blend SrcAlpha OneMinusSrcAlpha
			//Blend SrcAlpha One
            Cull Off
            ZWrite Off
			ColorMask RGB
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "UnityUI.cginc"

            #pragma multi_compile_fwdbase
			#pragma multi_compile __ UNITY_UI_CLIP_RECT

            uniform sampler2D _MainTex; 
            uniform float4 _MainTex_ST;

            uniform float4 _TintColor;
			float4 _ClipRect;

            uniform sampler2D _DisortTex; 
            uniform float4 _DisortTex_ST;

            uniform float _DistortStrangth;
            uniform float _GLOW;
            uniform float _SpeedV;
            uniform float _SpeedU;

            sampler2D _DisortMaskTex;
            float4 _DisortMaskTex_ST;
            float _DisortTexMaskStrangth;

            struct VertexInput 
            {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float4 vertexColor : COLOR;
            };

            struct VertexOutput 
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
				#ifdef UNITY_UI_CLIP_RECT
                float4 worldPosition : TEXCOORD1;
                #endif
                float4 vertexColor : COLOR;
            };

            VertexOutput vert (VertexInput v) 
            {
                VertexOutput o = (VertexOutput)0;
				#ifdef UNITY_UI_CLIP_RECT
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                #endif
                o.uv0 = v.texcoord0;
                o.uv1 = v.texcoord1.xy * _DisortMaskTex_ST.xy + _DisortMaskTex_ST.zw;
                o.vertexColor = v.vertexColor;
                o.pos = UnityObjectToClipPos(v.vertex );
                return o;
            }

            fixed4 frag(VertexOutput i) : COLOR 
            {
                half t = _Time.y;

                half4 mask = tex2D(_DisortMaskTex, i.uv1);

				half2 distortUV = (half2((_SpeedU*t),(_SpeedV*t))+i.uv0);
				half4 distortColor = tex2D(_DisortTex,TRANSFORM_TEX(distortUV, _DisortTex));  
				half2 mainUV = distortColor.r * _DistortStrangth * mask.r + i.uv0;

				half4 color = tex2D(_MainTex,TRANSFORM_TEX(mainUV, _MainTex));
				half3 emissive = distortColor.rgb*color.rgb * _TintColor.rgb*_GLOW;////*(color.rgb*i.vertexColor.rgb*(_TintColor.rgb*_GLOW)*color.a*i.vertexColor.a));

				half3 finalColor = emissive;

				#ifdef UNITY_UI_CLIP_RECT
                color.a *= UnityGet2DClipping(i.worldPosition.xy, _ClipRect);
                #endif
                
                half a =  distortColor.a * _TintColor.a * i.vertexColor.a * color.a;
                a = clamp(a * (1 - (1-distortColor.r) * _DisortTexMaskStrangth), 0, 1);

                return fixed4(finalColor, a);
            }

            ENDCG
        }
    }

}
