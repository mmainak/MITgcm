#ifndef CPP_OPTIONS_H
#define CPP_OPTIONS_H

#include "PACKAGES_CONFIG.h"

// Diagnostic Options
#define ALLOW_DIAGNOSTICS
#undef  ALLOW_DIAGNOSTICS_MNC

// Time-Averaging Options
#define ALLOW_TIMEAVE

// Monitor Package Options
#define ALLOW_MONITOR

// Input/Output Options
#define ALLOW_NETCDF_SUPPORT
#define ALLOW_MNC
#undef  ALLOW_IMBALANCE_DIMCHANGE

// Exact Conservation Options
#define EXACT_CONSERV

// C-D Grid Options
#define NONLIN_FRSURF
#undef  ALLOW_NONHYDROSTATIC

// Momentum Equation Options
#undef  ALLOW_NONHYDROSTATIC_PRESSURE
#define ALLOW_VISCOUS_DAMPING
#define ALLOW_BOTTOMDRAG

// Tracer Options
#define ALLOW_3D_DIFFKR
#define ALLOW_BL79_LAT_VARY
#define ALLOW_SOLVE4_PS_AND_DRAG

// Equation of State Options
#define ALLOW_NONLINEAR_EQUATION_OF_STATE

// Bottom Topography Options
#define ALLOW_PARTIAL_CELL_TOPOGRAPHY

// Package-Specific Options
#ifdef ALLOW_SEDIMENT
#define ALLOW_SEDIMENT_MULTICLASS
#define ALLOW_SEDIMENT_DIAGNOSTICS
#define ALLOW_SEDIMENT_SETTLING_MODIF
#define ALLOW_SEDIMENT_MORPH_ACC
#endif

// Grid Options
#define ALLOW_CYCLES_IN_X
#define ALLOW_CYCLES_IN_Y
#define ALLOW_GLOBAL_SUM_SINGLECPU

// I/O Options
#define ALLOW_BALANCE_FLUXES
#define ALLOW_BALANCE_RELAX
#define ALLOW_BALANCE_BLACK

// Forcing Options
#define ALLOW_ATM_TEMP
#define ALLOW_ATM_WIND
#define ALLOW_DOWNWARD_RADIATION
#define ALLOW_BULKFORCE
#define ALLOW_BULK_LARGEYEAGER04

// Checkpointing Options
#define ALLOW_ADAMSBASHFORTH_3
#define ALLOW_TIMESTEP_MONITOR

// Debug Options
#undef  ALLOW_DEBUG
#undef  ALLOW_PROFILE
#undef  CHECK_IMPLICIT_SCALING

// Other Options
#define EXCLUDE_FFIELDS_LOAD
#define EXCLUDE_EXCH_INIT
#define ALLOW_ADDFLUID

C--   COMMON /EEPARAMS_L/ Execution environment public logical variables.
C     eeBootError    :: Flags indicating error during multi-processing
C     eeEndError     :: Error termination flag
C     fatalError     :: Flags indicating fatal error 
C     debugMode      :: Flag indicating if debug mode is enabled
C     useSingleCpuIO :: Only master MPI process does I/O (see also masterThreadIO)
C     useSingleCpuInput  :: Only master MPI process reads input files
C     printMapIncludesZeros  :: Flag indicating whether character map
C                            :: code ignores exact zero values
C     useCubedSphereExchange :: use Cubed-Sphere topology domain
C     useCoupler     :: use Coupler for a multi-components set-up
C     useNEST_PARENT :: use Parent Nesting interface (pkg/nest_parent)
C     useNEST_CHILD  :: use Child  Nesting interface (pkg/nest_child)
C     useOASIS       :: use OASIS-coupler for a multi-components set-up
      COMMON /EEPARAMS_L/
     &  eeBootError, fatalError, eeEndError,
     &  debugMode, useSingleCpuIO, useSingleCpuInput,
     &  printMapIncludesZeros, useCubedSphereExchange,
     &  useCoupler, useNEST_PARENT, useNEST_CHILD, useOASIS,
     &  useSETRLSTK, useSIGREG
      LOGICAL eeBootError
      LOGICAL eeEndError
      LOGICAL fatalError
      LOGICAL debugMode
      LOGICAL useSingleCpuIO
      LOGICAL useSingleCpuInput
      LOGICAL printMapIncludesZeros
      LOGICAL useCubedSphereExchange
      LOGICAL useCoupler
      LOGICAL useNEST_PARENT
      LOGICAL useNEST_CHILD
      LOGICAL useOASIS
      LOGICAL useSETRLSTK
      LOGICAL useSIGREG

#endif /* CPP_OPTIONS_H */
