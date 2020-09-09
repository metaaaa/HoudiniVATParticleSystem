Shader "metaaa/fluidsVATParticle"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_boundingMax("Bounding Max", Float) = 1.0
		_boundingMin("Bounding Min", Float) = 1.0
		_numOfFrames("Number Of Frames", int) = 240
		_speed("Speed", Float) = 0.33
		_posTex ("Position Map (RGB)", 2D) = "white" {}
		_nTex ("Normal Map (RGB)", 2D) = "grey" {}
        _colorTex ("Colour Map (RGB)", 2D) = "white" {}

		_BumpMap ("Bumpmap", 2D) = "bump" {}
        _Detail ("Detail", 2D) = "gray" {}
		_EmissionTex("EmissionTexture",2D) = "white"{}
		_EmissionColor("EmissionColor",Color) = (1,1,1,1)
		_EmissionIntensity("EmissionIntensity",Float) = 0
    }
    SubShader
    {
        Tags {
			"Queue"      = "Geometry"
			"RenderType" = "Opaque"
		}
        LOD 200 Cull Off

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard addshadow fullforwardshadows 
        #pragma vertex vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 5.0

        sampler2D _MainTex;
        sampler2D _BumpMap, _EmissionTex;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color,_EmissionColor;
        sampler2D _Detail;
        float _EmissionIntensity;

		sampler2D _posTex;
		sampler2D _nTex;
        sampler2D _colorTex;
		uniform float _boundingMax;
		uniform float _boundingMin;
		uniform float _speed;
		uniform int _numOfFrames;

        struct appdata_particles {
            float4 vertex : POSITION;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
            float4 color : COLOR;
            float4 texcoord : TEXCOORD0;
            float4 texcoord1 : TEXCOORD1;//xyz=center,w= stable rand.x
            float4 texcoord2 : TEXCOORD2;
            float4 texcoord3 : TEXCOORD3;

            };

        struct Input {
            float2 uv_MainTex;
			float2 uv_BumpMap;
			float2 uv_Detail;
            float4 color;
			float3 viewDir;
            float4 vcolor : COLOR ;
        };

        float2 rot(float2 p, float r)
        {
            float c = cos(r);
            float s = sin(r);
            return mul(p, float2x2(c, -s, s, c));
        }

 

        void vert(inout appdata_particles v, out Input o) 
        {
            v.vertex.xyz -= v.texcoord1.xyz;//ローカル座標に変換
			float rand=v.texcoord1.w;
			//calcualte uv coordinates
			float timeInFrames = ((ceil(frac(-_Time.y * _speed) * _numOfFrames))/_numOfFrames) + (1.0/_numOfFrames);

			//get position and normal from textures
			float4 pos = tex2Dlod(_posTex,float4(v.texcoord.z, (timeInFrames + v.texcoord.w), 0, 0));
			float3 normal = tex2Dlod(_nTex,float4(v.texcoord.z, (timeInFrames + v.texcoord.w), 0, 0));
            float3 textureCd = tex2Dlod(_colorTex,float4(v.texcoord.z, (timeInFrames + v.texcoord.w), 0, 0));


			//expand normalised position texture values to world space
			float expand = _boundingMax - _boundingMin;
			pos.xyz *= expand;
			pos.xyz += _boundingMin;
			pos.x *= -1;  //flipped to account for right-handedness of unity
            pos.xyz =  pos.xzy;

            pos.xy=rot(pos.xy,-v.texcoord2.z);
            pos.xz=rot(pos.xz,-v.texcoord2.y);
            pos.yz=rot(pos.yz,-v.texcoord2.x);
            pos.xyz*=v.texcoord3.xyz;

            pos.xyz+=v.texcoord1.xyz;
            v.vertex=pos;
            //v.normal=normal;
            normal = normal.xzy;
            normal *= 2;
            normal -= 1;
            normal.x *= -1;
            v.normal = normal;
            v.color.rgb = textureCd;
            UNITY_INITIALIZE_OUTPUT(Input,o);
            o.uv_MainTex = v.texcoord.xy;
            o.color = v.color;
            
        }

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;// * IN.color;
            o.Albedo = c.rgb * IN.vcolor.rgb;
            o.Albedo = c.rgb;
			o.Normal = UnpackNormal (tex2D (_BumpMap, IN.uv_BumpMap));
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
