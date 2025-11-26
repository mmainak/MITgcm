#ifndef CPP_OPTIONS_H
#define CPP_OPTIONS_H

CBOP
C !ROUTINE: CPP_OPTIONS.h
C !INTERFACE:
C #include "CPP_OPTIONS.h"

C !DESCRIPTION:
C *==================================================================*
C | main CPP options file for the model:
C | Control which optional features to compile in model/src code.
C *==================================================================*
CEOP

C CPP flags controlling particular source code features

C-- Forcing code options:

C o Include pressure loading code
#define ATMOSPHERIC_LOADING

C-- Options to discard parts of the main code:

C o Include/exclude phi_hyd calculation code
#define INCLUDE_PHIHYD_CALCULATION_CODE

C-- Vertical mixing code options:

C o Include/exclude calling S/R CONVECTIVE_ADJUSTMENT
#define INCLUDE_CONVECT_CALL

C o Include/exclude call to S/R CALC_DIFFUSIVITY
#define INCLUDE_CALC_DIFFUSIVITY_CALL

C o Allow full 3D specification of vertical diffusivity
#define ALLOW_3D_DIFFKR

C o Exclude/allow to use isotropic 3-D Smagorinsky viscosity as diffusivity
C   for tracers (after scaling by constant Prandtl number)
#define ALLOW_SMAG_3D_DIFFUSIVITY

C-- Time-stepping code options:

C o Include/exclude Implicit vertical advection code
#define INCLUDE_IMPLVERTADV_CODE

C-- Model formulation options:

C o Allow the use of Non-Linear Free-Surface formulation
C   this implies that grid-cell thickness (hFactors) varies with time
#undef NONLIN_FRSURF

C o Include/exclude nonHydrostatic code
#define ALLOW_NONHYDROSTATIC

C-- Algorithm options:

C o Include/exclude code for single reduction Conjugate-Gradient solver
#define ALLOW_SRCG

C-- Diagnostics
#define ALLOW_DIAGNOSTICS

C-- Monitor
#define ALLOW_MONITOR

C-- Other option files:

C o Execution environment support options
#include "CPP_EEOPTIONS.h"

#endif /* CPP_OPTIONS_H */
