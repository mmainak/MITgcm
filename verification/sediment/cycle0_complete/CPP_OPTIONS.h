#ifndef CPP_OPTIONS_H
#define CPP_OPTIONS_H

#include "PACKAGES_CONFIG.h"

C     *** Debugging options ***
#undef  ALLOW_DEBUG

C     *** Diagnostic options ***
#define ALLOW_DIAGNOSTICS
#define ALLOW_TIMEAVE

C     *** I/O options ***
#define ALLOW_NETCDF_SUPPORT
#define ALLOW_MNC

C     *** Momentum equation options ***
#define ALLOW_3D_DIFFKR
#define ALLOW_VISCOUS_DAMPING
#define ALLOW_BOTTOMDRAG

C     *** Tracer options ***
#define ALLOW_3D_DIFFKR

C     *** Free surface ***
#define NONLIN_FRSURF

C     *** Equation of State ***
#define ALLOW_NONLINEAR_EQUATION_OF_STATE

C     *** Topography ***
#define ALLOW_PARTIAL_CELL_TOPOGRAPHY

C     *** Conservation flags ***
#define EXACT_CONSERV

C     *** Multiple processes ***
#define ALLOW_CYCLES_IN_X
#define ALLOW_CYCLES_IN_Y
#define ALLOW_GLOBAL_SUM_SINGLECPU

#endif


