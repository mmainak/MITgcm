#ifndef CPP_OPTIONS_H
#define CPP_OPTIONS_H

#include "PACKAGES_CONFIG.h"
#include "CPP_EEOPTIONS.h"

CBOP
C     !ROUTINE: CPP_OPTIONS.h
C     !INTERFACE:
C     include "CPP_OPTIONS.h"

C     !DESCRIPTION:
C     *==========================================================*
C     | CPP_OPTIONS.h
C     | o CPP options file for MITgcm
C     *==========================================================*
C     | Use this file for selecting CPP options within the
C     | model. All options are selected by #define.
C     | When turning on an option, leave the '#' in front of the
C     | #define statement to activate it. To turn off an option,
C     | comment out the line by adding a 'C' in column 1.
C     *==========================================================*
CEOP

C-- Diagnostic Options
#define ALLOW_DIAGNOSTICS
#undef  ALLOW_DIAGNOSTICS_MNC

C-- Time-Averaging Options (disabled - not needed for basic test)
#undef  ALLOW_TIMEAVE

C-- Monitor Package Options
#define ALLOW_MONITOR

C-- Input/Output Options
#undef  ALLOW_IMBALANCE_DIMCHANGE

C-- Exact Conservation Options
#define EXACT_CONSERV

C-- C-D Grid Options
#define NONLIN_FRSURF
#undef  ALLOW_NONHYDROSTATIC

C-- Tracer Options
#define ALLOW_3D_DIFFKR

C-- Grid Options
#undef  ALLOW_GLOBAL_SUM_SINGLECPU

C-- Debug Options
#undef  ALLOW_DEBUG
#undef  ALLOW_PROFILE

#endif /* CPP_OPTIONS_H */
