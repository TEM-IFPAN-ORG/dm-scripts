//--------------------------------------------------------------------
// AutoScannDiff v5.3
// Script by K. Morawiec and S. Kryvyi
// Based on "CBED stack process" by S. Kryvyi
//--------------------------------------------------------------------

// Script for automation of scanning diffraction procedure.
// It can be used to acquire diffraction patterns in STEM mode for NxM positions of electron beam.
// For each beam position a low exposure image is acquired first to check if the intensity
// of central beam exceeds some reference threshold value (i.e. if beam is located in vacuum).
// If not (i.e. if beam propagates through sample), then acquisition is repeated with proper
// exposure time and the image is added to the stack.

// Main dialog
class AutoScanDiffDialog : UIFrame
{
	// Method called when "Acquire ref. image" button is pressed.
	// Acquire low exposure reference image for beam located in vacuum area.
	// Reference image can then be used to mark central beam with ROI.
	void AcquireRefImageButtonPushed(object self)
	{
		object cam_mgr = CM_GetCameraManager()
		object cam_list = CM_GetCameras(cam_mgr)
		object camera
		
		// List available cameras.
		/*
		Result("\nAvailable cameras:\n")
		foreach(camera; cam_list)
			Result(CM_GetCameraName(camera) + "\n")
		*/
		
		// Ask user if currently selected camera should be used.
		camera = CM_GetCurrentCamera()
		if(!OkCancelDialog(CM_GetCameraName(camera) + " will be used. Are you sure?"))
		{
			ShowAlert("Select proper camera and try again.", 2)
			return
		}
		
		// Check if selected camera is inserted.
		if(!CM_GetCameraInserted(camera))
		{
			ShowAlert("Insert camera and try again.", 2)
			return
		}
		
		// Retrieve settings for the "RECORD" mode camera setup and
		// change some of the acquisition parameters.
		
		number processing = 3		// 1 - no dark/gain correction
									// 2 - dark correction
									// 3 - dark and gain correction
		number low_exp_time = DlgGetValue(self.LookUpElement("LowExpTime"))
		number bin_x = 4
		number bin_y = 4
		
		object acq_params = CM_GetCameraAcquisitionParameterSet(camera, "Imaging", "Acquire", "Record", 0)
		//object acq_params = CM_CreateAcquisitionParameters_FullCCD(camera, processing, low_exp_time, bin_x, bin_y)
		
		/*
		number top, left, bottom, right
		CM_GetCCDReadArea(acq_params, top, left, bottom, right)

		top /= bin_y
		bottom /= bin_y
		left /= bin_x
		right /= bin_x
		*/
		
		CM_SetProcessing(acq_params, processing)
		CM_SetExposure(acq_params, low_exp_time)
		CM_SetBinning(acq_params, bin_x, bin_y)
		
		// Acquire reference image with low exposure time.
		
		image ref_image = CM_CreateImageForAcquire(camera, acq_params, "Reference image")
		ConvertToLong(ref_image)
		
		CM_AcquireImage(camera, acq_params, ref_image)
		//ref_image = SSCUnprocessedBinnedAcquire(low_exp_time, bin_x, top, left, bottom, right)
		//SSCGainNormalizedBinnedAcquireInPlace(ref_image, low_exp_time, bin_x, top, left, bottom, right)
		//CM_AcquireInplace(ref_image, camera, processing, low_exp_time, bin_x, bin_y, top, left, bottom, right)
		ShowImage(ref_image)
	}
	
	// Method called when "Set central beam ROI" button is pressed.
	// Use reference image with central beam indicated by ROI to determine
	// threshold value for acquisition of subsequent images.
	void SetCentralBeamROIButtonPushed(object self)
	{
		image ref_image := GetFrontImage()
		imagedisplay ref_display = ref_image.ImageGetImageDisplay(0)
		number t, l, b, r
		ROI central_beam_roi
		string roi_name
		number threshold_factor = DlgGetValue(self.LookUpElement("ThresholdFactor"))
		number ref_threshold

		try
		{
			central_beam_roi = ImageDisplayLookupROI(ref_display, roi_name)
			ROIGetRectangle(central_beam_roi, t, l, b, r)	
		}
		catch
		{
			ShowAlert("Use ROI to mark central beam.", 2)
			return
		}
		
		ref_threshold = threshold_factor * integrate(ref_image[t, l, b, r])
			
		// Save reference threshold value and coordinates of area containing central beam in memory.
		SetPersistentNumberNote("ref_t", t)
		SetPersistentNumberNote("ref_l", l)
		SetPersistentNumberNote("ref_b", b)
		SetPersistentNumberNote("ref_r", r)
		SetPersistentNumberNote("ref_threshold", ref_threshold)
		
		OkDialog("Threshold value and ROI coordinates were saved.")
	}
	
	// Method called when "Get" button is pressed.
	// Display position of electron beam in STEM mode.
	void GetBeamPosButtonPushed(object self)
	{
		InitTIA()
		number beam_x, beam_y
		GetBeamPosition(beam_x, beam_y)
		
		self.LookUpElement("BeamX").DlgValue(beam_x)
		self.LookUpElement("BeamY").DlgValue(beam_y)
		ReleaseTIA()
	}
	
	// Method called when "Set" button is pressed.
	// Set position of electron beam in STEM mode.
	void SetBeamPosButtonPushed(object self)
	{
		InitTIA()
		number beam_x = DlgGetValue(self.LookUpElement("BeamX"))
		number beam_y = DlgGetValue(self.LookUpElement("BeamY"))
		
		SetBeamPosition(beam_x, beam_y)
		ReleaseTIA()
	}
	
	// Method called when "Start auto scan" button is pressed.
	// Start procedure of auto scanning diffraction, i.e. acquire diffraction patterns in STEM
	// for NxM positions of electron beam. For each beam position acquire low exposure image and
	// then, if the intensity of central beam does not exceed threshold value, repeat acquisition
	// for "normal" exposure time.
	void StartAutoScanButtonPushed(object self)
	{
		number ref_threshold = 0
		number check_ref_threshold = GetPersistentNumberNote("ref_threshold", ref_threshold)
		
		// Check if reference image from vacuum was registered and threshold value was determined.
		if(!check_ref_threshold)
		{
			ShowAlert("Acquire reference image (in vacuum) to determine central beam position and threshold exposure.", 2)
			return
		}
		
		// Get coordinates of the area which should contain central beam.
		number ref_t, ref_l, ref_b, ref_r
		GetPersistentNumberNote("ref_t", ref_t)
		GetPersistentNumberNote("ref_l", ref_l)
		GetPersistentNumberNote("ref_b", ref_b)
		GetPersistentNumberNote("ref_r", ref_r)
		
		number img_width, img_height
		number px_width, px_height
		string px_units
		number n_rows = DlgGetValue(self.LookUpElement("NumOfRows"))
		number n_cols = DlgGetValue(self.LookUpElement("NumOfCols"))
		number n_images = n_rows * n_cols
		number beam_x0, beam_y0
		number beam_x, beam_y
		number step_x, step_y
		number roi_w, roi_h
		number low_exp_time = DlgGetValue(self.LookUpElement("LowExpTime"))
		number norm_exp_time = DlgGetValue(self.LookUpElement("NormExpTime"))
		number processing = 3
		number bin_x = 4
		number bin_y = 4
		
		object cam_mgr = CM_GetCameraManager()
		object cam_list = CM_GetCameras(cam_mgr)
		object camera
		
		// List available cameras.
		/*
		Result("\nAvailable cameras:\n")
		foreach(camera; cam_list)
			Result(CM_GetCameraName(camera) + "\n")
		*/
		
		// Ask user if currently selected camera should be used.
		camera = CM_GetCurrentCamera()
		if(!OkCancelDialog(CM_GetCameraName(camera) + " will be used. Are you sure?"))
		{
			ShowAlert("Select proper camera and try again.", 2)
			return
		}
		
		// Check if selected camera is inserted.
		if(!CM_GetCameraInserted(camera))
		{
			ShowAlert("Insert camera and try again.", 2)
			return
		}
		
		// Retrieve settings for the "Record"/"Search" mode of camera setup and
		// change some of the acquisition parameters.
		
		//object acq_params = CM_GetCameraAcquisitionParameterSet(camera, "Imaging", "Acquire", "Record", 0)
		object acq_params = CM_GetCameraAcquisitionParameterSet(camera, "Imaging", "View", "Search", 0)
		
		CM_SetProcessing(acq_params, processing)
		CM_SetBinning(acq_params, bin_x, bin_y)
		
		// Get/Set whether the readout should be optimized for continuous acquisition.
		//number do_cont_read = CM_GetDoContinuousReadout(acq_params)
		CM_SetDoContinuousReadout(acq_params, 1)
		
		// Get/Set whether the shutter should be closed during exposure.
		//number is_shutter_closed_during_exp = CM_GetShutterExposure(acq_params)
		CM_SetShutterExposure(acq_params, 0)
		
		// Get/Set whether the shutter should be closed during any delay between frames of a continuous readout.
		//number is_shutter_closed_between_frames = CM_GetShutterClosedBetweenFrames(acq_params)
		CM_SetShutterClosedBetweenFrames(acq_params, 0)
		
		//CM_CCD_GetSize(camera, img_width, img_height)
		//CM_CCD_GetPixelSize_um(camera, px_width, px_height)
		
		image diff_image = CM_CreateImageForAcquire(camera, acq_params, "Diff. image")
		GetSize(diff_image, img_width, img_height)
		image diff_stack = RealImage("Diff. stack", 4, img_width, img_height, n_images)
		image acq_image = CreateByteImage("Acquire image", n_cols, n_rows)
		
		ConvertToLong(diff_image)
		ConvertToLong(diff_stack)
		ConvertToByte(acq_image)
		
		// Get the scale of image dimensions (the size of pixel).
		px_width = ImageGetDimensionScale(diff_image, 0)
		px_height = ImageGetDimensionScale(diff_image, 1)
		px_units = ImageGetDimensionUnitString(diff_image, 0)
		
		// Initialize communication with TIA.
		InitTIA()
		
		// Get coordinates and size of the ROI marked in TIA.
		GetROI(beam_x0, beam_y0, roi_w, roi_h)
		step_x = roi_w / n_cols
		step_y = roi_h / n_rows
		
		number i = 0
		number beam_check = 0
		
		ShowImage(acq_image)
		ShowImage(diff_stack)
		
		for(number row=0; row<n_rows; row++)
		{
			for(number col=0; col<n_cols; col++)
			{	
				// Determine the new beam position in raster.
				beam_x = beam_x0 + (col + 0.5) * step_x
				beam_y = beam_y0 - (row + 0.5) * step_y
				
				// Set the new beam position and check if it is inside of the viewing area.
				beam_check = SetBeamPosition(beam_x, beam_y)
				if(!beam_check)
				{
					ShowAlert("Scanning terminated. Set the new beam position and try again.", 2)
					return
				}
				
				// Acquire first image with low exposure time.
				CM_SetExposure(acq_params, low_exp_time)
				CM_AcquireImage(camera, acq_params, diff_image)
				
				// Check if intensity of central beam exceeds threshold value or not
				// (i.e. if electron beam is located in vacuum area or in sample area).
				image central_beam = diff_image[ref_t, ref_l, ref_b, ref_r]
				
				if(integrate(central_beam) > ref_threshold)
				{
					continue
				}
				
				// Acquire proper image with "normal" exposure time.
				CM_SetExposure(acq_params, norm_exp_time)
				CM_AcquireImage(camera, acq_params, diff_image)
				
				// Add image to the stack. Modify acq_image to indicate if the image was acquired.
				diff_stack[0, 0, i, img_width, img_height, i+1] = diff_image
				acq_image[col, row] = 1
				
				UpdateImage(acq_image)
				UpdateImage(diff_stack)
				i++
			}
		}
		
		// End communication with TIA.
		ReleaseTIA()
		
		// Set x,y scale (and units) of the image stack.
		ImageSetDimensionScale(diff_stack, 0, px_width)
		ImageSetDimensionScale(diff_stack, 1, px_height)
		
		ImageSetDimensionUnitString(diff_stack, 0, px_units)
		ImageSetDimensionUnitString(diff_stack, 1, px_units)
		
		/*
		String write_path = GetApplicationDirectory(2, 0)
		String dm3_file = write_path + "diff_stack.dm3"
		
		SaveAsGatan(diff_stack, dm3_file)
		*/
		
		//ShowImage(acq_image)
		//ShowImage(diff_stack)
	}
	
	// Create dialog box with items related to acquisition of reference image in vacuum and
	// determination of threshold intensity.
	taggroup MakeReferenceVacuumBox(object self)
	{
		taggroup ref_vac_box_items
		taggroup ref_vac_box = DlgCreateBox("Reference vacuum", ref_vac_box_items).DlgInternalPadding(3, 5).DlgExternalPadding(3, 3)
		
		taggroup acquire_ref_image_button = DlgCreatePushButton("Acquire ref. image", "AcquireRefImageButtonPushed").DlgIdentifier("AcquireRefImage")
		taggroup set_central_beam_roi_button = DlgCreatePushButton("Set central beam ROI", "SetCentralBeamROIButtonPushed").DlgIdentifier("SetCentralBeamROI")
		
		taggroup threshold_factor_label = DlgCreateLabel("Threshold [0-1]:")
		
		number threshold_factor
		taggroup threshold_factor_field = DlgCreateRealField(threshold_factor, 8, 1).DlgIdentifier("ThresholdFactor").DlgValue(0.5)
		
		taggroup ref_vac_group
		ref_vac_group = DlgGroupItems(threshold_factor_label, threshold_factor_field).DlgTableLayout(2, 1, 0)
		
		ref_vac_box_items.DlgAddElement(acquire_ref_image_button)
		ref_vac_box_items.DlgAddElement(set_central_beam_roi_button)
		ref_vac_box_items.DlgAddElement(ref_vac_group)
		
		return ref_vac_box
	}
	
	// Create dialog box with items related to controlling beam position in STEM mode.
	taggroup MakeBeamControlBox(object self)
	{
		taggroup beam_ctrl_box_items
		taggroup beam_ctrl_box = DlgCreateBox("Beam control", beam_ctrl_box_items).DlgInternalPadding(3, 5).DlgExternalPadding(3, 3)
	
		taggroup get_beam_pos_button = DlgCreatePushButton("Get", "GetBeamPosButtonPushed").DlgIdentifier("GetBeamPos")
		taggroup set_beam_pos_button = DlgCreatePushButton("Set", "SetBeamPosButtonPushed").DlgIdentifier("SetBeamPos")

		taggroup beam_x_label = DlgCreateLabel("X [nm]:")
		taggroup beam_y_label = DlgCreateLabel("Y [nm]:")
		
		number beam_x, beam_y
		taggroup beam_x_field = DlgCreateRealField(beam_x, 8, 1).DlgIdentifier("BeamX").DlgValue(0)
		taggroup beam_y_field = DlgCreateRealField(beam_y, 8, 1).DlgIdentifier("BeamY").DlgValue(0)

		taggroup beam_ctrl_group1, beam_ctrl_group2, beam_ctrl_group
		beam_ctrl_group1 = DlgGroupItems(beam_x_label, beam_x_field, beam_y_label, beam_y_field).DlgTableLayout(2, 2, 0)
		beam_ctrl_group2 = DlgGroupItems(get_beam_pos_button, set_beam_pos_button).DlgTableLayout(1, 2, 0)
		beam_ctrl_group = DlgGroupItems(beam_ctrl_group1, beam_ctrl_group2).DlgTableLayout(2, 1, 0)
		
		beam_ctrl_box_items.DlgAddElement(beam_ctrl_group)
		
		return beam_ctrl_box
	}
	
	// Create dialog box with items related to the procedure of automatic scanning diffraction.
	taggroup MakeAutoScanBox(object self)
	{
		taggroup auto_scan_box_items
		taggroup auto_scan_box = DlgCreateBox("Auto scan", auto_scan_box_items).DlgInternalPadding(3, 5).DlgExternalPadding(3, 3)
	
		taggroup start_auto_scan_button = DlgCreatePushButton("Start auto scan", "StartAutoScanButtonPushed").DlgIdentifier("StartAutoScan")
		
		taggroup low_exp_time_label = DlgCreateLabel("Low exposure [s]:")
		taggroup norm_exp_time_label = DlgCreateLabel("Norm. exposure [s]:")
		taggroup n_x_m_label = DlgCreateLabel("N x M (rows x columns):")
		taggroup x_sign_label = DlgCreateLabel("x")
		
		number low_exp_time, norm_exp_time
		number n_rows, n_cols
		taggroup low_exp_time_field = DlgCreateRealField(low_exp_time, 8, 1).DlgIdentifier("LowExpTime").DlgValue(0.01)
		taggroup norm_exp_time_field = DlgCreateRealField(norm_exp_time, 8, 1).DlgIdentifier("NormExpTime").DlgValue(0.1)
		taggroup n_rows_field = DlgCreateIntegerField(n_rows, 8).DlgIdentifier("NumOfRows").DlgValue(10)
		taggroup n_cols_field = DlgCreateIntegerField(n_cols, 8).DlgIdentifier("NumOfCols").DlgValue(10)
		
		taggroup auto_scan_group1, auto_scan_group2, auto_scan_group3
		auto_scan_group1 = DlgGroupItems(low_exp_time_label, low_exp_time_field, norm_exp_time_label, norm_exp_time_field).DlgTableLayout(2, 2, 0)
		auto_scan_group2 = DlgGroupItems(n_rows_field, x_sign_label, n_cols_field).DlgTableLayout(3, 1, 0)
		
		auto_scan_box_items.DlgAddElement(auto_scan_group1)
		auto_scan_box_items.DlgAddElement(n_x_m_label)
		auto_scan_box_items.DlgAddElement(auto_scan_group2)
		auto_scan_box_items.DlgAddElement(start_auto_scan_button)
		
		return auto_scan_box
	}
	
	// Construct the dialog.
	taggroup MakeAutoScanDiffDialog(object self)
	{
		taggroup dialog_items;	
		taggroup dialog = DlgCreateDialog("AutoScanDiff", dialog_items)
	
		taggroup ref_vac_box = self.MakeReferenceVacuumBox()
		taggroup beam_ctrl_box = self.MakeBeamControlBox()
		taggroup auto_scan_box = self.MakeAutoScanBox()
		
		dialog_items.DlgAddElement(ref_vac_box)
		dialog_items.DlgAddElement(beam_ctrl_box)
		dialog_items.DlgAddElement(auto_scan_box)

		return dialog
	}
	
	object Init(object self)
	{
		return self
	}
		
	// The constructor - builds the dialog.
	AutoScanDiffDialog(object self)
	{
		self.Init(self.MakeAutoScanDiffDialog())
	}
	
	// The destructor - frees up memory when the dialog is closed.
	~AutoScanDiffDialog(object self)
	{
		DeletePersistentNote("ref_t")
		DeletePersistentNote("ref_l")
		DeletePersistentNote("ref_b")
		DeletePersistentNote("ref_r")
		DeletePersistentNote("ref_threshold")
	}
}

//--------------------------------------------------------------------

// Main function

void Main()
{
	object UserInterface = alloc(AutoScanDiffDialog).Init() //initialization
	UserInterface.display("AutoScanDiff v5.2")
	
	return
}


//--------------------------------------------------------------------

Main()
