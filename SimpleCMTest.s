//--------------------------------------------------------------------
// SimpleCMTest v3.2
// Simple Camera Manager Test
// Script by K. Morawiec
//--------------------------------------------------------------------

object cam_mgr = CM_GetCameraManager()
object cam_list = CM_GetCameras(cam_mgr)
object camera

Result("\nAvailable cameras:\n")
foreach(camera; cam_list)
	Result(CM_GetCameraName(camera) + "\n")

camera = CM_GetCurrentCamera()
if(!OkCancelDialog(CM_GetCameraName(camera) + " will be used. Are you sure?"))
{
	ShowAlert("Select proper camera and try again.", 2)
	Exit(0)
}

if(!CM_GetCameraInserted(camera))
{
	ShowAlert("Insert camera and try again.", 2)
	Exit(0)
}

number processing = 3		// 1 - no dark/gain correction
							// 2 - dark correction
							// 3 - dark and gain correction
number exposure = 0.5
number bin_x = 4
number bin_y = 4

//object acq_params = CM_GetCameraAcquisitionParameterSet(camera, "Imaging", "Acquire", "Record", 0)
object acq_params = CM_GetCameraAcquisitionParameterSet(camera, "Imaging", "View", "Search", 0)
//object acq_params = CM_CreateAcquisitionParameters_FullCCD(camera, processing, exposure, bin_x, bin_y)

/*
number top, left, bottom, right
CM_GetCCDReadArea(acq_params, top, left, bottom, right)
Result("\n" + top + ", " + left + ", " + bottom + ", " + right)

top /= bin_y
bottom /= bin_y
left /= bin_x
right /= bin_x
*/

CM_SetProcessing(acq_params, processing)
CM_SetExposure(acq_params, exposure)
CM_SetBinning(acq_params, bin_x, bin_y)

// Set/Get whether the readout should be optimized for continuous acquisition.
CM_SetDoContinuousReadout(acq_params, 1)
number do_cont_read = CM_GetDoContinuousReadout(acq_params)
Result("\n" + do_cont_read)

// Set/Get whether the shutter should be closed during exposure.
CM_SetShutterExposure(acq_params, 0)
number is_shutter_closed_during_exp = CM_GetShutterExposure(acq_params)
Result("\n" + is_shutter_closed_during_exp)

// Set/Get whether the shutter should be closed during any delay between frames of a continuous readout.
CM_SetShutterClosedBetweenFrames(acq_params, 0)
number is_shutter_closed_between_frames = CM_GetShutterClosedBetweenFrames(acq_params)
Result("\n" + is_shutter_closed_between_frames)

number img_width, img_height
number px_width, px_height
string px_units
number n_images = 10

image test_image = CM_CreateImageForAcquire(camera, acq_params, "Test image")
GetSize(test_image, img_width, img_height)
image test_stack = RealImage("Test stack", 4, img_width, img_height, n_images)

ConvertToLong(test_image)
ConvertToLong(test_stack)

ShowImage(test_stack)

// Get the scale of image dimensions (the size of pixel)
px_width = ImageGetDimensionScale(test_image, 0)
px_height = ImageGetDimensionScale(test_image, 1)
px_units = ImageGetDimensionUnitString(test_image, 0)

for(number i=0; i<n_images; i++)
{
	CM_AcquireImage(camera, acq_params, test_image)		// faster for EF-CCD
	//test_image = SSCUnprocessedBinnedAcquire(exposure, bin_x, top, left, bottom, right)
	//SSCGainNormalizedBinnedAcquireInPlace(test_image, exposure, bin_x, top, left, bottom, right)
	//CM_AcquireInplace(test_image, camera, processing, exposure, bin_x, bin_y, top, left, bottom, right)	// faster for BM-UltraScan
	test_stack[0, 0, i, img_width, img_height, i+1] = test_image
	UpdateImage(test_stack)
}

ImageSetDimensionScale(test_stack, 0, px_width)
ImageSetDimensionScale(test_stack, 1, px_height)
ImageSetDimensionUnitString(test_image, 0, px_units)
ImageSetDimensionUnitString(test_image, 1, px_units)
