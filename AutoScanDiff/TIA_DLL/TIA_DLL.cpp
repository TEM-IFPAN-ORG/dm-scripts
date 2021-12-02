#include "TIA_DLL.h"
using namespace Gatan;

//--------------------------------------------------------

TIA_DLL tia_plugin;
ESVision::IApplicationPtr TIA;

//--------------------------------------------------------

void TIA_DLL::Start()
{
	AddFunction("bool InitTIA(void)", (void *) InitTIA);
	AddFunction("void ReleaseTIA(void)", (void *) ReleaseTIA);
	AddFunction("void GetBeamPosition(double *beam_x, double *beam_y)", (void *) GetBeamPosition);
	AddFunction("bool SetBeamPosition(double beam_x, double beam_y)", (void *) SetBeamPosition);
	AddFunction("void GetROI(double *roi_x0, double *roi_y0, double *roi_w, double *roi_h)", (void *) GetROI);
}

//--------------------------------------------------------

void TIA_DLL::Run() { }
void TIA_DLL::Cleanup() { }
void TIA_DLL::End() { }

//--------------------------------------------------------

bool InitTIA(void)
{
	HRESULT hr = CoInitialize(NULL);
	if (FAILED(hr)) return false;

	hr = TIA.CreateInstance("ESVision.Application");
	if (FAILED(hr)) return false;

	return true;
}

//--------------------------------------------------------

void ReleaseTIA(void)
{
	TIA.Release();
	TIA = NULL;
	CoUninitialize();
}

//--------------------------------------------------------

void GetBeamPosition(double *beam_x, double *beam_y)
{
	ESVision::IPosition2DPtr beam_pos = TIA->ScanningServer()->BeamPosition;
	*beam_x = beam_pos->X * 1e9;
	*beam_y = beam_pos->Y * 1e9;
}

//--------------------------------------------------------

bool SetBeamPosition(double beam_x, double beam_y)
{
	beam_x *= 1e-9;
	beam_y *= 1e-9;

	ESVision::IRange2DPtr total_range = TIA->ScanningServer()->GetTotalScanRange();
	if (beam_x < total_range->StartX || beam_x > total_range->EndX) {
		DM::OkDialog("Beam X-coordinate is outside of the total X-range");
		return false;
	}
	else if (beam_y < total_range->StartY || beam_y > total_range->EndY) {
		DM::OkDialog("Beam Y-coordinate is outside of the total Y-range");
		return false;
	}

	ESVision::IPosition2DPtr beam_pos = TIA->ScanningServer()->BeamPosition;
	beam_pos->X = beam_x;
	beam_pos->Y = beam_y;
	TIA->ScanningServer()->BeamPosition = beam_pos;
	return true;
}

//--------------------------------------------------------

void GetROI(double *roi_x0, double *roi_y0, double *roi_w, double *roi_h)
{
	// ESVision::IImageSelectionMarkerPtr roi = TIA->ActiveDisplayWindow()->SelectedDisplay()->GetImageSelectionMarker();
	// ESVision::IImageSelectionMarkerPtr roi = TIA->FindDisplayObject("Window/Display/Selection1");
	ESVision::IImageSelectionMarkerPtr roi = TIA->ActiveDisplayWindow()->SelectedObject();
	*roi_x0 = roi->Range->StartX * 1e9;
	*roi_y0 = roi->Range->EndY * 1e9;
	*roi_w = roi->Range->SizeX * 1e9;
	*roi_h = roi->Range->SizeY * 1e9;
}