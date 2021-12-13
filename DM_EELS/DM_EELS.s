//----------------------------------------------------------------
// DM_EELS.s
// Script by K. Morawiec
//----------------------------------------------------------------

// function declarations
void CreateMainDialog(Object dialog_frame, TagGroup exposure_field, TagGroup n_frames_field);
void ShowParams(Object acq_params);
void GetDispersionAndOrigin(Number disp_opt, Number &dispersion, Number &origin);
void AdjustZLP(Object cam, Object acq_params);
void StartAcquisition();

// global variables
Number exposure = 0.001
Number n_frames = 10
Number file_num = 0

TagGroup exposure_field
TagGroup n_frames_field

Object main_dialog

//----------------------------------------------------------------

class MainDialog : uiframe
{	
	void ButtonResponse(Object self)
	{
		exposure = DLGGetValue(exposure_field)
		n_frames = DLGGetValue(n_frames_field)
		StartAcquisition()
		return
	}
}

//----------------------------------------------------------------

void CreateMainDialog(Object dialog_frame, TagGroup exposure_field, TagGroup n_frames_field)
{
	TagGroup position
	position = DLGBuildPositionFromApplication()
	position.TagGroupSetTagAsTagGroup("Width", DLGBuildAutoSize())
	position.TagGroupSetTagAsTagGroup("Height", DLGBuildAutoSize())
	position.TagGroupSetTagAsTagGroup("X", DLGBuildRelativePosition("Inside", 0))		
	position.TagGroupSetTagAsTagGroup("Y", DLGBuildRelativePosition("Inside", 0))

	TagGroup dialog, dialog_items
	dialog = DLGCreateDialog("DM EELS", dialog_items).DLGPosition(position)
	
	TagGroup exposure_label = DLGCreateLabel("Exposure [s]")
	TagGroup exposure_group = DLGGroupItems(exposure_label, exposure_field)

	TagGroup n_frames_label = DLGCreateLabel("Number of frames")
	TagGroup n_frames_group = DLGGroupItems(n_frames_label, n_frames_field)
	
	TagGroup start_button = DLGCreatePushButton("Start", "ButtonResponse")
	
	exposure_group.DLGExternalPadding(20, 5)
	n_frames_group.DLGExternalPadding(20, 5)
	start_button.DLGExternalPadding(20, 5)
	
	dialog_items.DLGAddElement(exposure_group)
	dialog_items.DLGAddElement(n_frames_group)
	dialog_items.DLGAddElement(start_button)

	dialog_frame = alloc(MainDialog).init(dialog)
	dialog_frame.Display("DM EELS")
}

//----------------------------------------------------------------

void ShowParams(Object acq_params)
{
	Number processing
	Number top, left, bottom, right
	Number bin_x, bin_y
	
	processing = CM_GetProcessing(acq_params)
	CM_GetCCDReadArea(acq_params, top, left, bottom, right)
	CM_GetBinning(acq_params, bin_x, bin_y)
	
	String prc_str
	if (processing == 1) prc_str = "no dark/gain correction"
	else if (processing == 2) prc_str = "dark correction only"
	else prc_str = "dark and gain correction"
	
	String dcr_str
	if (CM_GetDoContinuousReadout(acq_params)) dcr_str = "yes"
	else dcr_str = "no"
	
	Result("\nAcquisition parameters:\n" + \
		   "Processing = " + prc_str + "\n" + \
	       "Exposure = " + CM_GetExposure(acq_params) + "\n" + \
           "Read area = " + left + ", " + top + ", " + right + ", " + bottom + "\n" + \
	       "CCD width = " + (right-left) + "\n" + \
	       "CCD height = " + (bottom-top) + "\n" + \
	       "Binning X = " + bin_x + "\n" + \
	       "Binning Y = " + bin_y + "\n" + \
	       "Read mode = " + CM_GetReadMode(acq_params) + "\n" + \
	       "Do continuous readout? " + dcr_str + "\n" + \
	       "Quality level = " + CM_GetQualityLevel(acq_params) + "\n\n")
}

//----------------------------------------------------------------

void GetDispersionAndOrigin(Number disp_opt, Number &dispersion, Number &origin)
{
	if (disp_opt == 1)
	{
		dispersion = 1
		origin = -200
	}
	else if (disp_opt == 2)
	{
		dispersion = 0.5
		origin = -100
	}
	else if (disp_opt == 3)
	{
		dispersion = 0.25
		origin = -50
	}
	else if (disp_opt == 4)
	{
		dispersion = 0.1
		origin = -20
	}
	else if (disp_opt == 5)
	{
		dispersion = 0.05
		origin = -10
	}
	else if (disp_opt == 6)
	{
		dispersion = 0.025
		origin = -5
	}
	else if (disp_opt == 7)
	{
		dispersion = 0.001
		origin = -2
	}
	return
}

//----------------------------------------------------------------

void AdjustZLP(Object cam, Object acq_params)
{
	Number top, left, bottom, right
	CM_GetCCDReadArea(acq_params, top, left, bottom, right)

	image ccd_img := IntegerImage (" " , 4 , 1 , right-left , bottom-top)
	Image zlp2D := IntegerImage (" " , 4 , 1 , right-left , bottom-top)
	Image zlp1D := RealImage (" " , 4 , right-left , 1)

	Number adjust = IFCGetEnergyAdjust()
	Number max_val, max_x, max_y, i

	while (1)
	{
		zlp1D = 0
		zlp2D = 0
		delay(60)
		
		ccd_img = CM_AcquireImage(cam, acq_params)
		zlp2D = CCD
		zlp1D[icol, 0] += zlp2D[0, 0, i, right-left, bottom-top, i+1]
		
		max_val = max (zlp1D, max_x, max_y)
		if ((max_x-10/dispersion) <= 3 ) break
		if (ShiftDown()) Exit(0)

		adjust -= (max_x-10/dispersion)*dispersion
		IFCSetEnergyAdjust(adjust)
	}
}

//----------------------------------------------------------------

void StartAcquisition()
{
	// Image Filter setup
	if (!IFSetUpCommunication())
	{
		OkDialog("Image Filter not found")
		Exit(0)
	}
	if (!IFIsInEELSMode()) 
	{
		OkDialog("Image Filter must be in spectroscopy mode")
		Exit(0)
	}
	Result("Image Filter is ok\n")

	Object cam_mgr = CM_GetCameraManager()
	Object cam_list = CM_GetCameras(cam_mgr)
	Object cam

	Result("\nExisting cameras:\n")
	foreach (cam; cam_list)      
		Result(CM_GetCameraName(cam) + "\n")
		
	cam = CM_GetCurrentCamera()
	Result("\nCurrent camera: <" + CM_GetCameraName(cam) + ">")

	Result("\nStatus: ")
	Number inserted = CM_GetCameraInserted(cam)
	if (inserted) Result("inserted\n")
	else
	{
		Result("not inserted\n\nCamera must be inserted to continue\n")
		Exit(0)
	}

	// acquisition parameters
	Number processing = 3		// 1 - no dark/gain correction
								// 2 - dark correction
								// 3 - dark and gain correction
	Number exposure = 0.001
	Number bin_x = 1
	Number bin_y = 1
	Number left = 0
	Number top = 904
	Number right = 2048
	Number bottom = 1144
	Number do_cont_readout = 1	// 0 or 1

	Object acq_params = CM_CreateAcquisitionParameters(cam, processing, exposure, bin_x, bin_y, top, left, bottom, right)
	CM_SetDoContinuousReadout(acq_params, do_cont_readout)

	ShowParams(acq_params)

	//---------------------------------------------------------------------------

	Number disp_opt, dispersion, origin	
	String energy_units = "eV"
	String intensity_units = "e-"

	disp_opt = IFCGetActiveDispersion()

	GetDispersionAndOrigin(disp_opt, dispersion, origin)
	Result("Dispersion = " + dispersion + " eV/ch\n" + \
		   "Origin = " + origin + " eV\n\n")
	
	// set ZLP to zero (?)
	//AdjustZLP(cam, acq_params)

	Image ccd_img = CM_CreateImageForAcquire(cam, acq_params, "CCD Image")
	Image spectra := RealImage("", 4, right-left, n_frames)
	Image spec_sum := RealImage("", 4, right-left, 1)

	Result("Starting acquisition...\n")

	// acquisition loop

	for (Number i=0; i<n_frames; ++i)
	{
		ccd_img = CM_AcquireImage(cam, acq_params)
		//ccd_img = SSCUnprocessedBinnedAcquire(exposure, bin_x, top, left, bottom, right)
		//SSCGainNormalizedBinnedAcquireInPlace(ccd_img, exposure, bin_x, top, left, bottom, right)
		//CM_AcquireInplace(ccd_img, cam, processing, exposure, bin_x, bin_y, top, left, bottom, right)
		
		spectra[icol, i] += ccd_img
	}

	AlignZLP(spectra)

	for (Number i=0; i<n_frames; ++i)
	{
		spec_sum += spectra[icol, i]
	}
	ImageSetDimensionCalibration(spec_sum, 0, origin, dispersion, energy_units, 0)
	ImageSetIntensityOrigin(spec_sum, 0)
	//ImageSetIntensityScale(spec_sum, 1)
	ImageSetIntensityUnitString(spec_sum, intensity_units)

	file_num++;
	
	String write_path = GetApplicationDirectory(2, 0)
	String dm3_file = write_path + "eels_" + file_num + "_n" + n_frames + "_exp" + exposure + ".dm3"

	SaveAsGatan(spec_sum, dm3_file)
	ShowImage(spec_sum)

	Result("\nAll done\n")
}

//---------------------------------------------------------------------------

// create GUI

exposure_field = DLGCreateRealField(exposure, 10, 1)
n_frames_field = DLGCreateIntegerField(n_frames, 10)

CreateMainDialog(main_dialog, exposure_field, n_frames_field)