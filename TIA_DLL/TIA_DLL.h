#import "C:\Program Files\FEI\TIA\bin\ESVision.tlb"

#define _GATAN_USE_STL_STRING

#include "DMPlugInBasic.h"
#include "DMPlugInMain.h"

//--------------------------------------------------------

extern ESVision::IApplicationPtr TIA;

//--------------------------------------------------------

class TIA_DLL : public GatanPlugIn::PlugInMain
{
	virtual void Start();
	virtual void Run();
	virtual void Cleanup();
	virtual void End();
};

//--------------------------------------------------------

bool InitTIA(void);
void ReleaseTIA(void);
void GetBeamPosition(double *beam_x, double *beam_y);
bool SetBeamPosition(double beam_x, double beam_y);
void GetROI(double *roi_x0, double *roi_y0, double *roi_w, double *roi_h);