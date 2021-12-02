#define _GATAN_USE_STL_STRING

#include "DMPlugInBasic.h"
#include "DMPlugInMain.h"

//--------------------------------------------------------

class SpectrumReader : public GatanPlugIn::PlugInMain
{
	virtual void Start();
	virtual void Run();
	virtual void Cleanup();
	virtual void End();
};

//--------------------------------------------------------

void AlignZLP(DM_ImageToken img_token);