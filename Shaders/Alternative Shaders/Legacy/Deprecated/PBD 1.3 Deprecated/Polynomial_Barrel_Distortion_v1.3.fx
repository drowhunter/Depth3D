 ////------------------------------------------//
 ///**Polynomial Barrel Distortion for HMDs**///
 //-----------------------------------------////

 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //* Barrel Distortion for HMD type Displays For SuperDepth3D v1.3																													*//
 //* For Reshade 3.0																																								*//
 //* --------------------------																																						*//
 //* This work is licensed under a Creative Commons Attribution 3.0 Unported License.																								*//
 //* So you are free to share, modify and adapt it for your needs, and even use it for commercial use.																				*//
 //* I would also love to hear about a project you are using it with.																												*//
 //* https://creativecommons.org/licenses/by/3.0/us/																																*//
 //*																																												*//
 //* Have fun,																																										*//
 //* Jose Negrete AKA BlueSkyDefender																																				*//
 //*																																												*//
 //* http://reshade.me/forum/shader-presentation/2128-sidebyside-3d-depth-map-based-stereoscopic-shader																				*//	
 //* ---------------------------------																																				*//
 //* Also thank you Zapal for your help with fixing a few things in this shader. 																									*//
 //* https://reshade.me/forum/shader-presentation/2128-3d-depth-map-based-stereoscopic-shader?start=900#21236																		*//
 //* 																																												*//
 //* 																																												*//
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Determines Slave and Master Shader Toggle. This is used if you want pair this shader up with a other one of the same kind.
// One = Master;
// Zero = Slave;
#define TOGGLE 1

uniform int Interpupillary_Distance <
	ui_type = "drag";
	ui_min = -400; ui_max = 400;
	ui_label = "Interpupillary Distance";
	ui_tooltip = "Determines the distance between your eyes.\n" 
				 "In Monoscopic mode it's x offset calibration.\n"
				 "Default is 0.";
> = 0;

uniform int Stereoscopic_Mode_Convert <
	ui_type = "combo";
	ui_items = "Side by Side\0Top and Bottom\0SbS to Alt-TnB\0TnB to Alt-TnB\0Monoscopic\0Checkerboard Reconstruction\0";
	ui_label = "3D Display Mode Conversion";
	ui_tooltip = "3D display output conversion for SbS and TnB.";
> = 0;

uniform int Vertical_Repositioning <
	ui_type = "drag";
	ui_min = -500; ui_max = 500;
	ui_label = "Vertical Repositioning";
	ui_tooltip = "Determines the vertical position of the Image.\n" 
				 "In Monoscopic mode it's y offset calibration.\n"
				 "Default is 0.";
> = 0;

uniform float Lens_Center <
	ui_type = "drag";
	ui_min = 0.475; ui_max = 0.575;
	ui_label = "Lens Center";
	ui_tooltip = "Adjust Lens Center. Default is 0.5";
> = 0.5;

uniform float2 Lens_Distortion <
	ui_type = "drag";
	ui_min = -0.325; ui_max = 5;
	ui_label = "K1 & K2 Lens Distortion";
	ui_tooltip = "On the 1st lens distortion value, positive values of k1 gives barrel distortion, negative give pincushion.\n"
				 "On the 2nd lens distortion value, positive values of k2 gives barrel distortion, negative give pincushion.\n"
				 "Mainly start with k2. Default is 0.01";
> = float2(0.01,0.01);

uniform float2 Degrees <
	ui_type = "drag";
	ui_min = 0; ui_max =  360;
	ui_label = "Rotation";
	ui_tooltip = "Left & Right Rotation Angle known as Degrees.\n"
				 "Default is Zero";
> = float2(0.0,0.0);

uniform float3 Polynomial_Colors <
	ui_type = "drag";
	ui_min = 0.250; ui_max = 2.0;
	ui_tooltip = "Adjust the Polynomial Distortion Red, Green, Blue.\n"
				 "Default is (R 1.0, G 1.0, B 1.0)";
	ui_label = "Polynomial Color Distortion";
> = float3(1.0, 1.0, 1.0);

uniform float2 Zoom_Aspect_Ratio <
	ui_type = "drag";
	ui_min = 0.5; ui_max = 2;
	ui_label = "Lens Zoom & Aspect Ratio";
	ui_tooltip = "Lens Zoom amd Aspect Ratio.\n" 
				 "Default is 1.0.";
> = float2(1.0,1.0);

uniform int Custom_Sidebars <
	ui_type = "combo";
	ui_items = "Black Edges\0Stretched Edges\0";
	ui_label = "Edge Selection";
	ui_tooltip = "Select how you like the Edge of the screen to look like.";
> = 1;

uniform bool Aliment_Marker <
	ui_label = "Aliment Marker";
	ui_tooltip = "Use to this green Cross Marker for lens aliment.";
> = false;

uniform bool Vignette <
	ui_label = "Vignette";
	ui_tooltip = "Soft edge effect around the image.";
> = false;

uniform bool Diaspora <
	ui_label = "Diaspora Fix";
	ui_tooltip = "A small fix for the game Diaspora.";
> = false;

//////////////////////////////////////////////////HMD Profiles//////////////////////////////////////////////////////////////////

uniform int HMD_Profiles <
	ui_type = "combo";
	ui_items = "Off\0Profile One\0Profile Two\0"; //Add your own Profile here.
	ui_label = "HMD Profiles";
	ui_tooltip = "Head Mounted Display Profiles.";
> = 0;

float4x4 HMDProfiles()
{
float Zoom = Zoom_Aspect_Ratio.x;
float Aspect_Ratio = Zoom_Aspect_Ratio.y;

float IPD = Interpupillary_Distance;
float VRP = Vertical_Repositioning;
float LC = Lens_Center;
float LDkO = Lens_Distortion.x;
float LDkT = Lens_Distortion.y;
float Z = Zoom;
float AR = Aspect_Ratio;
float3 PC = Polynomial_Colors;
float2 D =  Degrees;
float4x4 Done;

	//Make your own Profile here.
	if (HMD_Profiles == 1)
	{
		IPD = 0.0;					//Interpupillary Distance. Default is 0
		VRP = 0;                    //Vertical Repositioning.
		LC = 0.5; 					//Lens Center. Default is 0.5
		LDkO = 0.01;				//Lens Distortion k1. Default is 0.01
		LDkT = 0.01;				//Lens Distortion k2. Default is 0.01
		Z = 1.0;					//Zoom. Default is 1.0
		AR = 1.0;					//Aspect Ratio. Default is 1.0
		PC = float3(1,1,1);			//Polynomial Colors. Default is (Red 1.0, Green 1.0, Blue 1.0)
		D = float2(0,0);			//Left & Right Rotation Angle known as Degrees.
	}
	
	//Make your own Profile here.
	if (HMD_Profiles == 2)
	{
		IPD = -25.0;				//Interpupillary Distance.
		VRP = 0;                    //Vertical Repositioning.
		LC = 0.5; 					//Lens Center. Default is 0.5
		LDkO = 0.01;				//Lens Distortion k1. Default is 0.01
		LDkT = 0.250;				//Lens Distortion k2. Default is 0.01
		Z = 1.0;					//Zoom. Default is 1.0
		AR = 0.925;					//Aspect Ratio. Default is 1.0
		PC = float3(0.5,0.75,1);	//Polynomial Colors. Default is (Red 1.0, Green 1.0, Blue 1.0)
		D = float2(0,0);			//Left & Right Rotation Angle known as Degrees.
	}

	//Rift Profile WIP
	if (HMD_Profiles == 3)
	{
		IPD = -320.0;				//Interpupillary Distance.
		VRP = 0;                    //Vertical Repositioning.
		LC = 0.5; 					//Lens Center. Default is 0.5
		LDkO = 0.01;				//Lens Distortion k1. Default is 0.01
		LDkT = 0.250;				//Lens Distortion k2. Default is 0.01
		Z = 1.0;					//Zoom. Default is 1.0
		AR = 1.0;					//Aspect Ratio. Default is 1.0
		PC = float3(1,1,1);	        //Polynomial Colors. Default is (Red 1.0, Green 1.0, Blue 1.0)
		D = float2(0,0);			//Left & Right Rotation Angle known as Degrees.
	}

if(Diaspora)
{
	Done = float4x4(float4(IPD,PC.x,Z,0),float4(LC,PC.y,AR,0),float4(LDkT,PC.z,D.x,0),float4(LDkO,VRP,D.y,0)); //Diaspora frak up 4x4 fix
}
else
{
	Done = float4x4(float4(IPD,LC,LDkT,LDkO),float4(PC.x,PC.y,PC.z,VRP),float4(Z,AR,D.x,D.y),float4(0,0,0,0));
}
return Done;
}

////////////////////////////////////////////////HMD Profiles End/////////////////////////////////////////////////////////////////

//Interpupillary Distance Section//
float IPDS()
{
	float IPDS = HMDProfiles()[0][0];
	return IPDS;
}

//Vertical Repositioning Section//
float VRePos()
{
	float VRePos = HMDProfiles()[1][3];
	return VRePos;
}

//Lens Center Section//
float LCS()
{
	float LCS = HMDProfiles()[0][1];
	return LCS;
}

//Lens Distortion Section//
float2 LD_kN()
{
	float2 LD = float2(HMDProfiles()[0][2],HMDProfiles()[0][3]);
	return LD;
}

//Lens Zoom & Aspect Ratio Section//
float2 Z_A()
{
	float2 ZA = float2(HMDProfiles()[2][0],HMDProfiles()[2][1]);
	return ZA;
}

//Polynomial Colors Section//
float3 P_C()
{
	float3 PC = float3(HMDProfiles()[1][0],HMDProfiles()[1][1],HMDProfiles()[1][2]);
	return PC;
}

//Degrees Section//
float2 DEGREES()
{
	float2 Degrees = float2(HMDProfiles()[2][2],HMDProfiles()[2][3]);
	return Degrees;
}

/////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define TextureSize float2(BUFFER_WIDTH, BUFFER_HEIGHT)


texture BackBufferTex : COLOR;

sampler BackBuffer 
	{ 
		Texture = BackBufferTex;
	};
	
#if TOGGLE
texture texCLM  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA32F;}; 
texture texCRM  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA32F;}; 
#else
texture texCLS  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA32F;}; 
texture texCRS  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA32F;}; 
#endif
	
sampler SamplerCLBORDER
	{
		#if TOGGLE
		Texture = texCLM;
		#else
		Texture = texCLS;
		#endif
		AddressU = BORDER;
		AddressV = BORDER;
		AddressW = BORDER;
	};

sampler SamplerCLCLAMP
	{
		#if TOGGLE
		Texture = texCLM;
		#else
		Texture = texCLS;
		#endif
		AddressU = CLAMP;
		AddressV = CLAMP;
		AddressW = CLAMP;
	};
	
sampler SamplerCRBORDER
	{
		#if TOGGLE
		Texture = texCRM;
		#else
		Texture = texCRS;
		#endif
		AddressU = BORDER;
		AddressV = BORDER;
		AddressW = BORDER;
	};
	
sampler SamplerCRCLAMP
	{
		#if TOGGLE
		Texture = texCRM;
		#else
		Texture = texCRS;
		#endif
		AddressU = CLAMP;
		AddressV = CLAMP;
		AddressW = CLAMP;
	};
	
////////////////////////////////////////////////////Polynomial_Distortion/////////////////////////////////////////////////////

float4 L(in float2 texcoord : TEXCOORD0)
{
	float2 gridxy = floor(float2(texcoord.x*BUFFER_WIDTH,texcoord.y*BUFFER_HEIGHT)); //Native
	return int(gridxy.x+gridxy.y) % 2 ? 0 : tex2D(BackBuffer, float2(texcoord.x,texcoord.y)) ;
}

float4 Bi_L(in float2 texcoord : TEXCOORD0)
{
   float4 tl = L(texcoord);
   float4 tr = L(texcoord +float2(pix.x, 0.0));
   float4 bl = L(texcoord +float2(0.0, pix.y));
   float4 br = L(texcoord +float2(pix.x, pix.y));
   float2 f = frac( texcoord * TextureSize );
   float4 tA = lerp( tl, tr, f.x );
   float4 tB = lerp( bl, br, f.x );
   float4 done = lerp( tA, tB, f.y ) * 2.0;//2.0 Gamma correction.
   return done;
}

float4 R(in float2 texcoord : TEXCOORD0)
{
	float2 gridxy = floor(float2(texcoord.x*BUFFER_WIDTH,texcoord.y*BUFFER_HEIGHT)); //Native
	return int(gridxy.x+gridxy.y) % 2 ? tex2D(BackBuffer, float2(texcoord.x,texcoord.y)) : 0 ;
}

float4 Bi_R(in float2 texcoord : TEXCOORD0)
{
   float4 tl = R(texcoord);
   float4 tr = R(texcoord +float2(pix.x, 0.0));
   float4 bl = R(texcoord +float2(0.0, pix.y));
   float4 br = R(texcoord +float2(pix.x, pix.y));
   float2 f = frac( texcoord * TextureSize );
   float4 tA = lerp( tl, tr, f.x );
   float4 tB = lerp( bl, br, f.x );
   float4 done = lerp( tA, tB, f.y ) * 2.0;//2.0 Gamma correction.
   return done;
}

void LR(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target0 , out float4 colorT: SV_Target1)
{	
float4 SBSL, SBSR;
	if(Stereoscopic_Mode_Convert == 0 || Stereoscopic_Mode_Convert == 2) //SbS
	{
		SBSL = tex2D(BackBuffer, float2(texcoord.x*0.5,texcoord.y));
		SBSR = tex2D(BackBuffer, float2(texcoord.x*0.5+0.5,texcoord.y));
	}
	else if(Stereoscopic_Mode_Convert == 1 || Stereoscopic_Mode_Convert == 3) //TnB
	{
		SBSL = tex2D(BackBuffer, float2(texcoord.x,texcoord.y*0.5));
		SBSR = tex2D(BackBuffer, float2(texcoord.x,texcoord.y*0.5+0.5));
	}
	else if(Stereoscopic_Mode_Convert == 4)
	{
		SBSL = tex2D(BackBuffer, float2(texcoord.x,texcoord.y)); //Monoscopic No stereo
	}
	else
	{
	//float gridy = floor(texcoord.y*(BUFFER_HEIGHT)); //Native
	//float gridx = floor(texcoord.x*(BUFFER_WIDTH)); //Native
	
	//SBSL = (int(gridy+gridx) & 1) < 0.5 ? L(texcoord) : Bi_L(texcoord) ;
	//SBSR = (int(gridy+gridx) & 1) < 0.5 ? Bi_R(texcoord) : R(texcoord) ;
	
	SBSL = Bi_L(texcoord);
	SBSR = Bi_R(texcoord);   
	}
	
color = SBSL;
colorT = SBSR;
}

float2 DL(float2 p, float k_RGB) //Cubic Lens Distortion Left
{
	float LC = 1-LCS();
	float LD_k1 = LD_kN().y; //Lens distortion value, positive values of k1 give barrel distortion, negative give pincushion.
	float r2 = (p.x-LC) * (p.x-LC) + (p.y-0.5) * (p.y-0.5);       
	
	float newRadius = 1 + r2 * LD_k1 * k_RGB + (LD_kN().x * k_RGB * r2 * r2);

	 p.x = newRadius * (p.x-0.5)+0.5;
	 p.y = newRadius * (p.y-0.5)+0.5;
	
	return p;
}

float2 DR(float2 p, float k_RGB) //Cubic Lens Distortion Right
{
	float LC = LCS();
	float LD_k1 = LD_kN().y; //Lens distortion value, positive values of k1 give barrel distortion, negative give pincushion.
	float r2 = (p.x-LC) * (p.x-LC) + (p.y-0.5) * (p.y-0.5);       
	
	float newRadius = 1 + r2 * LD_k1 * k_RGB + (LD_kN().x * k_RGB * r2 * r2);

	 p.x = newRadius  * (p.x-0.5)+0.5;
	 p.y = newRadius  * (p.y-0.5)+0.5;
	
	return p;
}

float4 vignetteL(in float2 texcoord : TEXCOORD0)
{  
float4 base;

	//Cross Marker inside left Vignette
	float2 Horz = float2(1-0.49925,0.49925);
	float2 Vert = float2(1-0.501,0.501);
	float4 A = all( texcoord < float2(Horz.x,Vert.x)) || all( texcoord > float2(Horz.x,Vert.x));
	float4 B = all( texcoord < float2(Horz.y,Vert.y)) || all( texcoord > float2(Horz.y,Vert.y));
	float4 H = A-B;
	
	if(Custom_Sidebars == 0)
	{
		base = tex2D(SamplerCLBORDER, texcoord);
	}
	else
	{
		base = tex2D(SamplerCLCLAMP, texcoord);
	}
		   
		texcoord = -texcoord * texcoord + texcoord;
		
		if( Vignette )
		base.rgb *= saturate(texcoord.x * texcoord.y * 250);
		
		if( Aliment_Marker )
		base = H ? float4(0.0,1.0,0.0,1) : base;

	return base;    
}

float4 PDL(float2 texcoord)		//Texture = texCL Left
{		
		texcoord.x += IPDS() * pix.x;
		texcoord.y += VRePos() * pix.y;
		float4 color;
		float2 uv_red, uv_green, uv_blue;
		float4 color_red, color_green, color_blue;
		float Red, Green, Blue;
		float2 sectorOrigin;

    // Radial distort around center
		sectorOrigin = (texcoord.xy-0.5,0,0);
		
		Red = 1 / P_C().x;
		Green = 1 / P_C().y;
		Blue = 1 / P_C().z;
		
		uv_red = DL(texcoord.xy-sectorOrigin,Red) + sectorOrigin;
		uv_green = DL(texcoord.xy-sectorOrigin,Green) + sectorOrigin;
		uv_blue = DL(texcoord.xy-sectorOrigin,Blue) + sectorOrigin;
		
		color_red = vignetteL(uv_red).r;
		color_green = vignetteL(uv_green).g;
		color_blue = vignetteL(uv_blue).b;

		if( ((uv_red.x > 0) && (uv_red.x < 1) && (uv_red.y > 0) && (uv_red.y < 1)))
		{
			color = float4(color_red.x, color_green.y, color_blue.z, 1.0);
		}
		else
		{
			color = float4(0,0,0,1);
		}
		return color;
		
	}


float4 vignetteR(in float2 texcoord : TEXCOORD0)
{  
float4 base;
	//Cross Marker inside Right Vignette
	float2 Horz = float2(1-0.49925,0.49925);
	float2 Vert = float2(1-0.501,0.501);
	float4 A = all( texcoord < float2(Horz.x,Vert.x)) || all( texcoord > float2(Horz.x,Vert.x));
	float4 B = all( texcoord < float2(Horz.y,Vert.y)) || all( texcoord > float2(Horz.y,Vert.y));
	float4 H = A-B;
	
		if(Custom_Sidebars == 0)
		{
		base = tex2D(SamplerCRBORDER, texcoord);
		}
		else
		{
		base = tex2D(SamplerCRCLAMP, texcoord);
		}
		   
		texcoord = -texcoord * texcoord + texcoord;
		
		if( Vignette )
		base.rgb *= saturate(texcoord.x * texcoord.y * 250);
		
		if( Aliment_Marker )
		base = H ? float4(0.0,1.0,0.0,1) : base;
	return base;    
}
	
	float4 PDR(float2 texcoord)		//Texture = texCR Right
{		
		texcoord.x -= IPDS() * pix.x;
		texcoord.y += VRePos() * pix.y;
		float4 color;
		float2 uv_red, uv_green, uv_blue;
		float4 color_red, color_green, color_blue;
		float Red, Green, Blue;
		float2 sectorOrigin;

    // Radial distort around center
		sectorOrigin = (texcoord.xy-0.5,0,0); //sectorOrigin = (texcoord.xy-0.5,0,0);
		
		Red = 1 / P_C().x;
		Green = 1 / P_C().y;
		Blue = 1 / P_C().z;
		
		uv_red = DR(texcoord.xy-sectorOrigin,Red) + sectorOrigin;
		uv_green = DR(texcoord.xy-sectorOrigin,Green) + sectorOrigin;
		uv_blue = DR(texcoord.xy-sectorOrigin,Blue) + sectorOrigin;

		color_red = vignetteR(uv_red).r;
		color_green = vignetteR(uv_green).g;
		color_blue = vignetteR(uv_blue).b;

		if( ((uv_red.x > 0) && (uv_red.x < 1) && (uv_red.y > 0) && (uv_red.y < 1)))
		{
			color = float4(color_red.x, color_green.y, color_blue.z, 1.0);
		}
		else
		{
			color = float4(0,0,0,1);
		}
		return color;
		
	}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

float4 PBDOut(float2 texcoord : TEXCOORD0)
{	
	//Texture Rotation//
	
	//Converts the specified value from radians to degrees.
	float LD = radians(DEGREES().x);
	float RD = radians(-DEGREES().y);
	float MD = radians(DEGREES().x);
	
	//Left
	float2 L_PivotPoint = float2(0.25,0.5);
    float2 L_Rotationtexcoord = texcoord;
    float L_sin_factor = sin(LD);
    float L_cos_factor = cos(LD);
    L_Rotationtexcoord = mul(L_Rotationtexcoord - L_PivotPoint, float2x2(float2(L_cos_factor, L_sin_factor), float2(-L_sin_factor, L_cos_factor)));
	L_Rotationtexcoord += L_PivotPoint;
	
	//Right
	float2 R_PivotPoint = float2(0.75,0.5);
    float2 R_Rotationtexcoord = texcoord;
    float R_sin_factor = sin(RD);
    float R_cos_factor = cos(RD);
    R_Rotationtexcoord = mul(R_Rotationtexcoord - R_PivotPoint, float2x2(float2(R_cos_factor, R_sin_factor), float2(-R_sin_factor, R_cos_factor)));
	R_Rotationtexcoord += R_PivotPoint;
	
	//Mono
	float2 PivotPoint = float2(0.5,0.5);
    float2 Rotationtexcoord = texcoord;
    float sin_factor = sin(MD);
    float cos_factor = cos(MD);
    Rotationtexcoord = mul(Rotationtexcoord - PivotPoint, float2x2(float2(cos_factor, sin_factor), float2(-sin_factor, cos_factor)));
	Rotationtexcoord += PivotPoint;	
	//Texture Rotation End//

	float4 Out;
	
	float X = Z_A().x;
	float Y = Z_A().y * Z_A().x * 2;
	
	float midW = (X - 1)*(BUFFER_WIDTH*0.5)*pix.x;	
	float midH = (Y - 1)*(BUFFER_HEIGHT*0.5)*pix.y;	
	
	if( Stereoscopic_Mode_Convert == 0 || Stereoscopic_Mode_Convert == 1|| Stereoscopic_Mode_Convert == 5 )
	{
		Out = texcoord.x < 0.5 ? PDL(float2(((L_Rotationtexcoord.x*2)*X)-midW ,(L_Rotationtexcoord.y*Y)-midH)) : PDR(float2(((R_Rotationtexcoord.x*2-1)*X)-midW ,(R_Rotationtexcoord.y*Y)-midH));
	}
	else if (Stereoscopic_Mode_Convert == 2 || Stereoscopic_Mode_Convert == 3)
	{
		Out = texcoord.y < 0.5 ? PDL(float2((L_Rotationtexcoord.x*X)-midW ,((L_Rotationtexcoord.y*2)*Y)-midH)) : PDR(float2((R_Rotationtexcoord.x*X)-midW ,((R_Rotationtexcoord.y*2-1)*Y)-midH));
	}
	else if (Stereoscopic_Mode_Convert == 4 )
	{
		Out = PDL(float2((Rotationtexcoord.x*X)-midW ,(Rotationtexcoord.y*Y)-midH));
	}
	
	return Out;
}

////////////////////////////////////////////////////////Logo/////////////////////////////////////////////////////////////////////////
uniform float timer < source = "timer"; >;


float4 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float PosX = 0.5*BUFFER_WIDTH*pix.x,PosY = 0.5*BUFFER_HEIGHT*pix.y;	
	float4 Color = PBDOut(texcoord),Done,Website,D,E,P,T,H,Three,DD,Dot,I,N,F,O;
	
	if(timer <= 10000)
	{
	//DEPTH
	//D
	float PosXD = -0.035+PosX, offsetD = 0.001;
	float4 OneD = all( abs(float2( texcoord.x -PosXD, texcoord.y-PosY)) < float2(0.0025,0.009));
	float4 TwoD = all( abs(float2( texcoord.x -PosXD-offsetD, texcoord.y-PosY)) < float2(0.0025,0.007));
	D = OneD-TwoD;
	
	//E
	float PosXE = -0.028+PosX, offsetE = 0.0005;
	float4 OneE = all( abs(float2( texcoord.x -PosXE, texcoord.y-PosY)) < float2(0.003,0.009));
	float4 TwoE = all( abs(float2( texcoord.x -PosXE-offsetE, texcoord.y-PosY)) < float2(0.0025,0.007));
	float4 ThreeE = all( abs(float2( texcoord.x -PosXE, texcoord.y-PosY)) < float2(0.003,0.001));
	E = (OneE-TwoE)+ThreeE;
	
	//P
	float PosXP = -0.0215+PosX, PosYP = -0.0025+PosY, offsetP = 0.001, offsetP1 = 0.002;
	float4 OneP = all( abs(float2( texcoord.x -PosXP, texcoord.y-PosYP)) < float2(0.0025,0.009*0.682));
	float4 TwoP = all( abs(float2( texcoord.x -PosXP-offsetP, texcoord.y-PosYP)) < float2(0.0025,0.007*0.682));
	float4 ThreeP = all( abs(float2( texcoord.x -PosXP+offsetP1, texcoord.y-PosY)) < float2(0.0005,0.009));
	P = (OneP-TwoP) + ThreeP;

	//T
	float PosXT = -0.014+PosX, PosYT = -0.008+PosY;
	float4 OneT = all( abs(float2( texcoord.x -PosXT, texcoord.y-PosYT)) < float2(0.003,0.001));
	float4 TwoT = all( abs(float2( texcoord.x -PosXT, texcoord.y-PosY)) < float2(0.000625,0.009));
	T = OneT+TwoT;
	
	//H
	float PosXH = -0.0071+PosX;
	float4 OneH = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.002,0.001));
	float4 TwoH = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.002,0.009));
	float4 ThreeH = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.003,0.009));
	H = (OneH-TwoH)+ThreeH;
	
	//Three
	float offsetFive = 0.001, PosX3 = -0.001+PosX;
	float4 OneThree = all( abs(float2( texcoord.x -PosX3, texcoord.y-PosY)) < float2(0.002,0.009));
	float4 TwoThree = all( abs(float2( texcoord.x -PosX3 - offsetFive, texcoord.y-PosY)) < float2(0.003,0.007));
	float4 ThreeThree = all( abs(float2( texcoord.x -PosX3, texcoord.y-PosY)) < float2(0.002,0.001));
	Three = (OneThree-TwoThree)+ThreeThree;
	
	//DD
	float PosXDD = 0.006+PosX, offsetDD = 0.001;	
	float4 OneDD = all( abs(float2( texcoord.x -PosXDD, texcoord.y-PosY)) < float2(0.0025,0.009));
	float4 TwoDD = all( abs(float2( texcoord.x -PosXDD-offsetDD, texcoord.y-PosY)) < float2(0.0025,0.007));
	DD = OneDD-TwoDD;
	
	//Dot
	float PosXDot = 0.011+PosX, PosYDot = 0.008+PosY;		
	float4 OneDot = all( abs(float2( texcoord.x -PosXDot, texcoord.y-PosYDot)) < float2(0.00075,0.0015));
	Dot = OneDot;
	
	//INFO
	//I
	float PosXI = 0.0155+PosX, PosYI = 0.004+PosY, PosYII = 0.008+PosY;
	float4 OneI = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosY)) < float2(0.003,0.001));
	float4 TwoI = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosYI)) < float2(0.000625,0.005));
	float4 ThreeI = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosYII)) < float2(0.003,0.001));
	I = OneI+TwoI+ThreeI;
	
	//N
	float PosXN = 0.0225+PosX, PosYN = 0.005+PosY,offsetN = -0.001;
	float4 OneN = all( abs(float2( texcoord.x - PosXN, texcoord.y - PosYN)) < float2(0.002,0.004));
	float4 TwoN = all( abs(float2( texcoord.x - PosXN, texcoord.y - PosYN - offsetN)) < float2(0.003,0.005));
	N = OneN-TwoN;
	
	//F
	float PosXF = 0.029+PosX, PosYF = 0.004+PosY, offsetF = 0.0005, offsetF1 = 0.001;
	float4 OneF = all( abs(float2( texcoord.x -PosXF-offsetF, texcoord.y-PosYF-offsetF1)) < float2(0.002,0.004));
	float4 TwoF = all( abs(float2( texcoord.x -PosXF, texcoord.y-PosYF)) < float2(0.0025,0.005));
	float4 ThreeF = all( abs(float2( texcoord.x -PosXF, texcoord.y-PosYF)) < float2(0.0015,0.00075));
	F = (OneF-TwoF)+ThreeF;
	
	//O
	float PosXO = 0.035+PosX, PosYO = 0.004+PosY;
	float4 OneO = all( abs(float2( texcoord.x -PosXO, texcoord.y-PosYO)) < float2(0.003,0.005));
	float4 TwoO = all( abs(float2( texcoord.x -PosXO, texcoord.y-PosYO)) < float2(0.002,0.003));
	O = OneO-TwoO;
	}
	
	Website = D+E+P+T+H+Three+DD+Dot+I+N+F+O ? float4(1.0,1.0,1.0,1) : Color;
	
	if(timer >= 10000)
	{
	Done = Color;
	}
	else
	{
	Done = Website;
	}

	return Done;
}

///////////////////////////////////////////////////////////ReShade.fxh/////////////////////////////////////////////////////////////

// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

//*Rendering passes*//
#if TOGGLE
technique Polynomial_Barrel_Distortion_M
#else
technique Polynomial_Barrel_Distortion_S
#endif
{		
			pass StereoMonoPass
		{
			VertexShader = PostProcessVS;
			PixelShader = LR;
			#if TOGGLE
			RenderTarget0 = texCLM;
			RenderTarget1 = texCRM;
			#else
			RenderTarget0 = texCLS;
			RenderTarget1 = texCRS;
			#endif
		}
			pass PBD
		{
			VertexShader = PostProcessVS;
			PixelShader = Out;	
		}
}
