//--------------------------------------------------------
// Read_Spectrum_DLL.cpp
// Author: Krzysztof Morawiec
//--------------------------------------------------------

#include "Read_Spectrum_DLL.h"
#include "PEELS_Shift.h"

using namespace Gatan;
using namespace std;

//--------------------------------------------------------

SpectrumReader sr;

//--------------------------------------------------------

void SpectrumReader::Start()
{
	AddFunction("void AlignZLP(RealImagePtr)", (void *) AlignZLP);
}

//--------------------------------------------------------

void SpectrumReader::Run() { }
void SpectrumReader::Cleanup() { }
void SpectrumReader::End() { }

//--------------------------------------------------------

void AlignZLP(DM_ImageToken img_token)
{
	DM::Image img(img_token);
	PlugIn::ImageDataLocker imgL(img);

	int size = img.GetDimensionSize(ulong(0));
	int n_sp = img.GetDimensionSize(ulong(1));

	float *data = new float[n_sp*size];
	data = (float*) imgL.get();

	int ref_max_idx = get_max_idx(data, size);

	for (int i=1; i<n_sp; ++i) {
		data += size;
		shift_spectrum(data, size, ref_max_idx);
	}

	img.DataChanged();
}