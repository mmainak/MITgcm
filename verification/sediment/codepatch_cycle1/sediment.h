C---SEDIMENT MODULE BEGIN
C
C     sediment.h
C
C     Header file for sediment tracer module - Cycle 1: Minimal Settling
C
C     PURPOSE:
C     --------
C     Define sediment tracer parameters and control flags for the
C     minimal settling implementation. This cycle adds one settling
C     sediment tracer with gravitational settling and CFL stability check.
C
C     MODIFICATIONS:
C     - Added sediment settling velocity parameters
C     - Added CFL control parameter for settling
C     - Integrated with PTRACERS package
C
C---SEDIMENT MODULE END

#ifdef ALLOW_PTRACERS

C     ===================================================================
C     SEDIMENT PARAMETERS (Read from data.sediment namelist)
C     ===================================================================

C     Settling velocity for sediment tracer [m/s]
C     - Typical fine sediment: 0.001 m/s (very fine silt)
C     - Medium sediment: 0.01 m/s
C     - Coarse sediment: 0.05 m/s (sand)
      _RL SEDIMENT_ws0
      COMMON /SEDIMENT_PARAMS_RL/ SEDIMENT_ws0

C     Sediment tracer index (assigned by PTRACERS package)
C     - Tracer number in the PTRACERS array
      INTEGER SEDIMENT_tracerNum
      COMMON /SEDIMENT_PARAMS_I/ SEDIMENT_tracerNum

C     CFL limit flag and warning counter
C     - SEDIMENT_cflWarn: triggers if CFLset exceeds 0.5
C     - Count violations for diagnostic output
      LOGICAL SEDIMENT_cflWarn
      INTEGER SEDIMENT_cflWarnCount
      COMMON /SEDIMENT_FLAGS/ SEDIMENT_cflWarn, SEDIMENT_cflWarnCount

C     ===================================================================
C     SEDIMENT DIAGNOSTICS AND CHECKS
C     ===================================================================

C     Effective CFL number: CFLset = ws0*dt/dz
C     - Must remain < 0.5 for stability
C     - Computed at initialization
      _RL SEDIMENT_cflSet
      COMMON /SEDIMENT_DIAGNOSTICS_RL/ SEDIMENT_cflSet

#endif /* ALLOW_PTRACERS */

