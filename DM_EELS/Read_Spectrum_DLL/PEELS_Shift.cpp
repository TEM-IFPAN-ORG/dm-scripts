//--------------------------------------------------------------
// PEELS_Shift.cpp
// Author: Krzysztof Morawiec
//--------------------------------------------------------------

#include "PEELS_Shift.h"
using namespace std;

//--------------------------------------------------------------

int get_max_idx(float *data, int size)
{
	int max_idx = 0;
	int max_val = -1e3;
	for (int i=0; i<size; ++i) {
		if (data[i] > max_val) {
			max_idx = i;
			max_val = data[i];
		}
	}
	return max_idx;
}

//--------------------------------------------------------------

void shift_spectrum(float *sp, int cols, int ref_max_idx)
{
	int max_idx = get_max_idx(sp, cols);
	int diff = ref_max_idx - max_idx;

	float *sp_tmp = new float[cols];
	for (int i=0; i<cols; ++i) sp_tmp[i] = 0;

	int j, start, end;
	if (diff <= 0) {
		j = 0;
		start = -diff;
		end = cols;
	}
	else {
		j = diff;
		start = 0;
		end = cols-diff;
	}

	for (int i=start; i<end; ++i) sp_tmp[j++] = sp[i];
	memcpy(sp, sp_tmp, cols*sizeof(float));

	delete[] sp_tmp;
}