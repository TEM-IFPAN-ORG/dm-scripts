//--------------------------------------------------------------
// PEELS_SUM.cpp
// Author: Krzysztof Morawiec
//--------------------------------------------------------------

#include "PEELS_SUM.h"
using namespace std;

//--------------------------------------------------------------

int get_max_idx(int *data, int size)
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

void move_spectrum(int *row, int cols, int ref_max_idx)
{
	int max_idx = get_max_idx(row, cols);
	int diff = ref_max_idx - max_idx;

	int *row_tmp = new int[cols];
	for (int i=0; i<cols; ++i) row_tmp = 0;
	
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

	for (int i=start; i<end; ++i) row_tmp[j++] = row[i];
	row = row_tmp;

	delete[] row_tmp;
}