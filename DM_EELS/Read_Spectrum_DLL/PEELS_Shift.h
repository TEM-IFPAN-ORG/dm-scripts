//--------------------------------------------------------------
// PEELS_Shift.h
// Author: Krzysztof Morawiec
//--------------------------------------------------------------

#include <iostream>

int get_max_idx(float *data, int size);
void shift_spectrum(float *sp, int cols, int ref_max_idx);