 ////------------- --//
 ///**SuperDepth3D**///
 //----------------////

 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //* Depth Map Based 3D post-process shader v1.9.9          																														*//
 //* For Reshade 3.0																																								*//
 //* --------------------------																																						*//
 //* This work is licensed under a Creative Commons Attribution 3.0 Unported License.																								*//
 //* So you are free to share, modify and adapt it for your needs, and even use it for commercial use.																				*//
 //* I would also love to hear about a project you are using it with.																												*//
 //* https://creativecommons.org/licenses/by/3.0/us/																																*//
 //*																																												*//
 //* Jose Negrete AKA BlueSkyDefender																																				*//
 //*																																												*//
 //* http://reshade.me/forum/shader-presentation/2128-sidebyside-3d-depth-map-based-stereoscopic-shader																				*//	
 //* ---------------------------------																																				*//
 //*																																												*//
 //* Original work was based on the shader code of a CryTech 3 Dev http://www.slideshare.net/TiagoAlexSousa/secrets-of-cryengine-3-graphics-technology								*//
 //*																																												*//
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//USER EDITABLE PREPROCESSOR FUNCTIONS START//

// Determines The resolution of the Depth Map. For 4k Use 1.75 or 1.5. For 1440p Use 1.5 or 1.25. For 1080p use 1. Too low of a resolution will remove too much.
#define Depth_Map_Division 1.0

// Determines the Max Depth amount, in ReShades GUI.
#define Depth_Max 50

// Enable this to fix the problem when there is a full screen Game Map Poping out of the screen. AKA Full Black Depth Map Fix. I have this off by default. Zero is off, One is On.
#define FBDMF 0 //Default 0 is Off. One is On.

//Third person auto zero parallax distance is a form of Automatic Near Field Adjustment based on BOTW fix. This now should work on all Third Person Games. 
#define TPAuto_ZPD 0 //Default 0 is Off. One is On.

// Change the Cancel Depth Key
// Determines the Cancel Depth Toggle Key useing keycode info
// You can use http://keycode.info/ to figure out what key is what.
// key "." is Key Code 110. Ex. Key 110 is the code for Decimal Point.
#define Cancel_Depth_Key 0

//3D AO Toggle enable this if you want better 3D seperation between objects. 
//There will be a performance loss when enabled.
#define AO_TOGGLE 0 //Default 0 is Off. One is On.

//Use Depth Tool to adjust the lower preprocessor definitions below.
//Horizontal & Vertical Depth Buffer Resize for non conforming BackBuffer.
//Ex. Resident Evil 7 Has this problem. So you want to adjust it too around float2(0.9575,0.9575).
#define Horizontal_and_Vertical float2(1.0, 1.0) //Min value is -0.5 & Max value is 0.5 Default is Zero.

//Image Position Adjust is used to move the Z-Buffer around.
#define Image_Position_Adjust float2(0.0,0.0)

//USER EDITABLE PREPROCESSOR FUNCTIONS END//
//Divergence & Convergence//
uniform float Divergence <
	ui_type = "drag";
	ui_min = 1; ui_max = Depth_Max;
	ui_label = "·Divergence Slider·";
	ui_tooltip = "Determines the amount of Image Warping and Separation.\n" 
				 "You can override this value.";
	ui_category = "Divergence & Convergence";
> = 35.0;

uniform int Convergence_Mode <
	ui_type = "combo";
	ui_items = "ZPD Tied\0ZPD Locked\0ZPD Unlocked\0";
	ui_label = " Convergence Mode";
	ui_tooltip = "Select your Convergence Mode for ZPD calculations.\n" 
				 "ZPD Locked mode is locked to divergence & dissables ZPD control below.\n" 
				 "ZPD Unlocked mode lets you control ZPD separately from Divergence.\n" 
				 "ZPD Tied is controlled by ZPD. Works in tandam with Divergence.\n" 
				 "For FPS with no custom weapon profile use Tied.\n" 
				 "Default is ZPD Tied.";
	ui_category = "Divergence & Convergence";
> = 0;

uniform float ZPD <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.500;
	ui_label = " Zero Parallax Distance";
	ui_tooltip = "ZPD controls the focus distance for the screen Pop-out effect also known as Convergence.\n"
				"For FPS Games keeps this low Since you don't want your gun to pop out of screen.\n"
				"This is controled by Convergence Mode.\n"
				"Default is 0.010, Zero is off.";
	ui_category = "Divergence & Convergence";
> = 0.010;

uniform int Balance <
	ui_type = "drag";
	ui_min = -4.0; ui_max = 6.0;
	ui_label = " Balance";
	ui_tooltip = "Balance between ZPD Depth and Scene Depth and works with ZPD option above.\n"
				"Example Zero is 50/50 equal between ZPD Depth and Scene Depth.\n"
				"Default is Zero.";
	ui_category = "Divergence & Convergence";
> = 0;

uniform float Auto_Depth_Range <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.625;
	ui_label = " Auto Depth Range";
	ui_tooltip = "The Map Automaticly scales to outdoor and indoor areas.\n" 
				 "Default is Zero, Zero is off.";
	ui_category = "Divergence & Convergence";
> = 0.0;
//Occlusion Masking//
uniform int Disocclusion_Selection <
	ui_type = "combo";
	ui_items = "Off\0Radial Blur\0Normal Blur\0Depth Based\0Radial Depth Blur\0Normal Depth Blur\0";
	ui_label = "·Disocclusion Selection·";
	ui_tooltip = "This is to select the z-Buffer bluring option for low level occlusion masking.\n"
				"Default is Normal Blur.";
	ui_category = "Occlusion Masking";
> = 2;

uniform float Disocclusion_Power_Adjust <
	ui_type = "drag";
	ui_min = 0.250; ui_max = 2.5;
	ui_label = " Disocclusion Power Adjust";
	ui_tooltip = "Automatic occlusion masking power adjust.\n"
				"Default is 1.0";
	ui_category = "Occlusion Masking";
> = 1.0;

uniform int View_Mode <
	ui_type = "combo";
	ui_items = "View Mode Normal\0View Mode Alpha\0View Mode Beta\0View Mode Gamma -=WIP=-\0";
	ui_label = " View Mode";
	ui_tooltip = "Change the way the shader warps the output to the screen.\n"
				 "Default is Normal";
	ui_category = "Occlusion Masking";
> = 0;

uniform int Custom_Sidebars <
	ui_type = "combo";
	ui_items = "Mirrored Edges\0Black Edges\0Stretched Edges\0";
	ui_label = " Edge Handling";
	ui_tooltip = "Edges selection for your screen output.";
	ui_category = "Occlusion Masking";
> = 1;
//Depth Map//
uniform int Depth_Map <
	ui_type = "combo";
	ui_items = " 0 Normal\0 1 Normal Reversed\0 2 Offset Normal\0 3 Offset Reversed\0";
	ui_label = "·Depth Map Selection·";
	ui_tooltip = "Linearization for the zBuffer also known as Depth Map.\n"
			     "Normally you want to use 0 or 1.";
	ui_category = "Depth Map";
> = 0;

uniform float Depth_Map_Adjust <
	ui_type = "drag";
	ui_min = 0.250; ui_max = 125.0;
	ui_label = " Depth Map Adjustment";
	ui_tooltip = "Adjust the depth map for your games.";
	ui_category = "Depth Map";
> = 7.5;

uniform float Offsets <
	ui_type = "drag";
	ui_min = 0; ui_max = 1.0;
	ui_label = " Offset";
	ui_tooltip = "Offset is for the Special Depth Map Only";
	ui_category = "Depth Map";
> = 0.5;

uniform bool Depth_Map_View <
	ui_label = " Depth Map View";
	ui_tooltip = "Display the Depth Map.";
	ui_category = "Depth Map";
> = false;

uniform bool Depth_Map_Flip <
	ui_label = " Depth Map Flip";
	ui_tooltip = "Flip the depth map if it is upside down.";
	ui_category = "Depth Map";
> = false;
//Weapon & HUD Depth Map//
uniform int WP <
	ui_type = "combo";
	ui_items = "Weapon Profile Off\0Custom WP\0 WP 0\0 WP 1\0 WP 2\0 WP 3\0 WP 4\0 WP 5\0 WP 6\0 WP 7\0 WP 8\0 WP 9\0 WP 10\0 WP 11\0 WP 12\0 WP 13\0 WP 14\0 WP 15\0 WP 16\0 WP 17\0 WP 18\0 WP 19\0 WP 20\0 WP 21\0 WP 22\0 WP 23\0 WP 24\0 WP 25\0 WP 26\0 WP 27\0 WP 28\0 WP 29\0 WP 30\0 HUD Mode One\0";
	ui_label = "·HUD & Weapon Profiles·";
	ui_tooltip = "Pick your HUD or Weapon Profile for your game or make your own.";
	ui_category = "Weapon & HUD Depth Map";
> = 0;

uniform float4 Weapon_Adjust <
	ui_type = "drag";
	ui_min = -100.0; ui_max = 100.0;
	ui_label = " Weapon Adjust Depth Map";
	ui_tooltip = "Adjust weapon depth map for FPS Hand & also HUD Mode.\n"
				 "X, is FPS Hand Scale Adjustment & Adjusts HUD Mode.\n"
				 "Y, is Cutoff Point Adjustment.\n"
				 "Z, Zero is Auto.\n"
				 "W, is Weapon Depth Adjustment.\n"
				 "Pushes or Pulls the FPS Hand in or out of the screen.\n"
				 "This also used to fine tune the Weapon Hand.\n" 
				 "Default is (X 0.250, Y 0.0, Z 0.0, W 0.0).";
	ui_category = "Weapon & HUD Depth Map";
> = float4(0.0,0.250,0.0,0.0);
//Stereoscopic Options//
uniform int Stereoscopic_Mode <
	ui_type = "combo";
	ui_items = "Side by Side\0Top and Bottom\0Line Interlaced\0Column Interlaced\0Checkerboard 3D\0Anaglyph\0";
	ui_label = "·3D Display Modes·";
	ui_tooltip = "Stereoscopic 3D display output selection.";
	ui_category = "Stereoscopic Options";
> = 0;

uniform float Interlace_Optimization <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.5;
	ui_label = " Interlace Optimization";
	ui_tooltip = "Interlace Optimization Is used to reduce alisesing in a Line or Column interlaced image.\n"
	             "This has the side effect of softening the image.\n"
	             "Default is 0.375";
	ui_category = "Stereoscopic Options";
> = 0.375;

uniform int Anaglyph_Colors <
	ui_type = "combo";
	ui_items = "Red/Cyan\0Dubois Red/Cyan\0Green/Magenta\0Dubois Green/Magenta\0";
	ui_label = " Anaglyph Color Mode";
	ui_tooltip = "Select colors for your 3D anaglyph glasses.";
	ui_category = "Stereoscopic Options";
> = 0;

uniform float Anaglyph_Desaturation <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = " Anaglyph Desaturation";
	ui_tooltip = "Adjust anaglyph desaturation, Zero is Black & White, One is full color.";
	ui_category = "Stereoscopic Options";
> = 1.0;

uniform int Scaling_Support <
	ui_type = "combo";
	ui_items = " 2160p\0 Native\0 1080p A\0 1080p B\0 1050p A\0 1050p B\0 720p A\0 720p B\0";
	ui_label = " Scaling Support";
	ui_tooltip = "Dynamic Super Resolution , Virtual Super Resolution, downscaling, or Upscaling support for Line Interlaced, Column Interlaced, & Checkerboard 3D displays.";
	ui_category = "Stereoscopic Options";
> = 1;

uniform float Perspective <
	ui_type = "drag";
	ui_min = -100; ui_max = 100;
	ui_label = " Perspective Slider";
	ui_tooltip = "Determines the perspective point. Default is 0";
	ui_category = "Stereoscopic Options";
> = 0;

uniform bool Eye_Swap <
	ui_label = " Swap Eyes";
	ui_tooltip = "L/R to R/L.";
	ui_category = "Stereoscopic Options";
> = false;
//3D Ambient Occlusion//
#if AO_TOGGLE
uniform bool AO <
	ui_label = "·3D AO Switch·";
	ui_tooltip = "3D Ambient occlusion mode switch.\n"
				 "Performance loss when enabled.\n"
				 "Default is On.";
	ui_category = "3D Ambient Occlusion";
> = 1;

uniform float AO_Control <
	ui_type = "drag";
	ui_min = 0.001; ui_max = 1.25;
	ui_label = " 3D AO Control";
	ui_tooltip = "Control the spread of the 3D AO.\n" 
				 "Default is 0.5625.";
	ui_category = "3D Ambient Occlusion";
> = 0.5625;

uniform float AO_Power <
	ui_type = "drag";
	ui_min = 0.001; ui_max = 0.100;
	ui_label = " 3D AO Power";
	ui_tooltip = "Adjust the power 3D AO.\n" 
				 "Default is 0.05.";
	ui_category = "3D Ambient Occlusion";
> = 0.05;
#endif
//Cursor Adjustments//
uniform float4 Cross_Cursor_Adjust <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 255.0;
	ui_label = "·Cross Cursor Adjust·";
	ui_tooltip = "Pick your own cross cursor color & Size.\n" 
				 " Default is (R 255, G 255, B 255 , Size 25)";
	ui_category = "Cursor Adjustments";
> = float4(255.0, 255.0, 255.0, 25.0);

uniform bool Cancel_Depth < source = "key"; keycode = Cancel_Depth_Key; toggle = true; >;
/////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)

texture DepthBufferTex : DEPTH;

sampler DepthBuffer 
	{ 
		Texture = DepthBufferTex; 
	};

texture BackBufferTex : COLOR;

sampler BackBuffer 
	{ 
		Texture = BackBufferTex;
	};
	
sampler BackBufferMIRROR 
	{ 
		Texture = BackBufferTex;
		AddressU = MIRROR;
		AddressV = MIRROR;
		AddressW = MIRROR;
	};

sampler BackBufferBORDER
	{ 
		Texture = BackBufferTex;
		AddressU = BORDER;
		AddressV = BORDER;
		AddressW = BORDER;
	};

sampler BackBufferCLAMP
	{ 
		Texture = BackBufferTex;
		AddressU = CLAMP;
		AddressV = CLAMP;
		AddressW = CLAMP;
	};
	
texture texDM  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT/Depth_Map_Division; Format = RGBA32F;}; 

sampler SamplerDM
	{
		Texture = texDM;
	};
	
texture texDis  { Width = BUFFER_WIDTH/Depth_Map_Division; Height = BUFFER_HEIGHT/Depth_Map_Division; Format = RGBA32F;}; 

sampler SamplerDis
	{
		Texture = texDis;
	};
	
#if AO_TOGGLE	
texture texAO  { Width = BUFFER_WIDTH*0.5; Height = BUFFER_HEIGHT*0.5; Format = RGBA8; MipLevels = 1;}; 

sampler SamplerAO
	{
		Texture = texAO;
		MipLODBias = 1.0f;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};
#endif
		
uniform float2 Mousecoords < source = "mousepoint"; > ;	
////////////////////////////////////////////////////////////////////////////////////Cross Cursor////////////////////////////////////////////////////////////////////////////////////	
float4 MouseCursor(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 MousecoordsXY = Mousecoords * pix;
	float2 CC_Size = Cross_Cursor_Adjust.a * pix;
	float2 CC_Mode;
	//Adjust for CC for Stereoscopic Mode.
	if(Stereoscopic_Mode == 0 || Stereoscopic_Mode == 1)
	{
		CC_Mode = float2(1.0,0.75);
	}
	else
	{
		CC_Mode = float2(0.75,0.5);
	}
	
	float4 Mpointer = all(abs(texcoord - MousecoordsXY) < CC_Size*CC_Mode) * (1 - all(abs(texcoord - MousecoordsXY) > CC_Size/(Cross_Cursor_Adjust.a*float2(0.5,1.0)))) ? float4(Cross_Cursor_Adjust.rgb/255, 1.0) : tex2D(BackBuffer, texcoord);//cross
	
	return Mpointer;
}

/////////////////////////////////////////////////////////////////////////////////Adapted Luminance/////////////////////////////////////////////////////////////////////////////////
texture texLum {Width = 256*0.5; Height = 256*0.5; Format = RGBA8; MipLevels = 8;}; //Sample at 256x256/2 and a mip bias of 8 should be 1x1 
																				
sampler SamplerLum																
	{
		Texture = texLum;
		MipLODBias = 8.0f; //Luminance adapted luminance value from 1x1 Texture Mip lvl of 8
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};
	
texture texLumWeapon {Width = 256*0.5; Height = 256*0.5; Format = RGBA8; MipLevels = 8;}; //Sample at 256x256*0.5 and a mip bias of 8 should be 1x1 
																				
sampler SamplerLumWeapon																
	{
		Texture = texLumWeapon;
		MipLODBias = 8.0f; //Luminance adapted luminance value from 1x1 Texture Mip lvl of 8
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};	
	
float Lum(in float2 texcoord : TEXCOORD0)
	{
		float Luminance = tex2Dlod(SamplerLum,float4(texcoord,0,0)).r; //Average Luminance Texture Sample 

		return Luminance;
	}
	
float LumWeapon(in float2 texcoord : TEXCOORD0)
	{
		float Luminance = tex2Dlod(SamplerLumWeapon,float4(texcoord,0,0)).r; //Average Luminance Texture Sample 

		return Luminance;
	}
	
/////////////////////////////////////////////////////////////////////////////////Depth Map Information/////////////////////////////////////////////////////////////////////////////////

float Depth(in float2 texcoord : TEXCOORD0)
{	
		float2 texXY = texcoord + Image_Position_Adjust * pix;		
		float2 midHV = (Horizontal_and_Vertical-1) * float2(BUFFER_WIDTH * 0.5,BUFFER_HEIGHT * 0.5) * pix;			
		texcoord = float2((texXY.x*Horizontal_and_Vertical.x)-midHV.x,(texXY.y*Horizontal_and_Vertical.y)-midHV.y);	
		
		if (Depth_Map_Flip)
			texcoord.y =  1 - texcoord.y;
			
		float zBuffer = tex2D(DepthBuffer, texcoord).r; //Depth Buffer

		//Conversions to linear space.....
		//Near & Far Adjustment
		float Near = 0.125/Depth_Map_Adjust; //Division Depth Map Adjust - Near
		float Far = 1; //Far Adjustment

		//Raw Z Offset
		float Z = min(1,pow(abs(exp(zBuffer)*Offsets),2));
		float ZR = min(1,pow(abs(exp(zBuffer)*Offsets),50));
		
		//0. Normal
		float Normal = Far * Near / (Far + zBuffer * (Near - Far));
		
		//1. Reverse
		float NormalReverse = Far * Near / (Near + zBuffer * (Far - Near));
		
		//2. Offset Normal
		float OffsetNormal = Far * Near / (Far + Z * (Near - Far));
			  OffsetNormal = lerp(Normal,OffsetNormal,0.875);//mixing
			  
		//3. Offset Reverse
		float OffsetReverse = Far * Near / (Near + ZR * (Far - Near));
			  OffsetReverse = lerp(Normal,OffsetReverse,0.875);//mixing

		float DM;
		
		if (Depth_Map == 0)
		{
		DM = Normal;
		}		
		else if (Depth_Map == 1)
		{
		DM = NormalReverse;
		}
		else if (Depth_Map == 2)
		{
		DM = OffsetNormal;
		}
		else
		{
		DM = OffsetReverse;
		}
		
	return DM;	
}

float2 WeaponDepth(in float2 texcoord : TEXCOORD0)
{
		float2 texXY = texcoord + Image_Position_Adjust * pix;		
		float2 midHV = (Horizontal_and_Vertical-1) * float2(BUFFER_WIDTH * 0.5,BUFFER_HEIGHT * 0.5) * pix;			
		texcoord = float2((texXY.x*Horizontal_and_Vertical.x)-midHV.x,(texXY.y*Horizontal_and_Vertical.y)-midHV.y);	
			
			if (Depth_Map_Flip)
			texcoord.y =  1 - texcoord.y;
			
		float zBufferWH = tex2D(DepthBuffer, texcoord).r; //Weapon Hand Depth Buffer
		//Weapon Depth Map
		//FPS Hand Depth Maps require more precision at smaller scales to work
		float constantF = 1.0;	
		float constantN = 0.01;
		
		zBufferWH = constantF * constantN / (constantF + zBufferWH * (constantN - constantF));
 		
		//Set Weapon Depth Map settings for the section below.//
		float WA_X; //Weapon_Adjust.x
		float WA_Y; //Weapon_Adjust.y
		float CoP; //Weapon_Adjust.z
		
		if (WP == 1)
		{
			WA_X = Weapon_Adjust.x;
			WA_Y = Weapon_Adjust.y;
		}
		
		//WP 0 ; Unreal Gold with v227
		else if(WP == 2)
		{
			WA_X = 2.855;
			WA_Y = 0.1375;
			CoP = 0.335;
		}
		
		//WP 1 ; DOOM 2016
		else if(WP == 3)
		{
			WA_X = 2.775;
			WA_Y = 0.666;
			CoP = 0.2775;
		}
		
		//WP 2 ; Amnesia Games
		else if(WP == 4)
		{
			WA_X = 100.0;
			WA_Y = 75.0;
			CoP = 8.0;
		}
		
		//WP 3 ; BorderLands 2
		else if(WP == 5)
		{
			WA_X = 2.855;
			WA_Y = 1.0;
			CoP = 0.300;
		}
		
		//WP 4 ; CoD:AW
		else if(WP == 6)
		{
			WA_X = 98.0;
			WA_Y = -0.3625;
			CoP = 0.300;
		}
		
		//WP 5 ; CoD: Black Ops
		else if(WP == 7)
		{
			WA_X = 2.53945;
			WA_Y = 0.0125;
			CoP = 0.300;
		}
		
		//WP 6 ; CoD: Black Ops
		else if(WP == 8)
		{
			WA_X = 5.0;
			WA_Y = 15.625;
			CoP = 0.455;
		}
		
		//WP 7 ; Wolfenstine: The New Order
		else if(WP == 9)
		{
			WA_X = 5.500;
			WA_Y = 1.550;
			CoP = 0.550;
		}
		
		//WP 8 ; Fallout 4
		else if(WP == 10)
		{
			WA_X = 2.5275;
			WA_Y = 0.0875;
			CoP = 0.255;
		}
		
		//WP 9 ; Prey 2017 High and <
		else if(WP == 11)
		{
			WA_X = 19.700;
			WA_Y = -2.600;
			CoP = 0.285;
		}

		//WP 10 ; Prey 2017 Very High
		else if(WP == 12)
		{
			WA_X = 28.450;
			WA_Y = -2.600;
			CoP = 0.285;
		}
		
		//WP 11 ; Metro Redux Games
		else if(WP == 13)
		{
			WA_X = 2.61375;
			WA_Y = 1.0;
			CoP = 0.260;
		}
		
		//WP 12 ; NecroVisioN: Lost Company
		else if(WP == 14)
		{
			WA_X = 5.1375;
			WA_Y = 7.5;
			CoP = 0.485;
		}
		
		//WP 13 ; Kingpin Life of Crime
		else if(WP == 15)
		{
			WA_X = 3.925;
			WA_Y = 17.5;
			CoP = 0.400;
		}
	
		//WP 14 ; Rage64
		else if(WP == 16)
		{
			WA_X = 5.45;
			WA_Y = 1.0;
			CoP = 0.550;
		}	
		
		//WP 15 ; Quake DarkPlaces
		else if(WP == 17)
		{
			WA_X = 2.685;
			WA_Y = 1.0;
			CoP = 0.375;
		}	

		//WP 16 ; Quake 2 XP
		else if(WP == 18)
		{
			WA_X = 3.925;
			WA_Y = 16.25;
			CoP = 0.400;
		}
		
		//WP 17 ; Quake 4
		else if(WP == 19)
		{
			WA_X = 5.000000;
			WA_Y = 7.0;
			CoP = 0.500;
		}

		//WP 18 ; RTCW
		else if(WP == 20)
		{
			WA_X = 3.6875;
			WA_Y = 7.250;
			CoP = 0.400;
		}
	
		//WP 19 ; S.T.A.L.K.E.R: Games
		else if(WP == 21)
		{
			WA_X = 2.55925;
			WA_Y = 0.75;
			CoP = 0.255;
		}
		
		//WP 20 ; Soma
		else if(WP == 22)
		{
			WA_X = 16.250;
			WA_Y = 87.50;
			CoP = 0.825;
		}
		
		//WP 21 ; Skyrim: SE
		else if(WP == 23)
		{
			WA_X = 2.775;
			WA_Y = 1.125;
			CoP = 0.278;
		}
		
		//WP 22 ; Turok: DH 2017
		else if(WP == 24)
		{
			WA_X = 2.553125;
			WA_Y = 1.0;
			CoP = 0.500;
		}

		//WP 23 ; Turok2: SoE 2017
		else if(WP == 25)
		{
			WA_X = 140.0;
			WA_Y = 500.0;
			CoP = 5.0;
		}
		
		//WP 24 ; Dying Light
		else if(WP == 26)
		{
			WA_X = 2.000;
			WA_Y = -40.0;
			CoP = 2.0;
		}
		
		//WP 25 ; EuroTruckSim2
		else if(WP == 27)
		{
			WA_X = 2.800;
			WA_Y = 1.0;
			CoP = 0.280;
		}
		
		//WP 26 ; Prey - 2006
		else if(WP == 28)
		{
			WA_X = 5.000;
			WA_Y = 2.875;
			CoP = 0.500;
		}
		
		//WP 27 ; TitanFall 2
		else if(WP == 29)
		{
			WA_X = 2.77575;
			WA_Y = 0.3625;
			CoP = 0.3625;
		}
		
		//WP 28 ; Bioshock Remastred
		else if(WP == 30)
		{
			WA_X = 2.52475;
			WA_Y = 0.05625;
			CoP = 0.260;
		}
								
		//SWDMS Done//
 		
 		//TEXT MODE 31 Adjust
		else if(WP == 33) //Text mode one.
		{
			WA_X = Weapon_Adjust.x;
			WA_Y = 100;
			CoP = 0.252;
		}
 		
		//Scaled Section z-Buffer
		
		if(WP >= 1)
		{
			WA_X *= 0.004;
			WA_Y *= 0.004;
			zBufferWH = WA_Y*zBufferWH/(WA_X-zBufferWH);
		
			if(WP == 24)
			zBufferWH += 1;
		}
		
		float Adj = Weapon_Adjust.w*0.00266666; //Push & pull weapon in or out of screen. Weapon_Depth Adjustment
		zBufferWH = smoothstep(Adj,1,zBufferWH) ;//Weapon Adjust smoothstep range from Adj-1
		
		//Auto Anti Weapon Depth Map Z-Fighting is always on.
		
		float WeaponLumAdjust = abs(smoothstep(0,0.5,LumWeapon(texcoord)*2.5)) * zBufferWH;	
			
		if( WP == 1 || WP == 22 || WP == 24 || WP == 27 || WP == 33 )//WP Adjust,SOMA, EuroTruckSim2, and HUD mode.
		{
			zBufferWH = zBufferWH;
		}
		else
		{
			zBufferWH = lerp(saturate(WeaponLumAdjust),zBufferWH,0.025);
		}
		
		if(Weapon_Adjust.z <= 0) //Zero Is auto
		{
			CoP = CoP;
		}
		else	
		{
			CoP = Weapon_Adjust.z;
		}
		
	return float2(saturate(zBufferWH.r),CoP);	
}

void DepthMap(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 Color : SV_Target0)
{
		float N, R, G, B, D, LDM, RDM, Cutoff, A = 1;
		
		float2 DM = Depth(texcoord);
		
		float WD = lerp(WeaponDepth(texcoord).x,1,0.0175);
		
		float CoP = WeaponDepth(texcoord).y; //Weapon Cutoff Point
				
		float CutOFFCal = (CoP/Depth_Map_Adjust)/2; //Weapon Cutoff Calculation
		
		Cutoff = step(lerp(DM.x,DM.y,0.5),CutOFFCal);
				
		if (WP == 0)
		{
			LDM = DM.x;
			RDM = DM.y;
		}
		else
		{
			LDM = lerp(DM.x,WD,Cutoff);
			RDM = lerp(DM.y,WD,Cutoff);
		}
		
		R = LDM;
		G = Depth(texcoord); //AverageLuminance
		B = RDM;
		
	Color = float4(R,G,B,A);
}

#if AO_TOGGLE
//3D AO START//
float AO_Depth(float2 coords)
{
	float DM = tex2Dlod(SamplerDM,float4(coords.xy,0,0)).r;
	return ( DM - 0 ) / ( AO_Control - 0);
}

float3 GetPosition(float2 coords)
{
	float3 DM = -AO_Depth(coords).xxx;
	return float3(coords.xy*2.0-1.0,1.0)*DM;
}

float2 GetRandom(float2 co)
{
	float random = frac(sin(dot(co, float2(12.9898, 78.233))) * 43758.5453 * 1);
	return float2(random,random);
}

float3 normal_from_depth(float2 texcoords) 
{
	float depth;
	const float2 offset1 = float2(10,pix.y);
	const float2 offset2 = float2(pix.x,10);
	  
	float depth1 = AO_Depth(texcoords + offset1).x;
	float depth2 = AO_Depth(texcoords + offset2).x;
	  
	float3 p1 = float3(offset1, depth1 - depth);
	float3 p2 = float3(offset2, depth2 - depth);
	  
	float3 normal = cross(p1, p2);
	normal.z = -normal.z;
	  
	return normalize(normal);
}

//Ambient Occlusion form factor
float aoFF(in float3 ddiff,in float3 cnorm, in float c1, in float c2)
{
	float3 vv = normalize(ddiff);
	float rd = length(ddiff);
	return (clamp(dot(normal_from_depth(float2(c1,c2)),-vv),-1,1.0)) * (1.0 - 1.0/sqrt(-0.001/(rd*rd) + 1000));
}

float4 GetAO( float2 texcoord )
{ 
    //current normal , position and random static texture.
    float3 normal = normal_from_depth(texcoord);
    float3 position = GetPosition(texcoord);
	float2 random = GetRandom(texcoord).xy;
    
    //initialize variables:
    float F = 0.750;
	float iter = 2.5*pix.x;
    float aout, num = 8;
    float incx = F*pix.x;
    float incy = F*pix.y;
    float width = incx;
    float height = incy;
    
    //Depth Map
    float depthM = AO_Depth(texcoord).x;
    	
	//2 iterations
	[loop]
    for(int i = 0; i<2; ++i) 
    {
       float npw = (width+iter*random.x)/depthM;
       float nph = (height+iter*random.y)/depthM;
       
		if(AO == 1)
		{
			float3 ddiff = GetPosition(texcoord.xy+float2(npw,nph))-position;
			float3 ddiff2 = GetPosition(texcoord.xy+float2(npw,-nph))-position;
			float3 ddiff3 = GetPosition(texcoord.xy+float2(-npw,nph))-position;
			float3 ddiff4 = GetPosition(texcoord.xy+float2(-npw,-nph))-position;

			aout += aoFF(ddiff,normal,npw,nph);
			aout += aoFF(ddiff2,normal,npw,-nph);
			aout += aoFF(ddiff3,normal,-npw,nph);
			aout += aoFF(ddiff4,normal,-npw,-nph);
		}
		
		//increase sampling area
		   width += incx;  
		   height += incy;	    
    } 
    aout/=num;

	//Luminance adjust used for overbright correction.
	float4 Done = min(1.0,aout);
	float OBC =  dot(Done.rgb,float3(0.2627, 0.6780, 0.0593)* 2);
	return smoothstep(0,1,float4(OBC,OBC,OBC,1));
}

void AO_in(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target0 )
{
	color = GetAO(texcoord);
}

//AO END//
#endif

float AutoDepthRange( float d, float2 texcoord )
{
	float LumAdjust = smoothstep(-0.0175,Auto_Depth_Range,Lum(texcoord));
    return min(1,( d - 0 ) / ( LumAdjust - 0));
}

float Conv(float D,float2 texcoord)
{
	float Z, ZP, Con = ZPD, NF_Power, MSZ, MS_A = Divergence * pix.x, MS_B = (ZPD*1000) * pix.x;

		float Divergence_Locked = Divergence*0.001;
		float ALC = abs(smoothstep(0,1.0,Lum(texcoord)));
		
			if(TPAuto_ZPD == 1)
			{
				if (ALC < 0.0078125)
				{
					Con = ZPD*2.0;
				}	
				if (ALC > 0.0078125)
				{
					Con = ZPD*1.750;
				}
				if (ALC > 0.015625)
				{
					Con = ZPD*1.625;
				}
				if (ALC > 0.03125)
				{
					Con = ZPD*1.5;
				}
				if (ALC > 0.03125)
				{
					Con = ZPD*1.375;
				}
				if (ALC > 0.0625)
				{
					Con = ZPD*1.250;
				}
				if (ALC > 0.125)
				{
					Con = ZPD;
				}
			}
			else
			{
				Con = ZPD;
			}
			
		if (ALC <= 0.00005 && FBDMF) //Full Black Depth Map Fix.
		{
			Z = 0;
			Divergence_Locked = 0;
		}
		else
		{
			Z = Con;
			Divergence_Locked = Divergence_Locked;
		}	

		if(Balance == -4)
		{
			NF_Power = 0.125;
		}		
		if(Balance == -3)
		{
			NF_Power = 0.250;
		}
		if(Balance == -2)
		{
			NF_Power = 0.375;
		}
		else if(Balance == -1)
		{
			NF_Power = 0.425;
		}
		else if(Balance == 0)
		{
			NF_Power = 0.5;
		}
		else if(Balance == 1)
		{
			NF_Power = 0.5625;
		}
		else if(Balance == 2)
		{
			NF_Power = 0.625;
		}
		else if(Balance == 3)
		{
			NF_Power = 0.6875;
		}
		else if(Balance == 4)
		{
			NF_Power = 0.75;
		}
		else if(Balance == 5)
		{
			NF_Power = 0.8125;
		}
		else if(Balance == 6)
		{
			NF_Power = 0.875;
		}
		
		if(ZPD == 0)
		{
			ZP = 1.0;
		}
		else
		{
			ZP = NF_Power;
		}
		
		float Convergence;		
		
		if(Convergence_Mode == 1)
		{
			MSZ = MS_A; //Locked ZPD easy for new people less settings.
			Convergence = 1 - Divergence_Locked / D;
		}
		else if(Convergence_Mode == 2)
		{
			MSZ = MS_B; //Unhooked ZDP for Advance Users.
			Convergence = 1 - Z / D;
		}
		else
		{	
			MSZ = MS_A; //Tied ZDP AKA Original Way, Mix of both 0 & 1.
			Convergence = 1 - Z / D;
		}
		
		if (Auto_Depth_Range > 0)
		{
			D = AutoDepthRange(D,texcoord);
		}
		
		Z = lerp(MSZ * Convergence,MS_A * D,ZP);
			
    return Z;
}

void  Disocclusion(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target0)
{
float X, Y, A, B, DP =  Divergence, Disocclusion_PowerA, Disocclusion_PowerB , DBD = tex2Dlod(SamplerDM,float4(texcoord,0,0)).r , AMoffset = 0.008, BMoffset = 0.00285714, CMoffset = 0.09090909;
float2 DM, DMA, DMB, dirA, dirB;

#if AO_TOGGLE
float blursize = 2.0*pix.x,sum;
if(AO == 1)
	{
		sum += tex2Dlod(SamplerAO, float4(texcoord.x - 4.0*blursize, texcoord.y,0,0)).x * 0.05;
		sum += tex2Dlod(SamplerAO, float4(texcoord.x, texcoord.y - 3.0*blursize,0,0)).x * 0.09;
		sum += tex2Dlod(SamplerAO, float4(texcoord.x - 2.0*blursize, texcoord.y,0,0)).x * 0.12;
		sum += tex2Dlod(SamplerAO, float4(texcoord.x, texcoord.y - blursize,0,0)).x * 0.15;
		sum += tex2Dlod(SamplerAO, float4(texcoord.x + blursize, texcoord.y,0,0)).x * 0.15;
		sum += tex2Dlod(SamplerAO, float4(texcoord.x, texcoord.y + 2.0*blursize,0,0)).x * 0.12;
		sum += tex2Dlod(SamplerAO, float4(texcoord.x + 3.0*blursize, texcoord.y,0,0)).x * 0.09;
		sum += tex2Dlod(SamplerAO, float4(texcoord.x, texcoord.y + 4.0*blursize,0,0)).x * 0.05;
	}
#endif

//DBD Adjustment Start
DBD = (DBD - 0.025)/(1 - 0.025); 
DBD = DBD*DBD*(3 - 2*DBD);
DBD = ( DBD - 1.0f ) / ( -187.5f - 1.0f );
//DBD Adjustment End

	DP *= Disocclusion_Power_Adjust;
		
	if ( Disocclusion_Selection == 1 || Disocclusion_Selection == 4 ) // Radial    
	{
		Disocclusion_PowerA = DP*AMoffset;
	}
	else if ( Disocclusion_Selection == 2 || Disocclusion_Selection == 5 ) // Normal  
	{
		Disocclusion_PowerA = DP*BMoffset;
	}
	else if ( Disocclusion_Selection == 3 ) // Depth    
	{
		Disocclusion_PowerA = DBD*DP;
	}
		
	// Mix Depth Start	
	if ( Disocclusion_Selection == 4 || Disocclusion_Selection == 5 ) //Depth    
	{
		Disocclusion_PowerB = DBD*DP;
	}
	// Mix Depth End
	
	if (Disocclusion_Selection >= 1) 
	{
		const float weight[11] = {0.0,0.010,-0.010,0.020,-0.020,0.030,-0.030,0.040,-0.040,0.050,-0.050}; //By 10
		
		if( Disocclusion_Selection == 1)
		{
			dirA = 0.5 - texcoord;
			dirB = 0.5 - texcoord;
			A = Disocclusion_PowerA;
			B = Disocclusion_PowerB;
		}
		else if ( Disocclusion_Selection == 2 || Disocclusion_Selection == 3 || Disocclusion_Selection == 5)
		{
			dirA = float2(0.5,0.0);
			dirB = float2(0.5,0.0);
			A = Disocclusion_PowerA;
			B = Disocclusion_PowerB;
		}
		else if(Disocclusion_Selection == 4)
		{
			dirA = 0.5 - texcoord;
			dirB = float2(0.5,0.0);
			A = Disocclusion_PowerA;
			B = Disocclusion_PowerB;
		}
		
		if ( Disocclusion_Selection >= 1 )
		{			
				[loop]
				for (int i = 0; i < 11; i++)
				{	
					DM += tex2Dlod(SamplerDM,float4(texcoord + dirA * weight[i] * A,0,0)).rb*CMoffset;
					
					if(Disocclusion_Selection == 4 || Disocclusion_Selection == 5)
					{
						DMA += tex2Dlod(SamplerDM,float4(texcoord + dirB * weight[i] * B,0,0)).rb*CMoffset;
					}
				}
		}
		
		if ( Disocclusion_Selection == 4 || Disocclusion_Selection == 5)
		{	
			DM = lerp(DM,DMA,0.5);
		}
	}
	else
	{
		DM = tex2Dlod(SamplerDM,float4(texcoord,0,0)).rb;
	}

	if (!Cancel_Depth)
	{	
		#if AO_TOGGLE
		if(AO == 1)
		{
			X =lerp(DM.x,DM.x+sum,AO_Power);
			Y =lerp(DM.y,DM.x+sum,AO_Power);
		}
		else
		{
			X = DM.x;
			Y = DM.y;
		}
		#else
			X = DM.x;
			Y = DM.y;
		#endif	
	}
	else
	{
		X = 0.5;
		Y = 0.5;
	}
		
	color = float4(X,DM.x,Y,1);
}

/////////////////////////////////////////L/R//////////////////////////////////////////////////////////////////////
float4 PS_calcLR(float2 texcoord)
{
	float2 TCL, TCR, TexCoords = texcoord;
	float4 color, Right, Left, cR, cL;
	float DepthR = 1, DepthL = 1, Adjust_A = 0.11111111, Adjust_B = 0.07692307, Adjust_C = 0.05882352, N, S, L, R;
	float samplesA[5] = {0.5,0.625,0.75,0.875,1.0};
	float samplesB[9] = {0.5,0.5625,0.625,0.6875,0.75,0.8125,0.875,0.9375,1.0};
	float samplesC[13] = {0.5,0.546875,0.578125,0.625,0.659375,0.703125,0.75,0.796875,0.828125,0.875,0.921875,0.953125,1.0};
	float samplesD[17] = {0.5,0.53125,0.5625,0.59375,0.625,0.63125,0.6875,0.71875,0.75,0.78125,0.8125,0.84375,0.875,0.90625,0.9375,0.96875,1.0};
	
	//MS is Max Separation P is Perspective Adjustment
	float MS = Divergence * pix.x, P = Perspective * pix.x;
					
		if(Eye_Swap)
		{
			if ( Stereoscopic_Mode == 0 )
			{
				TCL.x = (texcoord.x*2-1) - P;
				TCR.x = (texcoord.x*2) + P;
				TCL.y = texcoord.y;
				TCR.y = texcoord.y;
			}
			else if( Stereoscopic_Mode == 1 )
			{
				TCL.x = texcoord.x - P;
				TCR.x = texcoord.x + P;
				TCL.y = (texcoord.y*2-1);
				TCR.y = (texcoord.y*2);
			}
			else
			{
				TCL.x = texcoord.x - P;
				TCR.x = texcoord.x + P;
				TCL.y = texcoord.y;
				TCR.y = texcoord.y;
			}
		}	
		else
		{
			if (Stereoscopic_Mode == 0)
			{
				TCR.x = (texcoord.x*2-1) - P;
				TCL.x = (texcoord.x*2) + P;
				TCR.y = texcoord.y;
				TCL.y = texcoord.y;
			}
			else if(Stereoscopic_Mode == 1)
			{
				TCR.x = texcoord.x - P;
				TCL.x = texcoord.x + P;
				TCR.y = (texcoord.y*2-1);
				TCL.y = (texcoord.y*2);
			}
			else
			{
				TCR.x = texcoord.x - P;
				TCL.x = texcoord.x + P;
				TCR.y = texcoord.y;
				TCL.y = texcoord.y;
			}
		}
		//Optimization for line & column interlaced out.
		if (Stereoscopic_Mode == 2)
		{
			TCL.y = TCL.y + (Interlace_Optimization * pix.y);
			TCR.y = TCR.y - (Interlace_Optimization * pix.y);
		}
		else if (Stereoscopic_Mode == 3)
		{
			TCL.x = TCL.x + (Interlace_Optimization * pix.x);
			TCR.x = TCR.x - (Interlace_Optimization * pix.x);
		}
			
		if (View_Mode == 0)
			N = 5;
		else if (View_Mode == 1)
			N = 9;
		else if (View_Mode == 2)
			N = 13;
		else if (View_Mode == 3)
			N = 17;
				
		[loop]
		for ( int i = 0 ; i < N; i++ ) 
		{
			if (View_Mode == 0)
			{
				S = samplesA[i] * MS;
				DepthL = min(DepthL,tex2Dlod(SamplerDis,float4(TCL.x+S, TCL.y,0,0)).r);
				DepthR = min(DepthR,tex2Dlod(SamplerDis,float4(TCR.x-S, TCR.y,0,0)).b);
			}
			else if (View_Mode == 1)
			{
				S = samplesB[i] * MS * 1.125;
				L += tex2Dlod(SamplerDis,float4(TCL.x+S, TCL.y,0,0)).r*Adjust_A;
				R += tex2Dlod(SamplerDis,float4(TCR.x-S, TCR.y,0,0)).b*Adjust_A;
				DepthL = saturate(L);
				DepthR = saturate(R);
			}
			else if (View_Mode == 2)
			{
				S = samplesC[i] * MS * 1.125;
				L += tex2Dlod(SamplerDis,float4(TCL.x+S, TCL.y,0,0)).r*Adjust_B;
				R += tex2Dlod(SamplerDis,float4(TCR.x-S, TCR.y,0,0)).b*Adjust_B;
				DepthL = saturate(L);
				DepthR = saturate(R);
			}
			else if (View_Mode == 3)
			{
				S = samplesD[i] * MS * 1.125;
				L += tex2Dlod(SamplerDis,float4(TCL.x+S, TCL.y,0,0)).r*Adjust_C;
				R += tex2Dlod(SamplerDis,float4(TCR.x-S, TCR.y,0,0)).b*Adjust_C;
				DepthL = saturate(L);
				DepthR = saturate(R);
			}
		}
		
			DepthR = Conv(DepthR,TexCoords);//Zero Parallax Distance Pass
			DepthL = Conv(DepthL,TexCoords);//Zero Parallax Distance Pass
			
		float ReprojectionRight = DepthR;
		float ReprojectionLeft =  DepthL;

			if(Custom_Sidebars == 0)
			{
				Left = tex2Dlod(BackBufferMIRROR, float4(TCL.x + ReprojectionLeft, TCL.y,0,0));
				Right = tex2Dlod(BackBufferMIRROR, float4(TCR.x - ReprojectionRight, TCR.y,0,0));
			}
			else if(Custom_Sidebars == 1)
			{
				Left = tex2Dlod(BackBufferBORDER, float4(TCL.x + ReprojectionLeft, TCL.y,0,0));
				Right = tex2Dlod(BackBufferBORDER, float4(TCR.x - ReprojectionRight, TCR.y,0,0));
			}
			else
			{
				Left = tex2Dlod(BackBufferCLAMP, float4(TCL.x + ReprojectionLeft, TCL.y,0,0));
				Right = tex2Dlod(BackBufferCLAMP, float4(TCR.x - ReprojectionRight, TCR.y,0,0));
			}

	
			if ( Eye_Swap )
			{
				cL = Right;
				cR = Left;	
			}
			else
			{
				cL = Left;
				cR = Right;
			}
			
	if(!Depth_Map_View)
	{	
	float2 gridxy;

	if(Scaling_Support == 0)
	{
		gridxy = floor(float2(TexCoords.x*3840.0,TexCoords.y*2160.0));
	}	
	else if(Scaling_Support == 1)
	{
		gridxy = floor(float2(TexCoords.x*BUFFER_WIDTH,TexCoords.y*BUFFER_HEIGHT));
	}
	else if(Scaling_Support == 2)
	{
		gridxy = floor(float2(TexCoords.x*1920.0,TexCoords.y*1080.0));
	}
	else if(Scaling_Support == 3)
	{
		gridxy = floor(float2(TexCoords.x*1921.0,TexCoords.y*1081.0));
	}
	else if(Scaling_Support == 4)
	{
		gridxy = floor(float2(TexCoords.x*1680.0,TexCoords.y*1050.0));
	}
	else if(Scaling_Support == 5)
	{
		gridxy = floor(float2(TexCoords.x*1681.0,TexCoords.y*1051.0));
	}
	else if(Scaling_Support == 6)
	{
		gridxy = floor(float2(TexCoords.x*1280.0,TexCoords.y*720.0));
	}
	else if(Scaling_Support == 7)
	{
		gridxy = floor(float2(TexCoords.x*1281.0,TexCoords.y*721.0));
	}
			
		if(Stereoscopic_Mode == 0)
		{	
			color = TexCoords.x < 0.5 ? cL : cR;
		}
		else if(Stereoscopic_Mode == 1)
		{	
			color = TexCoords.y < 0.5 ? cL : cR;
		}
		else if(Stereoscopic_Mode == 2)
		{
			color = int(gridxy.y) & 1 ? cR : cL;	
		}
		else if(Stereoscopic_Mode == 3)
		{
			color = int(gridxy.x) & 1 ? cR : cL;		
		}
		else if(Stereoscopic_Mode == 4)
		{
			color = int(gridxy.x+gridxy.y) & 1 ? cR : cL;
		}
		else if(Stereoscopic_Mode == 5)
		{													
				float3 HalfLA = dot(cL.rgb,float3(0.299, 0.587, 0.114));
				float3 HalfRA = dot(cR.rgb,float3(0.299, 0.587, 0.114));
				float3 LMA = lerp(HalfLA,cL.rgb,Anaglyph_Desaturation);  
				float3 RMA = lerp(HalfRA,cR.rgb,Anaglyph_Desaturation); 
				
				float4 cA = float4(LMA,1);
				float4 cB = float4(RMA,1);
	
			if (Anaglyph_Colors == 0)
			{
				float4 LeftEyecolor = float4(1.0,0.0,0.0,1.0);
				float4 RightEyecolor = float4(0.0,1.0,1.0,1.0);
				
				color =  (cA*LeftEyecolor) + (cB*RightEyecolor);
			}
			else if (Anaglyph_Colors == 1)
			{
			float red = 0.437 * cA.r + 0.449 * cA.g + 0.164 * cA.b
					- 0.011 * cB.r - 0.032 * cB.g - 0.007 * cB.b;
			
			if (red > 1) { red = 1; }   if (red < 0) { red = 0; }

			float green = -0.062 * cA.r -0.062 * cA.g -0.024 * cA.b 
						+ 0.377 * cB.r + 0.761 * cB.g + 0.009 * cB.b;
			
			if (green > 1) { green = 1; }   if (green < 0) { green = 0; }

			float blue = -0.048 * cA.r - 0.050 * cA.g - 0.017 * cA.b 
						-0.026 * cB.r -0.093 * cB.g + 1.234  * cB.b;
			
			if (blue > 1) { blue = 1; }   if (blue < 0) { blue = 0; }

			color = float4(red, green, blue, 0);
			}
			else if (Anaglyph_Colors == 2)
			{
				float4 LeftEyecolor = float4(0.0,1.0,0.0,1.0);
				float4 RightEyecolor = float4(1.0,0.0,1.0,1.0);
				
				color =  (cA*LeftEyecolor) + (cB*RightEyecolor);			
			}
			else
			{
								
			float red = -0.062 * cA.r -0.158 * cA.g -0.039 * cA.b
					+ 0.529 * cB.r + 0.705 * cB.g + 0.024 * cB.b;
			
			if (red > 1) { red = 1; }   if (red < 0) { red = 0; }

			float green = 0.284 * cA.r + 0.668 * cA.g + 0.143 * cA.b 
						- 0.016 * cB.r - 0.015 * cB.g + 0.065 * cB.b;
			
			if (green > 1) { green = 1; }   if (green < 0) { green = 0; }

			float blue = -0.015 * cA.r -0.027 * cA.g + 0.021 * cA.b 
						+ 0.009 * cB.r + 0.075 * cB.g + 0.937  * cB.b;
			
			if (blue > 1) { blue = 1; }   if (blue < 0) { blue = 0; }
					
			color = float4(red, green, blue, 0);
			}
		}
	}
		else
	{		
			float4 Top = TexCoords.x < 0.5 ? Lum(float2(TexCoords.x*2,TexCoords.y*2)).xxxx : tex2Dlod(SamplerDM,float4(TexCoords.x*2-1 , TexCoords.y*2,0,0)).rrbb;
			float4 Bottom = TexCoords.x < 0.5 ?  AutoDepthRange(tex2Dlod(SamplerDM,float4(TexCoords.x*2 , TexCoords.y*2-1,0,0)).r,TexCoords) : tex2Dlod(SamplerDis,float4(TexCoords.x*2-1,TexCoords.y*2-1,0,0)).rrrr;
			color = TexCoords.y < 0.5 ? Top : Bottom;
	}
	float Average_Lum = TexCoords.y < 0.5 ? 0.5 : tex2D(SamplerDM,float2(TexCoords.x,TexCoords.y)).g;
	return float4(color.rgb,Average_Lum);
}

float4 Average_Luminance(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 Average_Lum = tex2D(SamplerDM,float2(texcoord.x,texcoord.y)).ggg;
	return float4(Average_Lum,1);
}

float4 Average_Luminance_Weapon(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 Average_Lum_Weapon = PS_calcLR(float2(texcoord.x,(texcoord.y + 0.500) * 0.500 + 0.250)).www;
	return float4(Average_Lum_Weapon,1);
}

////////////////////////////////////////////////////////Logo/////////////////////////////////////////////////////////////////////////
uniform float timer < source = "timer"; >;
float4 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float PosX = 0.5*BUFFER_WIDTH*pix.x,PosY = 0.5*BUFFER_HEIGHT*pix.y;	
	float4 Color = float4(PS_calcLR(texcoord).rgb,1),Done,Website,D,E,P,T,H,Three,DD,Dot,I,N,F,O;
	
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

technique Cross_Cursor
{			
			pass Cursor
		{
			VertexShader = PostProcessVS;
			PixelShader = MouseCursor;
		}	
}

technique SuperDepth3D
	{
			pass zbuffer
		{
			VertexShader = PostProcessVS;
			PixelShader = DepthMap;
			RenderTarget = texDM;
		}
		#if AO_TOGGLE
			pass AmbientOcclusion
		{
			VertexShader = PostProcessVS;
			PixelShader = AO_in;
			RenderTarget = texAO;
		}
		#endif
			pass Disocclusion
		{
			VertexShader = PostProcessVS;
			PixelShader = Disocclusion;
			RenderTarget = texDis;
		}
			pass AverageLuminance
		{
			VertexShader = PostProcessVS;
			PixelShader = Average_Luminance;
			RenderTarget = texLum;
		}
			pass AverageLuminanceWeapon
		{
			VertexShader = PostProcessVS;
			PixelShader = Average_Luminance_Weapon;
			RenderTarget = texLumWeapon;
		}
			pass StereoOut
		{
			VertexShader = PostProcessVS;
			PixelShader = Out;
		}
	}