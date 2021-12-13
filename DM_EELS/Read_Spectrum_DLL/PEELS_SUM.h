//--------------------------------------------------------
// PEELS_SUM.h
// Author: Krzysztof Morawiec
//--------------------------------------------------------

#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <sstream>

//--------------------------------------------------------

int get_max_idx(int *data, int size);
void move_spectrum(int *row, int cols, int ref_max_idx);