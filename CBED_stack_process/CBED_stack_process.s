//*****************!!!!!!!!!!!!!!!!!!
// Serhii Kryvyi
// CBED stack process v1.2
// version:19.6_mod
// Test version!!! Contains ERRORS!!!
// Without optimization only calculation!!!
//
//*****************!!!!!!!!!!!!!!!!!!
// This should work on 3D images
//
// For stop calculating process Hold down SHIFT and SPACE.
//
// CBED stack process uses cross correlation and can be done on the raw images or the images after Sobel (edge enhancing)
// filtering has been applied. Applying a Butterworth (B'worth) filter emphasises regions in the image centre and reduces
// the effect of edges and features near the edge. Use the cross correlation values as a guide to what is working well.
// The cross correlation is done to sub-pixel accuracy using a centre of gravity approach on the cross correlation image.
// Cross correlation can be led astray if highly symmetric features dominate the image (eg a linear interface).
// The cross correlation can be made for reference ideal diffraction disk (radius of ideal diffraction disk eqval value Disk radius in box CBED parameters)
// or reference experimental diffraction disk using ROI (Exp.Ref.Disk) and Reference slise (in box ROI).
// In case Exp.Ref.Disk not pressed will be used ideal diffraction disk approach.
//
// !!!Reconstructed image.
// First of all need define X and Y size of reconstructed image.
// X*Y=total Slice number. Remember Slice numbered from 0!!!
//
// !!!CBED parameters
// The Disk radius need to work of filters and amplitude calculations
// Max shift restricts value of diffraction disk shift.
// If shift is to big, pix value on reconstructed image will be 0.
//
// !!!ROI
// For chosen interesting reflex need plot rectangle ROI. The ROI must be n x n.
// Hold down SHIFT or ALT and click and drag with the ROI tool selected.
// For chosen interesting reflex need to move ROI and click.
// In case ROI chosen it frozen.
// Clear ROI button removes ROI on display and clear memory of ROI coordinates.
// Exp.Ref.Disk used for selected ROI coordinates reference experimental diffraction disk. 
// Reference slise - chosen Slise with reference experimental diffraction disk. 
// In case Exp.Ref.Disk not pressed will be used ideal diffraction disk approach.
// Background as ROI used for filtering Reconstructed image.
// In case suma(ROI) for First, Second, and Third reflex > then suma(Background as ROI) pix value on reconstructed image will be 0.
// Background multiplier used for multiply suma(Background as ROI).
// Or You can set maximal Background value using set Background value.
// In case Background as ROI not pressed and set Background value not choised, Background approach filtering not used.
// In case remember ROI coordinates is off, after calculation script removes ROI on display and clear memory of ROI coordinates.
// In case remember ROI coordinates is on, ROI coordinates saved in memory if script was closed.
//
// The adaptive ROI:
// !!!!If adaptive ROI is on in case shift of diffraction disk bigger then 2pix the ROI of Firs, Second, and Third reflex shifted on 1pix !!!!
// The bigger total shift of diffraction disk then Max Shift, return initial ROI coordinates.
// The adaptive ROI good for large shifts and rotation of diffraction from Slice to Slice.
// The adaptive ROI mode can increase error in calculation.
// The adaptive ROI do not work for zero reflex (not shifted 000ROI)
//
// !!!Filters
// Can be done Sobel, ILLowPass and Butterworth (B'worth) images filtered
// 
// !!!Outputs
// You can use Calculate only One Row for fast adjust process parameters.
// Show RAW Image used to show image before filtered 
// Result can be saved as .txt file
// 



///////////////////////////
// Global variables
///////////////////////////

//*****Declareted value*****
	number RecImg_XSize=60 //Reconstruction image size X
	number RecImg_YSize=20 //Reconstruction image size Y

	number DiskRadius=12 // Disk Radius
	number Max_Shift=10 // Maximum shift in pix

class ScaningDifractionDialog : UIFrame
{
//*****
		void x_sizefieldchanged(object self, taggroup tg)
			{
			}
		void y_sizefieldchanged(object self, taggroup tg)
			{
			}
		void shiftfieldchanged(object self, taggroup tg)
			{
			}
		void Diskradiusfieldchanged(object self, taggroup tg)
			{
			}
		void BackgroundMultiplfieldchanged(object self, taggroup tg)
			{
			}
		void BackgroundValuefieldchanged(object self, taggroup tg)
			{
			}			
		void refslicefieldchanged(object self, taggroup tg)
			{
			}
		void ROIx_sizefieldchanged(object self, taggroup tg)
			{
			}
		void ROIy_sizefieldchanged(object self, taggroup tg)
			{
			}
		void zerox_centerfieldchanged(object self, taggroup tg)
			{
			}
		void zeroy_centerfieldchanged(object self, taggroup tg)
			{
			}
		void x_centerfieldchanged(object self, taggroup tg)
			{
			}
		void y_centerfieldchanged(object self, taggroup tg)
			{
			}
		void BWchanged(object self, taggroup tg)
			{
			}
	
	
// A Sobel edge finding function
// Partly based on "Stack Alignment" D. R. G. Mitchell version:20150524, v2.0, May 2015
image sobelfilter(object self, image sourceimg, number magorphaseflag, number SobelFlag) 
{
	// Declare and set up some variables
	
	image sobel, dx, dy
	number xsize, ysize
	getsize(sourceimg, xsize,ysize)

	number scalex, scaley
	string unitstring
	getscale(sourceimg,scalex, scaley)
	getunitstring(sourceimg, unitstring)

	// Create images to hold the derivatives - then calculate them

	sobel=Exprsize(xsize,ysize,0)
	dx=Exprsize(xsize,ysize,0)
	dy=Exprsize(xsize,ysize,0)

		dx = sourceimg[icol-1,irow-1]-sourceimg[icol+1,irow-1] +\
			2*(sourceimg[icol-1,irow+0]-sourceimg[icol+1,irow+0])+\
			sourceimg[icol-1,irow+1]-sourceimg[icol+1,irow+1]
         
        dy = sourceimg[icol-1,irow-1]-sourceimg[icol-1,irow+1] +\
            2*(sourceimg[icol+0,irow-1]-sourceimg[icol+0,irow+1])+\
            sourceimg[icol+1,irow-1]-sourceimg[icol+1,irow+1]

	// calculate either the magnitude or phase image depending on the passed in flag
	
		If (SobelFlag==1)
		{
			if(magorphaseflag==0) // if the flag is set to 0 calculate the magnitude image
				{
					sobel = sqrt(dx*dx+dy*dy)
					setscale(sobel, scalex, scaley)
					setunitstring(sobel, unitstring)
				}
			else // calculate the phase image
				{
					sobel = 180 * atan2(dy,dx) / Pi()
					setscale(sobel, scalex, scaley)
					setunitstring(sobel, unitstring)
				}
				
				deleteimage(dx)
				deleteimage(dy)
		}
		else  sobel=sourceimg

	return sobel
}

// A low pass smoothing filter for removing noise
// Partly based on "Stack Alignment" D. R. G. Mitchell version:20150524, v2.0, May 2015
Image ILLowPass(object self, image sourceimg, number ILLowPassFlag )
{
	Image result = sourceimg
	number scalex, scaley
	number nf = 1/9
	
		GetSize( sourceimg, scalex, scaley )
        SubArea imageS := sourceimg[ 1, 1, scaley - 2, scalex - 2 ]
        
	If (ILLowPassFlag==1)
	{
		result[ 1, 1, scaley - 2, scalex - 2 ] = nf * ( \
					imageS[icol-1,irow-1]+\
					imageS[icol-1,irow-0]+\
					imageS[icol-1,irow+1]+\
					imageS[icol-0,irow-1]+\
					imageS[icol-0,irow-0]+\
					imageS[icol-0,irow+1]+\
					imageS[icol+1,irow-1]+\
					imageS[icol+1,irow-0]+\
					imageS[icol+1,irow+1]);
	}	

	return result// end of low pass smoothing filter
}

// Function to create a butterworth filter. Imgxsize and imgysize are the sizes of the filter image
// bworthorder is a numerical value (1-6 is good), which defines the rate at which the edge of the filter
// decays to zero. Low values give shallow slopes. zeroradius specifies the radius of the filter.
// Partly based on "Stack Alignment" D. R. G. Mitchell version:20150524, v2.0, May 2015
Image butterworthfilter(object self, number bwXsize, number bwYsize, number bwOrder, number zeroradius, number ButterWorthFlag)
	{
		// See John Russ's Image Processing Handbook, 2nd Edn, p 31
		
	image butterworthimg=realimage("",4,bwXsize, bwYsize)
	butterworthimg=0
		If (ButterWorthFlag==1)
		{
			// note the halfpointconst value sets the value of the filter at the halfway point
			// ie where the radius = zeroradius. A value of 0.414 sets this value to 0.5
			// a value of 1 sets this point to root(2)

			number halfpointconst=0.414
			butterworthimg=1/(1+halfpointconst*(iradius/zeroradius)**(2*bwOrder))
			
		}
		Else butterworthimg=1
		return butterworthimg
	}
	
	Image AdaptedCircularHoughTransform(object self, Image InputImage, number MinRadius, number MaxRadius, number step, number &HoughRadius)
		{
		Number Radius
		Number MaxValue=0
		Image HoughImage, OutputImage
		For (Radius=MinRadius; Radius<MaxRadius; Radius=Radius+step)
			{
			HoughImage=ImageCircularHoughTransform(InputImage, Radius, 1, 1)
			
			If (max(HoughImage)>MaxValue)
				{
				MaxValue=max(HoughImage)
				OutputImage=HoughImage
				HoughRadius=Radius
				}
			}
		//HoughImage.DeleteImage()	
		Return 	OutputImage
		}
	
// Partly based on "Stack Alignment" D. R. G. Mitchell version:20150524, v2.0, May 2015	
void findcentreofgravity(object self, image centralroi, number &cogx, number &cogy)

	{

	// For information on this calculation see John Russ - Image Processing Handbook, 2nd Ed. p489
	number xpos, ypos, maxval, imgsum, xsize, ysize, i
	image tempimg

	maxval=max(centralroi, xpos, ypos)
	imgsum=sum(centralroi)
	getsize(centralroi, xsize, ysize)
	// Traps for a blank image

	if(imgsum==0) // the image is blank so set the CoGs to the centre of the image and return

		{

		cogx=(xsize-1)/2 //minus one since the centre of a 2 x 2 image is 0.5,0.5 - 0,0 is a position
		cogy=(ysize-1)/2 //minus one since the centre of a 2 x 2 image is 0.5,0.5 - 0,0 is a position
		return

		}

	// Collapse the image down onto the x axis

	image xproj=realimage("",4,xsize,1)
	xproj[icol,0]+=centralroi

	// Rotate the passed in image through 90 degs so that rows become columns
	// Then collapse that image down onto the x axis (was the y axis)

	tempimg=realimage("", 4, ysize, xsize)
	tempimg=centralroi[irow,icol]
	image yproj=realimage("",4,ysize, 1)
	yproj[icol,0]+=tempimg

	yproj=yproj*(icol+1) // NB the +1 ensures that for the left column and top row, where
	xproj=xproj*(icol+1) // icol=0 are included in the weighting. 1 must be subtracted from

	// the final position to compensate for this shift

	cogx=sum(xproj)
	cogy=sum(yproj)

	cogx=(cogx/imgsum)-1 // compensation for the above +1 to deal with icol=0
	cogy=(cogy/imgsum)-1
	
	}		
	
Number  CalckulateAngle(object self, number gx, number gy, number g)
	{
	Number	Alpha
	Number	LoalAlpha=abs(180/Pi()*asin(gy/g))
	If (gx>=0 && gy<=0) Alpha=LoalAlpha
	If (gx<=0 && gy<=0) Alpha=180-LoalAlpha
	If (gx<=0 && gy>=0) Alpha=180+LoalAlpha
	If (gx>=0 && gy>=0) Alpha=360-LoalAlpha
	Return Alpha
	}

//@@@@@@@@@@@@@@@@	
//*****ROI image
void  ROIimage(object self, number ROIname)
	{
	image InputStack
	ImageDisplay Disp1
	number Xsize, Ysize, Zsize
	number t,l,b,r
	number ROI_XCenter, ROI_YCenter, ROI_radius	//000
	number ID_ROI
	ROI selection, selection_new, selection_new2
	string roizero
	string str_ROIname=Decimal(ROIname)

			
	InputStack:=getfrontimage()
		try
			{
				get3dsize(InputStack, xsize, ysize, Zsize)
			}
		catch
			{
				showalert("Ensure the front-most image is a 3D stack.",2)
				return
			}
		
						
			Disp1 = InputStack.ImageGetImageDisplay(0)

			try
			{
				selection=ImageDisplayLookupROI(  Disp1, roizero )
				ROIGetRectangle (selection, t,l,b,r)

			}
			catch
			{
				showalert("There is no ROI.",2)
				return
			}

			
		ROI_XCenter=(l+r)/2 // 
		ROI_YCenter=(t+b)/2
		ROI_radius=(r-l+b-t)/4
		
			selection_new = CreateROI()
			ROISetColor( selection_new,  0,  0,  1 )
			selection_new.RoiSetRectangle( t,l,b,r)
			StringToUpper( str_ROIname ) 
			ROISetLabel( selection_new, str_ROIname )
			ROISetName( selection_new, str_ROIname )
			InputStack.ImageGetImageDisplay(0).ImageDisplayAddRoi(selection_new )
			ROISetMoveable( selection_new, 0 )
			ID_ROI=ROIGetID( selection_new )
			
		InputStack.ImageGetImageDisplay(0).ImageDisplayDeleteROI( selection)

			selection = CreateROI()
			ROISetColor( selection,  1,  0,  0 )
			selection.RoiSetRectangle( t,l,b,r)
			InputStack.ImageGetImageDisplay(0).ImageDisplayAddRoi(selection )
			
		setpersistentnumbernote("XCenter"+ROIname, ROI_XCenter)
		setpersistentnumbernote("YCenter"+ROIname, ROI_YCenter)
		setpersistentnumbernote("XCenter"+ROIname+"new", ROI_XCenter)
		setpersistentnumbernote("YCenter"+ROIname+"new", ROI_YCenter)
		setpersistentnumbernote("ROI_radius", ROI_radius)
		setpersistentnumbernote("ID_ROI"+ROIname, ID_ROI)
	
		beep()	
	}

Image RAWImage(object self, number WidthMult, number HeightMult, number WidthMultSize, number HeightMultSize,number ROI_radius, string name)
	{
		Image RAWImage
		number Screen_width, Screen_height 
		GetScreenSize( Screen_width, Screen_height )
		
		RAWImage := RealImage(name,4,2*ROI_radius,2*ROI_radius)
		RAWImage.DisplayAt(Screen_width*WidthMult,Screen_width*(0.02+HeightMult))
		RAWImage.SetWindowSize(Screen_width*WidthMultSize,Screen_width*HeightMultSize)
		SetSurvey( RAWImage, 1 )
		Return RAWImage
	}
		
Image ReconstrImage(object self, number WidthMult, number HeightMult,  string name)
	{
		
		Image ReconstrImage
		ImageDisplay Disp1
		number Screen_width, Screen_height
		GetScreenSize( Screen_width, Screen_height )
		number RecImg_XSize=dlggetvalue(self.lookupelement("x_sizefield")) //Reconstruction image size X
		number RecImg_YSize=dlggetvalue(self.lookupelement("y_sizefield")) //Reconstruction image size Y
		
		ReconstrImage:=RealImage(name,4,RecImg_XSize,RecImg_YSize);
		ReconstrImage.DisplayAt(Screen_width*WidthMult,Screen_width*(0.02+HeightMult))
		ReconstrImage.SetWindowSize(RecImg_XSize*5,RecImg_YSize*5)
		SetColorMode( ReconstrImage, 4 )
		SetSurvey( ReconstrImage, 1 )

		Return ReconstrImage
	}

void SumProces(object self, Image InputStack, Image ReflIntensImage, Image ReflIntensImage_Sum, number XCenter, number YCenter, number i, number j, number Slice,  number ROI_radius, \
				number Background, number BackgroundMultip, number BackgroundIsToBig, number ShowProcImage)
	{		
		number ReflIntens_SumNumber
		If (XCenter+YCenter>0)
		{
			ReflIntensImage=InputStack[XCenter-ROI_radius,YCenter-ROI_radius,Slice, \
			XCenter+ROI_radius,YCenter+ROI_radius,Slice+1];
	
			ReflIntens_SumNumber=sum(ReflIntensImage)
			If (ReflIntens_SumNumber<Background*BackgroundMultip) ReflIntens_SumNumber=BackgroundIsToBig
				ReflIntensImage_Sum[j,i,j+1,i+1]=ReflIntens_SumNumber
				UpdateImage(ReflIntensImage_Sum)
			If (ShowProcImage==1) UpdateImage(ReflIntensImage)
		}
	}

void ImageProces(object self, Image InputStack, Image ReflIntensImage, Image ImageRAW, number XCenter, number YCenter, number xShift, number yShift, number Slice,  number ROI_radius, 	number Background, \
			number BackgroundMultip, number AdaptiveModeFlag, number ShowProcImage, number ILLowPassFlag, number MagOrPhaseFlag, number SobelFlag, number  ButterWorthOrder, number ButterWorthFlag, number ShowRAWImage)
	{		
		number ReflIntens_SumNumber
		number real_XCenter,real_YCenter
		number Diskradius=dlggetvalue(self.lookupelement("Diskradiusfield"))
		If (XCenter+YCenter>0)
			{
		XCenter=abs(XCenter)
		YCenter=abs(YCenter)
				ReflIntensImage=InputStack[XCenter-ROI_radius,YCenter-ROI_radius,Slice, \
				XCenter+ROI_radius,YCenter+ROI_radius,Slice+1];
				
				If (ShowRAWImage==1)
					{
						ImageRAW=ReflIntensImage
						UpdateImage(ImageRAW)
					}	
				ReflIntensImage=self.ILLowPass(ReflIntensImage, ILLowPassFlag)
				ReflIntensImage=self.sobelfilter(ReflIntensImage, MagOrPhaseFlag, SobelFlag)
				ReflIntensImage=ReflIntensImage*self.butterworthfilter(ROI_radius*2, ROI_radius*2,  ButterWorthOrder,  Diskradius, ButterWorthFlag)
				
				If (ShowProcImage==1) ReflIntensImage.UpdateImage()
			}
	}
	
	

void clearROI(object self, Image InputStack, number flag)	
	{
		number xsize, ysize, Zsize
		
			try
				{
					get3dsize(InputStack, xsize, ysize, Zsize)
				}
			catch
				{
					showalert("Ensure the front-most image is a 3D stack.",2)
					return
				}
					
			
			ClearSelection( InputStack )
			
			setpersistentnumbernote("XCenter9", 0)		//Reference
			setpersistentnumbernote("YCenter9", 0)	
			setpersistentnumbernote("XCenter0", 0)		//Zero
			setpersistentnumbernote("YCenter0", 0)
			setpersistentnumbernote("XCenter1", 0)		//First
			setpersistentnumbernote("YCenter1", 0)
			setpersistentnumbernote("XCenter2", 0)		//Second
			setpersistentnumbernote("YCenter2", 0)
			setpersistentnumbernote("XCenter3", 0)		//Third
			setpersistentnumbernote("YCenter3", 0)
			setpersistentnumbernote("XCenter-1", 0)		//Background
			setpersistentnumbernote("YCenter-1", 0)		//Background
			If (flag==1) showalert("All ROI coordinates are cleared",1)
	}

void ReferenceROIButtonpushed(object self)
	{
	
	image InputStack
	ImageDisplay Disp1
	number Xsize, Ysize, Zsize
	number t,l,b,r
	number ROI_XCenter, ROI_YCenter, ROI_radius	//000
	number ID_ROI
	ROI selection, selection_new, selection_new2
	string roizero
	number ROIname=9
	
		InputStack:=getfrontimage()

		Disp1 = InputStack.ImageGetImageDisplay(0)

			try
			{
				selection=ImageDisplayLookupROI(  Disp1, roizero )
				ROIGetRectangle (selection, t,l,b,r)
				
			}
			catch
			{
				showalert("There is no ROI.",2)
				return
			}
		ROI_XCenter=(l+r)/2 // 
		ROI_YCenter=(t+b)/2
		ROI_radius=(r-l+b-t)/4
			
		setpersistentnumbernote("XCenter"+ROIname, ROI_XCenter)
		setpersistentnumbernote("YCenter"+ROIname, ROI_YCenter)
		setpersistentnumbernote("ROI_radius", ROI_radius)
		setpersistentnumbernote("ID_ROI"+ROIname, ID_ROI)
		beep()
	}
	
void ZeroROIButtonpushed(object self)
	{
	self.ROIimage(0)		
	}
	
void FirstROIButtonpushed(object self)
	{
	self.ROIimage(1)		
	}
	
void SecondROIButtonpushed(object self)
	{
	self.ROIimage(2)		
	}
	
void ThirdROIButtonpushed(object self)
	{
	self.ROIimage(3)		
	}
	
void BackgroundROIButtonpushed(object self)
	{
	self.ROIimage(-1)		
	}
	
void clearROIButtonpushed(object self)	
	{
	Image InputStack
	InputStack:=getfrontimage()
	self.clearROI(InputStack,1)
	}
	
//*****************************************
//*****************************************
void CalculateShift(object self)
	{ 
	number Slice=0
	number BackgroundIsToBig=0		
	number i, j	
	number Xsize, Ysize, Zsize
	image Temp_im
	Image InputStack:=getfrontimage()
			try
			{
				get3dsize(InputStack, xsize, ysize, Zsize)
			}
				catch
			{
				showalert("Ensure the front-most image is a 3D stack.",2)
				return
			}
			
	Image ZeroRefl, FirstRefl, SecondRefl, BackgroundIntens				//processed Images
	Image ZeroReflRAW, FirstReflRAW, SecondReflRAW						//RAW Images
	Image crosscorrFirst, crosscorrSecond, crosscorrZero				//crosscorrelated Images
	Image ZeroRefl_Xshift, ZeroRefl_Yshift, Zero_g_im, ZeroRefl_SumIm, ZeroRefl_HoughRadIm				//Reconstructed Images of Zero Reflex
	Image FirstRefl_Xshift, FirstRefl_Yshift, First_g_im, FirstRefl_Alpha, FirstRefl_SumIm, FirstRefl_HoughRadIm			//Reconstructed Images of First Reflex
	Image SecondRefl_Xshift, SecondRefl_Yshift, Second_g_im, SecondRefl_Alpha, SecondRefl_SumIm, SecondRefl_HoughRadIm		//Reconstructed Images of Second Reflex
	number Second_x_Shift=0, Second_y_Shift=0, Second_g_Shift, Second_gx, Second_gy, Second_g 			//shifts of reflex centers (Second reflex)	
	
//*********ThirdRefl
	Image ThirdRefl, ThirdReflRAW, crosscorrThird
	Image ThirdRefl_Xshift, ThirdRefl_Yshift, Third_g_im, ThirdRefl_Alpha, ThirdRefl_SumIm, ThirdRefl_HoughRadIm 
	number Third_x_Shift=0, Third_y_Shift=0, Third_g_Shift, Third_gx, Third_gy, Third_g				//shifts of reflex centers (Third reflex)	
	number ThirdReflIntens_SumNumber
	number XCenterThirdROI=0, YCenterThirdROI=0
	number XCenterThirdROInew, YCenterThirdROInew
	number Third_x_delta, Third_y_delta
	number ThirdReflCentrX, ThirdReflCentrY
	Image BackgroundIntens_Sum 											//Reconstructed Images of Background Sum
	
	Image RefImage, RefImageRAW											//Reference Images
	
	number Zero_x_Shift=0, Zero_y_Shift=0, Zero_g_Shift, Zero_gx, Zero_gy, Zero_g	
	
	number First_x_Shift=0, First_y_Shift=0, First_g_Shift, First_gx=0.0, First_gy, First_g					//shifts of reflex centers (First reflex)

	number XCenterFirstROI_ad, YCenterFirstROI_ad
		number	RecImg_XSize=dlggetvalue(self.lookupelement("x_sizefield")) 					//Reconstruction image size X
		number	RecImg_YSize=dlggetvalue(self.lookupelement("y_sizefield")) 					//Reconstruction image size Y
		
		
	number ROIname
	number ZeroReflIntens_SumNumber, FirstReflIntens_SumNumber, SecondReflIntens_SumNumber
	
	number	ZeroReflCentrX, ZeroReflCentrY
	number	FirstReflCentrX, FirstReflCentrY
	number	SecondReflCentrX, SecondReflCentrY, posx, posy
	number XCenterZeroROInew, YCenterZeroROInew					//shifts of reflex centers (Zero reflex)
	number XCenterFirstROInew, YCenterFirstROInew					//shifts of reflex centers (Zero reflex)
	number XCenterSecondROInew, YCenterSecondROInew					//shifts of reflex centers (Zero reflex)
	//number XCenterZeroROInew, YCenterZeroROInew					//shifts of reflex centers (Zero reflex)
	number Zero_x_delta=0, Zero_y_delta=0	
	number First_x_delta=0, First_y_delta=0, Second_x_delta=0, Second_y_delta=0
	
	number ZeroRefl_sum, FirstRefl_sum, SecondRefl_sum, ThirdRefl_sum
	number First_alpha, Second_alpha, Third_alpha
	
	number HoughRadius
	
	String filename, text
	Number fileID
	
	//Flags

		number ShowRAWImage=dlggetvalue(self.lookupelement("ShowRAWImageBox"))
		number ShowProcImage=dlggetvalue(self.lookupelement("ShowImageBox"))
		number ShowOneRowFlag=dlggetvalue(self.lookupelement("ShowOneRowBox"))
		number AdaptiveModeFlag=dlggetvalue(self.lookupelement("AdaptiveBox"))
		number ShowXYShift=dlggetvalue(self.lookupelement("ShowXYShiftBox"))
		number Backgroundradio=dlggetvalue(self.lookupelement("Backgroundradio"))
		
		number SobelFlag=dlggetvalue(self.lookupelement("Sobelbox"))
		number MagOrPhaseFlag=0//dlggetvalue(self.lookupelement("Sobelradio"))
		number ButterWorthOrder=dlggetvalue(self.lookupelement("Bworth"))
		number ButterWorthFlag=dlggetvalue(self.lookupelement("BWorthbox"))
		number ILLowPassFlag=dlggetvalue(self.lookupelement("ILLowBox"))
		number MatchAlgorithm=dlggetvalue(self.lookupelement("Algorithmradio"))
		number MinHoughRadius=dlggetvalue(self.lookupelement("MinRadiusField"))
		number MaxHoughRadius=dlggetvalue(self.lookupelement("MaxRadiusField"))
		number HoughRadiusStep=dlggetvalue(self.lookupelement("StepField"))
		//number useRefslice=dlggetvalue(self.lookupelement("refsliceBox"))
		number rememberROIFlag=dlggetvalue(self.lookupelement("rememberROIBox"))
		number ShowCrosscorImage=dlggetvalue(self.lookupelement("ShowCrosscorImageBox"))
		number BackgroundMultip=dlggetvalue(self.lookupelement("BackgroundMultiplfield"))
		number Background=dlggetvalue(self.lookupelement("Backgroundvaluefield"))
			Diskradius=dlggetvalue(self.lookupelement("Diskradiusfield"))
			Max_Shift=dlggetvalue(self.lookupelement("shiftfield"))
		number Savetxt=dlggetvalue(self.lookupelement("SavetxtBox"))
		number ShowAlpha=dlggetvalue(self.lookupelement("ShowAlphaBox"))
		number RefSlice=dlggetvalue(self.lookupelement("refslicefield"))
		number ShowSum=dlggetvalue(self.lookupelement("ShowSumBox"))
		number ShowHoughRad=dlggetvalue(self.lookupelement("ShowHoughRadBox"))

 
//ROI coordinates
	number XCenterZeroROI=0, YCenterZeroROI=0
	number XCenterFirstROI=0, YCenterFirstROI=0
	number XCenterSecondROI=0, YCenterSecondROI=0
	
	number XCenterReferenceROI=0, YCenterReferenceROI=0
	number XCenterBackgroundROI=0, YCenterBackgroundROI=0
	number ROI_radius=0
	

			getpersistentnumbernote("XCenter9", XCenterReferenceROI)				
			getpersistentnumbernote("YCenter9", YCenterReferenceROI)
			getpersistentnumbernote("XCenter0", XCenterZeroROI)				//Zero
			getpersistentnumbernote("YCenter0", YCenterZeroROI)
			getpersistentnumbernote("XCenter1", XCenterFirstROI)			//First
			getpersistentnumbernote("YCenter1", YCenterFirstROI)
			getpersistentnumbernote("XCenter2", XCenterSecondROI)			//Second
			getpersistentnumbernote("YCenter2", YCenterSecondROI)
			getpersistentnumbernote("XCenter3", XCenterThirdROI)			//Third ROI
			getpersistentnumbernote("YCenter3", YCenterThirdROI)			
			getpersistentnumbernote("XCenter-1", XCenterBackgroundROI)		//Background
			getpersistentnumbernote("YCenter-1", YCenterBackgroundROI)
			getpersistentnumbernote("ROI_radius", ROI_radius)
	
		XCenterZeroROInew=XCenterZeroROI
		YCenterZeroROInew=YCenterZeroROI
		XCenterFirstROInew=XCenterFirstROI
		YCenterFirstROInew=YCenterFirstROI	
		XCenterSecondROInew=XCenterSecondROI
		YCenterSecondROInew=YCenterSecondROI
		XCenterThirdROInew=XCenterThirdROI
		YCenterThirdROInew=YCenterThirdROI	
	If (Savetxt==1)
		{
		If (!SaveAsDialog("Save text file as", GetApplicationDirectory(2,0) + "myText.txt", filename)) Exit(0)
		Result("\n Selected file path:"+filename)
		fileID = CreateFileForWriting(filename)
		WriteFile(fileID, "\n i j Zero_g Zero_gx Zero_gy ZeroRefl_Sum")
		If (XCenterFirstROI+YCenterFirstROI>0)
			{
			WriteFile(fileID," First_g First_gx First_gy FirstRefl_Sum FirstRefl_Alpha")
			}
		If (XCenterSecondROI+YCenterSecondROI>0)
			{
			WriteFile(fileID," Second_g Second_gx Second_gy SecondRefl_Sum SecondRefl_Alpha")
			}	
		If (XCenterThirdROI+YCenterThirdROI>0)
			{
			WriteFile(fileID," Third_g Third_gx Third_gy ThirdRefl_Sum ThirdRefl_Alpha")
			}
				
		}

	ZeroRefl:=self.RAWImage(0.56, 0.0, 0.1, 0.1, ROI_radius,  "ZeroRefl") //(Position_x, Position_y, Size_x, Size_y, Name)
	//If (ShowProcImage==1) showimage(ZeroRefl)
		If (ShowRAWImage==1)
			{
			ZeroReflRAW:=self.RAWImage(0.56, 0.12, 0.1, 0.1, ROI_radius,  "ZeroReflRAW") //(Position_x, Position_y, Size_x, Size_y, Name)
			showimage(ZeroReflRAW)
			}
		If (ShowCrosscorImage==1)
			{
			crosscorrZero:=self.RAWImage(0.56, 0.24, 0.1, 0.1, ROI_radius,  "crosscorrZero") //(Position_x, Position_y, Size_x, Size_y, Name)
			showimage(crosscorrZero)
			}
		
// Reference Image	
		RefImage:=self.RAWImage(0.56, 0.36, 0.1, 0.1, ROI_radius,  "RefImage") //(Position_x, Position_y, Size_x, Size_y, Name)
		If (XCenterReferenceROI+YCenterReferenceROI>0)
			{
			RefImage=InputStack[XCenterReferenceROI-ROI_radius,YCenterReferenceROI-ROI_radius,RefSlice, \
				XCenterReferenceROI+ROI_radius,YCenterReferenceROI+ROI_radius,RefSlice+1]
			}
		Else
			{
			RefImage=100
			RefImage=tert( Diskradius>iradius, RefImage,0)
			}
		If (ShowRAWImage==1)
			{
			RefImageRAW:=self.RAWImage(0.67, 0.36, 0.1, 0.1, ROI_radius,  "RefImageRAW") //(Position_x, Position_y, Size_x, Size_y, Name)
			RefImageRAW=RefImage
			showimage(RefImageRAW)
			}
		RefImage=self.ILLowPass(RefImage, ILLowPassFlag)
		RefImage=self.sobelfilter(RefImage, MagOrPhaseFlag, SobelFlag)
		RefImage=RefImage*self.butterworthfilter(ROI_radius*2, ROI_radius*2,  ButterWorthOrder,  Diskradius, ButterWorthFlag)
		If (ShowProcImage==1) showimage(RefImage)

	If (XCenterFirstROI+YCenterFirstROI>0)
		{	
		FirstRefl:=self.RAWImage(0.67, 0.0, 0.1, 0.1, ROI_radius,  "FirstRefl") //(Position_x, Position_y, Size_x, Size_y, Name)
		If (ShowProcImage==1) showimage(FirstRefl)
			If (ShowRAWImage==1)
				{
				FirstReflRAW:=self.RAWImage(0.67, 0.12, 0.1, 0.1, ROI_radius,  "FirstReflRAW") //(Position_x, Position_y, Size_x, Size_y, Name)
				showimage(FirstReflRAW)
				}
			If (ShowCrosscorImage==1)
				{
				crosscorrFirst:=self.RAWImage(0.67, 0.24, 0.1, 0.1, ROI_radius,  "crosscorrFirst") //(Position_x, Position_y, Size_x, Size_y, Name)
				showimage(crosscorrFirst)
				}
		}

	Zero_g_im:=self.ReconstrImage(0.0, 0.0, "Zero_g_im")
	showimage(Zero_g_im)
	If (ShowXYShift==1)
		{
		ZeroRefl_Xshift:=self.ReconstrImage(0.1, 0.0, "ZeroRefl_Xshift")
		showimage(ZeroRefl_Xshift)
		ZeroRefl_Yshift:=self.ReconstrImage(0.2, 0.0, "ZeroRefl_Yshift")
		showimage(ZeroRefl_Yshift)
		}
	If (ShowSum==1)
			{	
			ZeroRefl_SumIm:=self.ReconstrImage(0.4, 0.0,  "ZeroRefl_Sum")
			showimage(ZeroRefl_SumIm)
			}	
	If (ShowHoughRad==1 && MatchAlgorithm==1)
			{	
			ZeroRefl_HoughRadIm:=self.ReconstrImage(0.5, 0.0,  "ZeroRefl_HoughRad")
			showimage(ZeroRefl_HoughRadIm)	
			}
		
	If (XCenterFirstROI+YCenterFirstROI>0)
		{
		First_g_im:=self.ReconstrImage(0.0, 0.1,  "First_g_im")
		showimage(First_g_im)
		If (ShowXYShift==1)
			{	
			FirstRefl_Xshift:=self.ReconstrImage(0.1, 0.1,  "FirstRefl_Xshift")
			showimage(FirstRefl_Xshift)
			FirstRefl_Yshift:=self.ReconstrImage(0.2, 0.1,  "FirstRefl_Yshift")
			showimage(FirstRefl_Yshift)
			}
		If (ShowAlpha==1)
			{	
			FirstRefl_Alpha:=self.ReconstrImage(0.3, 0.1,  "FirstRefl_Alpha")
			showimage(FirstRefl_Alpha)
			}
		If (ShowSum==1)
			{	
			FirstRefl_SumIm:=self.ReconstrImage(0.4, 0.1,  "FirstRefl_Sum")
			showimage(FirstRefl_SumIm)
			}
		If (ShowHoughRad==1 && MatchAlgorithm==1)
			{	
			FirstRefl_HoughRadIm:=self.ReconstrImage(0.5, 0.1,  "FirstRefl_HoughRad")
			showimage(FirstRefl_HoughRadIm)
			}
		}	
		
	If (XCenterSecondROI+YCenterSecondROI>0)
		{
		SecondRefl:=self.RAWImage(0.78, 0.0, 0.1, 0.1, ROI_radius,  "SecondRefl") //(Position_x, Position_y, Size_x, Size_y, Name)
		If (ShowProcImage==1) showimage(SecondRefl)
		If (ShowRAWImage==1)
			{
			SecondReflRAW:=self.RAWImage(0.78, 0.12, 0.1, 0.1, ROI_radius,  "SecondReflRAW") //(Position_x, Position_y, Size_x, Size_y, Name)
			showimage(SecondReflRAW)
			}
		If (ShowCrosscorImage==1)
			{
			crosscorrSecond:=self.RAWImage(0.78, 0.24, 0.1, 0.1, ROI_radius,  "crosscorrSecond") //(Position_x, Position_y, Size_x, Size_y, Name)
			showimage(crosscorrSecond)
			}
		Second_g_im:=self.ReconstrImage(0.0, 0.2,  "Second_g_im")
		showimage(Second_g_im)
		If (ShowXYShift==1)
			{	
			SecondRefl_Xshift:=self.ReconstrImage(0.1, 0.2,  "SecondRefl_Xshift")
			showimage(SecondRefl_Xshift)
			SecondRefl_Yshift:=self.ReconstrImage(0.2, 0.2,  "SecondRefl_Yshift")
			showimage(SecondRefl_Yshift)
			}
			If (ShowAlpha==1)
			{	
			SecondRefl_Alpha:=self.ReconstrImage(0.3, 0.2,  "SecondRefl_Alpha")
			showimage(SecondRefl_Alpha)
			}
			If (ShowSum==1)
			{	
			SecondRefl_SumIm:=self.ReconstrImage(0.4, 0.2,  "SecondRefl_Sum")
			showimage(SecondRefl_SumIm)
			}
			If (ShowHoughRad==1 && MatchAlgorithm==1)
			{	
			SecondRefl_HoughRadIm:=self.ReconstrImage(0.5, 0.2,  "SecondRefl_HoughRad")
			showimage(SecondRefl_HoughRadIm)
			}
		}
		
		If (XCenterThirdROI+YCenterThirdROI>0)
		{
		ThirdRefl:=self.RAWImage(0.89, 0.0, 0.1, 0.1, ROI_radius,  "ThirdRefl") //(Position_x, Position_y, Size_x, Size_y, Name)
		If (ShowProcImage==1) showimage(ThirdRefl)
		If (ShowRAWImage==1)
			{
			ThirdReflRAW:=self.RAWImage(0.89, 0.12, 0.1, 0.1, ROI_radius,  "ThirdReflRAW") //(Position_x, Position_y, Size_x, Size_y, Name)
			showimage(ThirdReflRAW)
			}
		If (ShowCrosscorImage==1)
			{
			crosscorrThird:=self.RAWImage(0.89, 0.24, 0.1, 0.1, ROI_radius,  "crosscorrThird") //(Position_x, Position_y, Size_x, Size_y, Name)
			showimage(crosscorrThird)
			}
		Third_g_im:=self.ReconstrImage(0.0, 0.3,  "Third_g_im")
		showimage(Third_g_im)
		If (ShowXYShift==1)
			{	
			ThirdRefl_Xshift:=self.ReconstrImage(0.1, 0.3,  "ThirdRefl_Xshift")
			showimage(ThirdRefl_Xshift)
			ThirdRefl_Yshift:=self.ReconstrImage(0.2, 0.3,  "ThirdRefl_Yshift")
			showimage(ThirdRefl_Yshift)
			}
		If (ShowAlpha==1)
			{	
			ThirdRefl_Alpha:=self.ReconstrImage(0.3, 0.3,  "ThirdRefl_Alpha")
			showimage(ThirdRefl_Alpha)
			}
		If (ShowSum==1)
			{	
			ThirdRefl_SumIm:=self.ReconstrImage(0.4, 0.3,  "ThirdRefl_Sum")
			showimage(ThirdRefl_SumIm)
			}
		If (ShowHoughRad==1 && MatchAlgorithm==1)
			{	
			ThirdRefl_HoughRadIm:=self.ReconstrImage(0.5, 0.3,  "ThirdRefl_HoughRad")
			showimage(ThirdRefl_HoughRadIm)
			}
		}	
	

		If (XCenterBackgroundROI+YCenterBackgroundROI>0)
			{
			BackgroundIntens:=self.RAWImage(0.78, 0.36, 0.1, 0.1, ROI_radius,  "Background_Intens") //(Position_x, Position_y, Size_x, Size_y, Name)
			showimage(BackgroundIntens)	
			BackgroundIntens_Sum:=self.ReconstrImage(0, 0.4,  "BackgroundIntens_Sum")
			showimage(BackgroundIntens_Sum)
			}
		
//******************************************************************	
	
		
	
	If (ShowOneRowFlag==1)RecImg_YSize=1
	for (j=0; j<RecImg_YSize; j++)
		{
 
		for (i=0; i<RecImg_XSize; i++)
			{
			if (ShiftDown() && SpaceDown()==1) break
			
			If (XCenterBackgroundROI+YCenterBackgroundROI>0)
				{
				BackgroundIntens=InputStack[XCenterBackgroundROI-ROI_radius,YCenterBackgroundROI-ROI_radius,Slice, \
				XCenterBackgroundROI+ROI_radius,YCenterBackgroundROI+ROI_radius,Slice+1];
				If (Backgroundradio==0)
					{
					Background=sum(BackgroundIntens)*BackgroundMultip
					}
				BackgroundIntens_Sum[j,i,j+1,i+1]=Background
				UpdateImage(BackgroundIntens_Sum)
					If (ShowProcImage==1) BackgroundIntens.UpdateImage()
				}
		
				self.ImageProces(  InputStack,  ZeroRefl, ZeroReflRAW,  XCenterZeroROInew,  YCenterZeroROInew,  Zero_x_shift,  Zero_x_shift,  Slice,   ROI_radius, \
						 Background,  BackgroundMultip,  AdaptiveModeFlag,  ShowProcImage,  ILLowPassFlag,  MagOrPhaseFlag,  SobelFlag,   ButterWorthOrder,  ButterWorthFlag, ShowRAWImage)
				
			
				self.ImageProces(  InputStack,  FirstRefl, FirstReflRAW, XCenterFirstROInew,  YCenterFirstROInew,  First_x_shift,  First_y_shift,  Slice,   ROI_radius, \
						 Background,  BackgroundMultip,  AdaptiveModeFlag,  ShowProcImage,  ILLowPassFlag,  MagOrPhaseFlag,  SobelFlag,   ButterWorthOrder,  ButterWorthFlag, ShowRAWImage)
					
				self.ImageProces(  InputStack,  SecondRefl, SecondReflRAW, XCenterSecondROInew,  YCenterSecondROInew,  Second_x_shift,  Second_y_shift,  Slice,   ROI_radius, \
						 Background,  BackgroundMultip,  AdaptiveModeFlag,  ShowProcImage,  ILLowPassFlag,  MagOrPhaseFlag,  SobelFlag,   ButterWorthOrder,  ButterWorthFlag, ShowRAWImage)
				self.ImageProces(  InputStack,  ThirdRefl, ThirdReflRAW, XCenterThirdROInew,  YCenterThirdROInew,  Third_x_shift,  Third_y_shift,  Slice,   ROI_radius, \
						 Background,  BackgroundMultip,  AdaptiveModeFlag,  ShowProcImage,  ILLowPassFlag,  MagOrPhaseFlag,  SobelFlag,   ButterWorthOrder,  ButterWorthFlag, ShowRAWImage) 
	
				
						 
		
		

//*!!!!!!!!!!!!!!!!!!!	    |
//*!!!!!!!!!!!!!!!!!!!!!!!  |
//*!!!!!!!!!!!!!mathematics V


		If (MatchAlgorithm==0) 
			{
			crosscorrZero=crosscorrelation(RefImage, ZeroRefl)
			IUImageFindMax(crosscorrZero, 0, 0, 2*ROI_radius, 2*ROI_radius, Zero_x_delta, Zero_y_delta, 1)
			Zero_x_delta=-Zero_x_delta
			Zero_y_delta=-Zero_y_delta
			}
		If(MatchAlgorithm==1)			//Circular Hough Transform
			{
			crosscorrZero=self.AdaptedCircularHoughTransform(ZeroRefl, MinHoughRadius, MaxHoughRadius, HoughRadiusStep, HoughRadius)
			IUImageFindMax(crosscorrZero, 0, 0, 2*ROI_radius, 2*ROI_radius, Zero_x_delta, Zero_y_delta, 1)
			Zero_x_delta=Zero_x_delta
			Zero_y_delta=Zero_y_delta
			}
	
			Zero_x_shift=Zero_x_delta
			Zero_y_shift=Zero_y_delta
		

		Zero_gx=XCenterZeroROInew+Zero_x_shift
		Zero_gy=YCenterZeroROInew+Zero_y_shift
		Zero_g=sqrt(Zero_gx*Zero_gx+Zero_gy*Zero_gy)
		Zero_g_im[j,i,j+1,i+1]=Zero_g
				
			ZeroReflCentrX=Zero_gx
			ZeroReflCentrY=Zero_gy

		Temp_im=InputStack[ZeroReflCentrX-ROI_radius,ZeroReflCentrY-ROI_radius,Slice, \
		ZeroReflCentrX+ROI_radius,ZeroReflCentrY+ROI_radius,Slice+1]
		Temp_im=tert((iradius<Diskradius), Temp_im,0)
		ZeroRefl_sum=sum(Temp_im)

		UpdateImage(Zero_g_im)
		If (Savetxt==1)
			{
			WriteFile(fileID, "\n"+i+" "+j+" "+Zero_g+" "+Zero_gx+" "+Zero_gy+" "+ZeroRefl_sum)
			}

		If (ShowXYShift==1)
			{
			ZeroRefl_Xshift[j,i,j+1,i+1]=Zero_gx
			ZeroRefl_Yshift[j,i,j+1,i+1]=Zero_gy
			UpdateImage(ZeroRefl_Xshift)
			UpdateImage(ZeroRefl_Yshift)
			}
		If (ShowSum==1)
			{	
			ZeroRefl_SumIm[j,i,j+1,i+1]=ZeroRefl_sum
			UpdateImage(ZeroRefl_SumIm)
			}
		If (ShowHoughRad==1 && MatchAlgorithm==1)
			{	
			ZeroRefl_HoughRadIm[j,i,j+1,i+1]=HoughRadius
			UpdateImage(ZeroRefl_HoughRadIm)
			}	
		If (ShowCrosscorImage==1)
			{
			UpdateImage(crosscorrZero)
			}
				
			

				
	If (XCenterFirstROI+YCenterFirstROI>0)
		{		
		If (MatchAlgorithm==0)
			{
			crosscorrFirst=crosscorrelation(RefImage, FirstRefl)
			IUImageFindMax(crosscorrFirst, 0, 0, 2*ROI_radius, 2*ROI_radius, First_x_shift, First_y_shift, 1)
			First_x_shift=-First_x_shift
			First_y_shift=-First_y_shift
			}
		If(MatchAlgorithm==1)			//Circular Hough Transform
			{
			crosscorrFirst=self.AdaptedCircularHoughTransform(FirstRefl, MinHoughRadius, MaxHoughRadius, HoughRadiusStep, HoughRadius)
			IUImageFindMax(crosscorrFirst, 0, 0, 2*ROI_radius, 2*ROI_radius, First_x_shift, First_y_shift, 1)
			First_x_shift=First_x_shift
			First_y_shift=First_y_shift
			}
		
		
			FirstReflCentrX=XCenterFirstROInew+First_x_shift
			FirstReflCentrY=YCenterFirstROInew+First_y_shift
			First_gx=FirstReflCentrX-Zero_gx
			First_gy=FirstReflCentrY-Zero_gy
		
			If (abs(First_x_shift)> Max_Shift || abs(First_y_shift) > Max_Shift || sum(FirstRefl)<Background)
				{
				First_x_shift=0
				First_y_shift=0
				First_gx=0
				First_gy=0
				}
					
		First_g=sqrt(First_gx*First_gx+First_gy*First_gy)		
		First_g_im[j,i,j+1,i+1]=First_g
		
			If (AdaptiveModeFlag==1)
				
				{
					If (First_x_shift>2) XCenterFirstROInew=XCenterFirstROInew+1
					If (First_x_shift<2) XCenterFirstROInew=XCenterFirstROInew-1
					If (First_y_shift>2) YCenterFirstROInew=YCenterFirstROInew+1
					If (First_y_shift<2) YCenterFirstROInew=YCenterFirstROInew-1
					If (abs(XCenterFirstROInew-XCenterFirstROI)>Max_Shift ||  abs(YCenterFirstROInew-YCenterFirstROI)>Max_Shift || sum(FirstRefl)<Background)
						{
							XCenterFirstROInew=XCenterFirstROI
							YCenterFirstROInew=YCenterFirstROI
						}	
			
				}
		Temp_im=InputStack[FirstReflCentrX-ROI_radius,FirstReflCentrY-ROI_radius,Slice, \
		FirstReflCentrX+ROI_radius,FirstReflCentrY+ROI_radius,Slice+1]
		Temp_im=tert((iradius<Diskradius), Temp_im,0)
		FirstRefl_sum=sum(Temp_im)	
		
		First_alpha=0
		If(abs(First_g)>0)
			{
			First_alpha=self.CalckulateAngle(First_gx, First_gy, First_g)
			}
		
		If (Savetxt==1)
			{
			WriteFile(fileID, " "+First_g+" "+First_gx+" "+First_gy+" "+FirstRefl_sum+" "+ First_alpha)
			}
		
		UpdateImage(First_g_im)
		If (ShowXYShift==1)
			{
			FirstRefl_Xshift[j,i,j+1,i+1]=abs(FirstReflCentrX)
			FirstRefl_Yshift[j,i,j+1,i+1]=abs(FirstReflCentrY)
			UpdateImage(FirstRefl_Xshift)
			UpdateImage(FirstRefl_Yshift)
			}
		If (ShowAlpha==1)
			{
			FirstRefl_Alpha[j,i,j+1,i+1]=First_alpha
			UpdateImage(FirstRefl_Alpha)
			}	
		If (ShowSum==1)
			{	
			FirstRefl_SumIm[j,i,j+1,i+1]=FirstRefl_sum
			UpdateImage(FirstRefl_SumIm)
			}
		If (ShowHoughRad==1 && MatchAlgorithm==1)
			{	
			FirstRefl_HoughRadIm[j,i,j+1,i+1]=HoughRadius
			UpdateImage(FirstRefl_HoughRadIm)
			}	
		If (ShowCrosscorImage==1)
			{
			UpdateImage(crosscorrFirst)
			}		 
		}
		


	If (XCenterSecondROI+YCenterSecondROI>0)
		{
				
		If (MatchAlgorithm==0)
			{
			crosscorrSecond=crosscorrelation(RefImage, SecondRefl)
			IUImageFindMax(crosscorrSecond, 0, 0, 2*ROI_radius, 2*ROI_radius, Second_x_shift, Second_y_shift, 1)
			Second_x_shift=-Second_x_shift
			Second_y_shift=-Second_y_shift
			}
		If(MatchAlgorithm==1)			//Circular Hough Transform
			{
			crosscorrSecond=self.AdaptedCircularHoughTransform(SecondRefl, MinHoughRadius, MaxHoughRadius, HoughRadiusStep, HoughRadius)
			IUImageFindMax(crosscorrSecond, 0, 0, 2*ROI_radius, 2*ROI_radius, Second_x_shift, Second_y_shift, 1)
			Second_x_shift=Second_x_shift
			Second_y_shift=Second_y_shift
			}
			
			SecondReflCentrX=XCenterSecondROInew+Second_x_shift
			SecondReflCentrY=YCenterSecondROInew+Second_y_shift
			Second_gx=SecondReflCentrX-Zero_gx
			Second_gy=SecondReflCentrY-Zero_gy
		
			If (abs(Second_x_shift)> Max_Shift || abs(Second_y_shift) > Max_Shift || sum(SecondRefl)<Background)
				{
				Second_x_shift=0
				Second_y_shift=0
				Second_gx=0
				Second_gy=0
				}
					
		Second_g=sqrt(Second_gx*Second_gx+Second_gy*Second_gy)		
		Second_g_im[j,i,j+1,i+1]=Second_g
		
			If (AdaptiveModeFlag==1)
				
				{
					If (Second_x_shift>2) XCenterSecondROInew=XCenterSecondROInew+1
					If (Second_x_shift<2) XCenterSecondROInew=XCenterSecondROInew-1
					If (Second_y_shift>2) YCenterSecondROInew=YCenterSecondROInew+1
					If (Second_y_shift<2) YCenterSecondROInew=YCenterSecondROInew-1
					If (abs(XCenterSecondROInew-XCenterSecondROI)>Max_Shift ||  abs(YCenterSecondROInew-YCenterSecondROI)>Max_Shift || sum(SecondRefl)<Background)
						{
							XCenterSecondROInew=XCenterSecondROI
							YCenterSecondROInew=YCenterSecondROI
						}	
			
				}
		Temp_im=InputStack[SecondReflCentrX-ROI_radius,SecondReflCentrY-ROI_radius,Slice, \
		SecondReflCentrX+ROI_radius,SecondReflCentrY+ROI_radius,Slice+1]
		Temp_im=tert((iradius<Diskradius), Temp_im,0)
		SecondRefl_sum=sum(Temp_im)	
		
		Second_alpha=0
		If(abs(Second_g)>0)
			{
			Second_alpha=self.CalckulateAngle(Second_gx, Second_gy, Second_g)
			}
		
		If (Savetxt==1)
			{
			WriteFile(fileID, " "+Second_g+" "+Second_gx+" "+Second_gy+" "+SecondRefl_sum+" "+ Second_alpha)
			}
		
		UpdateImage(Second_g_im)
		If (ShowXYShift==1)
			{
			SecondRefl_Xshift[j,i,j+1,i+1]=abs(SecondReflCentrX)
			SecondRefl_Yshift[j,i,j+1,i+1]=abs(SecondReflCentrY)
			UpdateImage(SecondRefl_Xshift)
			UpdateImage(SecondRefl_Yshift)
			}
		If (ShowAlpha==1)
			{
			SecondRefl_Alpha[j,i,j+1,i+1]=Second_alpha
			UpdateImage(SecondRefl_Alpha)
			}	
		If (ShowSum==1)
			{	
			SecondRefl_SumIm[j,i,j+1,i+1]=SecondRefl_sum
			UpdateImage(SecondRefl_SumIm)
			}
		If (ShowHoughRad==1 && MatchAlgorithm==1)
			{	
			SecondRefl_HoughRadIm[j,i,j+1,i+1]=HoughRadius
			UpdateImage(SecondRefl_HoughRadIm)
			}	
		If (ShowCrosscorImage==1)
			{
			UpdateImage(crosscorrSecond)
			}		 
		}
		
				
	If (XCenterThirdROI+YCenterThirdROI>0)
		{
				
		If (MatchAlgorithm==0) 
			{
			crosscorrThird=crosscorrelation(RefImage, ThirdRefl)
			IUImageFindMax(crosscorrThird, 0, 0, 2*ROI_radius, 2*ROI_radius, Third_x_shift, Third_y_shift, 1)
			Third_x_shift=-Third_x_shift
			Third_y_shift=-Third_y_shift
			}
		If(MatchAlgorithm==1)			//Circular Hough Transform
			{
			crosscorrThird=self.AdaptedCircularHoughTransform(ThirdRefl, MinHoughRadius, MaxHoughRadius, HoughRadiusStep, HoughRadius)
			
			IUImageFindMax(crosscorrThird, 0, 0, 2*ROI_radius, 2*ROI_radius, Third_x_shift, Third_y_shift, 1)
			Third_x_shift=Third_x_shift
			Third_y_shift=Third_y_shift
			}
			
			ThirdReflCentrX=XCenterThirdROInew+Third_x_shift
			ThirdReflCentrY=YCenterThirdROInew+Third_y_shift
			Third_gx=ThirdReflCentrX-Zero_gx
			Third_gy=ThirdReflCentrY-Zero_gy
		
			If (abs(Third_x_shift)> Max_Shift || abs(Third_y_shift) > Max_Shift || sum(ThirdRefl)<Background)
				{
				Third_x_shift=0
				Third_y_shift=0
				Third_gx=0
				Third_gy=0
				}
					
		Third_g=sqrt(Third_gx*Third_gx+Third_gy*Third_gy)		
		Third_g_im[j,i,j+1,i+1]=Third_g
		
			If (AdaptiveModeFlag==1)
				
				{
					If (Third_x_shift>2) XCenterThirdROInew=XCenterThirdROInew+1
					If (Third_x_shift<2) XCenterThirdROInew=XCenterThirdROInew-1
					If (Third_y_shift>2) YCenterThirdROInew=YCenterThirdROInew+1
					If (Third_y_shift<2) YCenterThirdROInew=YCenterThirdROInew-1
					If (abs(XCenterThirdROInew-XCenterThirdROI)>Max_Shift ||  abs(YCenterThirdROInew-YCenterThirdROI)>Max_Shift || sum(ThirdRefl)<Background)
						{
							XCenterThirdROInew=XCenterThirdROI
							YCenterThirdROInew=YCenterThirdROI
						}	
			
				}
		Temp_im=InputStack[ThirdReflCentrX-ROI_radius,ThirdReflCentrY-ROI_radius,Slice, \
		ThirdReflCentrX+ROI_radius,ThirdReflCentrY+ROI_radius,Slice+1]
		Temp_im=tert((iradius<Diskradius), Temp_im,0)
		ThirdRefl_sum=sum(Temp_im)	
		
		Third_alpha=0
		If(abs(Third_g)>0)
			{
			Third_alpha=self.CalckulateAngle(Third_gx, Third_gy, Third_g)
			}
		
		If (Savetxt==1)
			{
			WriteFile(fileID, " "+Third_g+" "+Third_gx+" "+Third_gy+" "+ThirdRefl_sum+" "+ Third_alpha)
			}
		
		UpdateImage(Third_g_im)
		If (ShowXYShift==1)
			{
			ThirdRefl_Xshift[j,i,j+1,i+1]=abs(ThirdReflCentrX)
			ThirdRefl_Yshift[j,i,j+1,i+1]=abs(ThirdReflCentrY)
			UpdateImage(ThirdRefl_Xshift)
			UpdateImage(ThirdRefl_Yshift)
			}
		If (ShowAlpha==1)
			{
			ThirdRefl_Alpha[j,i,j+1,i+1]=Third_alpha
			UpdateImage(ThirdRefl_Alpha)
			}	
		If (ShowSum==1)
			{	
			ThirdRefl_SumIm[j,i,j+1,i+1]=ThirdRefl_sum
			UpdateImage(ThirdRefl_SumIm)
			}
		If (ShowHoughRad==1 && MatchAlgorithm==1)
			{	
			ThirdRefl_HoughRadIm[j,i,j+1,i+1]=HoughRadius
			UpdateImage(ThirdRefl_HoughRadIm)
			}
		If (ShowCrosscorImage==1)
			{
			UpdateImage(crosscorrThird)
			}		 
		}
	

	Slice++
	
	}
	
}
If (Savetxt==1)
	{
	CloseFile(fileID)
	}

	If (rememberROIFlag==0) self.clearROI(InputStack,0)
}	
	

void CalculateIntensityTaskPushed(object self) { StartThread( self, "CalculateIntensity" ); } 
void CalculateShiftTaskPushed(object self) { StartThread( self, "CalculateShift" ); } 
	

// Creates the Settings dialog box

taggroup MakeSettingsBox(object self)
	{
		taggroup settingsbox_items
		taggroup settingsbox=dlgcreatebox(" Filters ", settingsbox_items)
		settingsbox.dlginternalpadding(10,0).dlgexternalpadding(0,0)


		taggroup Filter_items

		// Create the Sobel group 
		taggroup Sobelradio_items
		
		number Sobelradio
		number SobelBoxVal
		taggroup Sobelcheckbox=dlgcreatecheckbox("Sobel", SobelBoxVal).dlgidentifier("Sobelbox").dlganchor("West").dlgexternalpadding(0,0).DLGValue(1)
		taggroup spacer=dlgcreatelabel("").dlgexternalpadding(0,-7)
			
		taggroup Sobelradiolist=dlgcreateradiolist(Sobelradio_items, Sobelradio).dlgidentifier("Sobelradio")
		Sobelradio_items.dlgaddelement(dlgcreateradioitem("Magnitude",0))
		Sobelradio_items.dlgaddelement(dlgcreateradioitem("Phase",1))
				
		number ILLowVal
		taggroup ILLowBox=dlgcreatecheckbox("ILLowPass", ILLowVal).dlgidentifier("ILLowBox").dlganchor("West").dlgexternalpadding(0,0).DLGValue(1)
		
		taggroup Sobelradiogroup=dlggroupitems(ILLowBox, Sobelcheckbox).dlgidentifier("Sobelradiogroup").dlganchor("North").dlgexternalpadding(4,3)
		//taggroup Sobelradiogroup=dlggroupitems(ILLowBox, Sobelcheckbox, Sobelradiolist).dlgidentifier("Sobelradiogroup").dlganchor("North").dlgexternalpadding(4,3)
		
		taggroup ButterWorthlabel=dlgcreatelabel("B'worth Order \n from 1 to 6:")
		number ButterWorthBoxVal
		taggroup ButterWorthCheckBox=dlgcreatecheckbox("B'worth", ButterWorthBoxVal).dlgidentifier("BWorthbox").dlganchor("West").dlgexternalpadding(0,0).DLGValue(0)
		number ButterWorthOrder
		taggroup ButterWorthOrderfield=dlgcreaterealfield(ButterWorthOrder, 8, 0).dlgchangedmethod("BWchanged").dlgidentifier("Bworth").dlganchor("West").DLGValue(1)
		
		taggroup Filter_items2
		Filter_items2=dlggroupitems(  ButterWorthCheckBox, ButterWorthlabel, ButterWorthOrderfield).dlgtablelayout(1,3,0)
		
		Filter_items=dlggroupitems( Sobelradiogroup, Filter_items2).dlgtablelayout(2,3,0)
		
		settingsbox_items.dlgaddelement(Filter_items)
		
		return settingsbox
	}
	
	TagGroup MakeAlgorithmBox(object self)
	{
		TagGroup AlgorithmBox_items
		TagGroup AlgorithmBox=dlgcreatebox(" Matching algorithm", Algorithmbox_items)
		AlgorithmBox.dlginternalpadding(10,0).dlgexternalpadding(0,0)

		// Create the Algorithm group 
		taggroup AlgorithmRadio_items
		
		number Algorithmradio
		number AlgorithmBoxVal
			
		taggroup Algorithmradiolist=dlgcreateradiolist(Algorithmradio_items, Algorithmradio).dlgidentifier("Algorithmradio")
		Algorithmradio_items.dlgaddelement(dlgcreateradioitem("CrossCorelation",0))
		Algorithmradio_items.dlgaddelement(dlgcreateradioitem("Circular Hough Transform",1))
		
		taggroup HuoghRadiusLabel=dlgcreatelabel("Huogh radius (min; max; step)")
		
		number MinRadiusNumber
		If(MinRadiusNumber<0) MinRadiusNumber=0
		taggroup MinRadiusField=dlgcreaterealfield(MinRadiusNumber, 6, 1).dlgidentifier("MinRadiusField").DLGValue(10)	
		number MaxRadiusNumber
		If(MaxRadiusNumber<=0) MaxRadiusNumber=1
		taggroup MaxRadiusField=dlgcreaterealfield(MaxRadiusNumber, 6, 1).dlgidentifier("MaxRadiusField").DLGValue(12)
		number StepNumber
		If(StepNumber<=0) StepNumber=1
		taggroup StepField=dlgcreaterealfield(StepNumber, 6, 1).dlgidentifier("StepField").DLGValue(0.1)
		
		taggroup RadiusGroup=dlggroupitems( MinRadiusField, MaxRadiusField, StepField).dlgtablelayout(3,1,0).dlganchor("west").dlgexternalpadding(4,3)
		
		AlgorithmBox_items.dlgaddelement(Algorithmradiolist)
		AlgorithmBox_items.dlgaddelement(HuoghRadiusLabel)
		AlgorithmBox_items.dlgaddelement(RadiusGroup)
		
		return AlgorithmBox
	}
	TagGroup MakeOutputBox (object self)
	{
		TagGroup OutputBox_Items
		TagGroup OutputBox=dlgcreatebox(" Outputs ", outputbox_items)
		
		number ShowOneRowVal
		taggroup ShowOneRowCheckBox=dlgcreatecheckbox("Calculate only One Row", ShowOneRowVal).dlgidentifier("ShowOneRowBox").dlganchor("West").dlgexternalpadding(0,0).DLGValue(1)

		number ShowImageBoxVal
		taggroup ShowImageCheckBox=dlgcreatecheckbox("Show Images Processing", ShowImageBoxVal).dlgidentifier("ShowImageBox").dlganchor("West").dlgexternalpadding(0,0).DLGValue(1)
			
		number ShowRAWImageBoxVal
		taggroup ShowRAWImageCheckBox=dlgcreatecheckbox("Show RAW Images", ShowRAWImageBoxVal).dlgidentifier("ShowRAWImageBox").dlganchor("West").dlgexternalpadding(0,0).DLGValue(0)
		
		number ShowCrosscorImageBoxVal
		taggroup ShowCrosscorImageCheckBox=dlgcreatecheckbox("Show Crosscorelated Images", ShowCrosscorImageBoxVal).dlgidentifier("ShowCrosscorImageBox").dlganchor("West").dlgexternalpadding(0,0).DLGValue(0)
		
		number ShowXYShiftBoxVal
		taggroup ShowXYShiftCheckBox=dlgcreatecheckbox("Show gx,gy-Images", ShowXYShiftBoxVal).dlgidentifier("ShowXYShiftBox").dlganchor("West").dlgexternalpadding(0,0).DLGValue(0)
		
		number ShowAlphaBoxVal
		taggroup ShowAlphaCheckBox=dlgcreatecheckbox("Show Alpha", ShowAlphaBoxVal).dlgidentifier("ShowAlphaBox").dlganchor("West").dlgexternalpadding(0,0).DLGValue(1)
		
		number ShowSumBoxVal
		taggroup ShowSumCheckBox=dlgcreatecheckbox("Show Amplitudes", ShowSumBoxVal).dlgidentifier("ShowSumBox").dlganchor("West").dlgexternalpadding(0,0).DLGValue(1)
		
		number ShowHoughRadBoxVal
		taggroup ShowHoughRadCheckBox=dlgcreatecheckbox("Show Hough radius", ShowHoughRadBoxVal).dlgidentifier("ShowHoughRadBox").dlganchor("West").dlgexternalpadding(0,0).DLGValue(1)
		
		number SavetxtBoxVal
		taggroup SavetxtCheckBox=dlgcreatecheckbox("Save as .txt", SavetxtBoxVal).dlgidentifier("SavetxtBox").dlganchor("West").dlgexternalpadding(0,0).DLGValue(0)
		
		outputbox_items.dlgaddelement(ShowOneRowCheckBox)
		outputbox_items.dlgaddelement(ShowImageCheckBox)
		outputbox_items.dlgaddelement(ShowRAWImageCheckBox)
		outputbox_items.dlgaddelement(ShowCrosscorImageCheckBox)
		outputbox_items.dlgaddelement(ShowXYShiftCheckBox)
		outputbox_items.dlgaddelement(ShowAlphaCheckBox)
		outputbox_items.dlgaddelement(ShowSumCheckBox)
		outputbox_items.dlgaddelement(ShowHoughRadCheckBox)
		outputbox_items.dlgaddelement(SavetxtCheckBox)
		
		return outputbox
	}
	

taggroup makeGlobalsettingsbox(object self)
	{
		taggroup Globalsettingsbox_items

		taggroup Globalsettings=dlgcreatebox("Reconstructed Image", Globalsettingsbox_items).dlginternalpadding(5,5).dlgexternalpadding(3,3)
		taggroup x_sizefieldlabel=dlgcreatelabel(" x size")
		taggroup Y_sizefieldlabel=dlgcreatelabel("   y size")
		taggroup shiftfieldlabel=dlgcreatelabel("Max shift in pix.")
		taggroup Diskradiusfieldlabel=dlgcreatelabel("Disc radius in pix.")
		taggroup spacer=dlgcreatelabel("  ").dlgexternalpadding(6,-6)
		
		number x_sizenumber
		if(x_sizenumber<0) x_sizenumber=0
		taggroup x_sizefield=dlgcreaterealfield(x_sizenumber, 6, 1).dlgchangedmethod("x_sizefieldchanged").dlgidentifier("x_sizefield").DLGValue(RecImg_XSize)
		
		number y_sizenumber
		if(y_sizenumber<0) y_sizenumber=0
		taggroup y_sizefield=dlgcreaterealfield(y_sizenumber, 6, 1).dlgchangedmethod("y_sizefieldchanged").dlgidentifier("y_sizefield").DLGValue(RecImg_YSize)
		
		taggroup size_group=dlggroupitems( x_sizefieldlabel, x_sizefield, Y_sizefieldlabel, y_sizefield).dlgtablelayout(4,1,0).dlganchor("west")

		Globalsettingsbox_items.dlgaddelement(size_group)
		
		return Globalsettings
	}
	
	taggroup makeCBEDparametersbox(object self)
	{
		taggroup CBEDparametersbox_items

		taggroup CBEDparameters=dlgcreatebox("CBED parameters", CBEDparametersbox_items).dlginternalpadding(22,3).dlgexternalpadding(2,2)

		taggroup shiftfieldlabel=dlgcreatelabel("Max shift in pix.")
		taggroup Diskradiusfieldlabel=dlgcreatelabel("Disc radius in pix.")
		taggroup spacer=dlgcreatelabel("  ").dlgexternalpadding(6,-6)
		
	
		number shiftnumber
		if(shiftnumber<0) shiftnumber=0
		taggroup shiftfield=dlgcreaterealfield(shiftnumber, 6, 1).dlgchangedmethod("shiftfieldchanged").dlgidentifier("shiftfield").DLGValue(Max_Shift)
		
		number Diskradiusnumber
		if(Diskradiusnumber<0) Diskradiusnumber=0
		taggroup Diskradiusfield=dlgcreaterealfield(Diskradiusnumber, 6, 1).dlgchangedmethod("Diskradiusfieldchanged").dlgidentifier("Diskradiusfield").DLGValue(DiskRadius)
		
		
		
		number refsliceBoxVal
		taggroup refsliceCheckBox=dlgcreatecheckbox("Use reference slice", refsliceBoxVal).dlgidentifier("refsliceBox").dlganchor("east").dlgexternalpadding(0,0).DLGValue(0)
		
		
		
		
		taggroup shift_group=dlggroupitems(shiftfieldlabel, shiftfield).dlgtablelayout(2,1,0).dlganchor("north")
		taggroup disk_group=dlggroupitems(Diskradiusfieldlabel, Diskradiusfield).dlgtablelayout(2,1,0).dlganchor("north")

		CBEDparametersbox_items.dlgaddelement(disk_group)
		CBEDparametersbox_items.dlgaddelement(shift_group)
		
		
		return CBEDparameters
	}
	
//*****ROI*****	
	taggroup makeROIbox(object self)
	{
		taggroup ROIbox_items

		taggroup ROIbox=dlgcreatebox(" ROI ", ROIbox_items).dlginternalpadding(3,5).dlgexternalpadding(3,3)
		
		number refslicenumber
		if(refslicenumber<0) refslicenumber=0
		taggroup recfieldlabel=dlgcreatelabel("Reference slise")
		taggroup refslicefield=dlgcreaterealfield(refslicenumber, 6, 1).dlgchangedmethod("refslicefieldchanged").dlgidentifier("refslicefield").DLGValue(1)
		
		TagGroup ReferenceROIButton=dlgcreatepushbutton("Exp. Ref. Disk", "ReferenceROIButtonpushed").dlgidentifier("ReferenceROIButton")
		TagGroup ZeroROIButton=dlgcreatepushbutton("000 ROI", "ZeroROIButtonpushed").dlgidentifier("ZeroROIButton")
		TagGroup FirstROIButton=dlgcreatepushbutton("First ROI", "FirstROIButtonpushed").dlgidentifier("FirstROIButton")
		TagGroup SecondROIButton=dlgcreatepushbutton("Second ROI", "SecondROIButtonpushed").dlgidentifier("SecondROIButton")
		TagGroup ThirdROIButton=dlgcreatepushbutton("Third ROI", "ThirdROIButtonpushed").dlgidentifier("ThirdROIButton")
		TagGroup ClearROIButton=dlgcreatepushbutton("Clear ROI", "ClearROIButtonpushed").dlgidentifier("ClearROIButton")
		TagGroup BackgroundROIButton=dlgcreatepushbutton("Background as ROI", "BackgroundROIButtonpushed").dlgidentifier("BackgroundROIButton")
		
		number AdaptiveBoxVal
		TagGroup AdaptiveCheckBox=dlgcreatecheckbox("Use Adaptive ROI mode", AdaptiveBoxVal).dlgidentifier("AdaptiveBox").dlganchor("west").dlgexternalpadding(0,0).DLGValue(0)
		
		number BackgroundMultipl
		if(BackgroundMultipl<0) BackgroundMultipl=0
		TagGroup BackgroundMultiplField=dlgcreaterealfield(BackgroundMultipl, 6, 1).dlgchangedmethod("BackgroundMultiplfieldchanged").dlgidentifier("BackgroundMultiplfield").DLGValue(1)
		
		number BackgroundValue
		TagGroup BackgroundValueField=dlgcreaterealfield(BackgroundValue, 6, 1).dlgchangedmethod("BackgroundValuefieldchanged").dlgidentifier("Backgroundvaluefield").DLGValue(100)
		
		number Backgroundradio
		taggroup Backgroundradio_items
		taggroup Backgroundradiolist=dlgcreateradiolist(Backgroundradio_items, Backgroundradio).dlgidentifier("Backgroundradio")
		Backgroundradio_items.dlgaddelement(dlgcreateradioitem("Background multiplier",0))
		Backgroundradio_items.dlgaddelement(dlgcreateradioitem("set Background value:",1))
		
		number rememberROIBoxVal
		taggroup rememberROICheckBox=dlgcreatecheckbox("remember ROI coordinates", rememberROIBoxVal).dlgidentifier("rememberROIBox").dlganchor("West").dlgexternalpadding(0,0).DLGValue(1)
	
		taggroup ReferenceFieldgroup=dlggroupitems(recfieldlabel, refslicefield).dlgtablelayout(2,1,0)
		taggroup Buttongroup=dlggroupitems(ZeroROIButton, FirstROIButton,SecondROIButton, ThirdROIButton).dlgtablelayout(2,2,0)
		taggroup BackgroundFieldgroup=dlggroupitems(BackgroundMultiplField, BackgroundValueField).dlgtablelayout(1,2,0)
		taggroup Backgroundgroup=dlggroupitems(Backgroundradiolist, BackgroundFieldgroup).dlgtablelayout(2,1,0)
		

		ROIbox_items.dlgaddelement(ReferenceROIButton)
		ROIbox_items.dlgaddelement(ReferenceFieldgroup)
		ROIbox_items.dlgaddelement(Buttongroup)
		ROIbox_items.dlgaddelement(AdaptiveCheckBox)
		ROIbox_items.dlgaddelement(BackgroundROIButton)
		ROIbox_items.dlgaddelement(Backgroundgroup)
		ROIbox_items.dlgaddelement(ClearROIButton)
		ROIbox_items.dlgaddelement(rememberROICheckBox)
		
		
		
		return ROIbox
	}
	
// Creat the Alignment button

TagGroup MakeCalculateBox(object self)
	{
	taggroup box_items
		taggroup CalculateIntensityButton=dlgcreatepushbutton("Calculate intensity", "CalculateIntensityTaskPushed").dlgidentifier("CalculateIntensityButton").dlgexternalpadding(0,0).dlginternalpadding(7,0)
		taggroup CalculateShiftButton=dlgcreatepushbutton("Run Process", "CalculateShiftTaskPushed").dlgidentifier("CalculateShiftButton").dlgexternalpadding(0,0).dlginternalpadding(7,0)
		taggroup legend=dlgcreatelabel("Serhii Kryvyi, v1.2, 21.08.2018")
		taggroup Buttons1=dlggroupitems(CalculateShiftButton, legend).dlgtablelayout(1,2,0)
		
		return Buttons1
		
	}

taggroup MakeScaningDifractionDialog(object self)
	{
		TagGroup dialog_items;	
		TagGroup dialog = DLGCreateDialog("Scaning Diffraction", dialog_items)
		
		//Serg
		taggroup Globalsettings=self.makeGlobalsettingsbox()
		dialog_items.dlgaddelement(Globalsettings)
		
		taggroup CBEDparameters=self.makeCBEDparametersbox()
		dialog_items.dlgaddelement(CBEDparameters)
	
		taggroup ROIbox=self.makeROIbox()
		dialog_items.dlgaddelement(ROIbox)

		taggroup settingsbox=self.makesettingsbox()
		dialog_items.dlgaddelement(settingsbox)
		
		taggroup AlgorithmBox=self.MakeAlgorithmBox()
		dialog_items.dlgaddelement(AlgorithmBox)
		
		taggroup outputbox=self.makeoutputbox()
		dialog_items.dlgaddelement(outputbox)
		
		taggroup CalculateBox=self.MakeCalculateBox()
		dialog_items.dlgaddelement(CalculateBox)

		return dialog
	}

//*****Copy from Stack Alignment*****
object init(object self)
		{
			return self
		}
		
// The constructor - builds the dialog
ScaningDifractionDialog(object self)
	{
		// Configure the positioning in the top right of the application window
		self.init( self.makeScaningDifractionDialog() )
	}
	
// The destructor
~ScaningDifractionDialog(object self)
	{	// frees up memory when the dialog is closed
	}	
	
} 


void Main()
	{
		object UserInterface = Alloc(ScaningDifractionDialog).init() //initialization
		UserInterface.display("CBED series")
		
		Return
	}


// Call the Main function

main()





