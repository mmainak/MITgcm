C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C SEDIMENT_APPLY_SETTLING
C
C Add gravitational settling tendency to passive tracer (sediment)
C
C Physics:
C   Settling adds a vertical flux divergence to the tracer equation:
C     dC/dt = ... - d(ws*C)/dz
C
C   At level k, the tendency due to settling is:
C     gPtracer = (flux_in - flux_out) / dz
C              = (ws*C(k-1) - ws*C(k)) / dz   [for interior]
C              = -ws*C(k) / dz                 [for k=1, no flux from above]
C
C   This routine adds this tendency to gPtracer.
C
C Called from: PTRACERS_APPLY_FORCING
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

#include "CPP_EEOPTIONS.h"
#include "SEDIMENT_OPTIONS.h"

      SUBROUTINE SEDIMENT_APPLY_SETTLING(
     U                 gPtracer,
     I                 iMin, iMax, jMin, jMax,
     I                 k, bi, bj,
     I                 iTracer,
     I                 myTime, myIter, myThid )

      IMPLICIT NONE

C === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_FIELDS.h"
#include "sediment.h"

C === Routine arguments ===
C  gPtracer  :: tendency array for this level (updated)
C  iMin,iMax,jMin,jMax :: loop bounds
C  k         :: vertical level
C  bi,bj     :: tile indices
C  iTracer   :: which tracer is being processed
C  myTime    :: current time
C  myIter    :: current iteration
C  myThid    :: thread ID
      _RL gPtracer(1-OLx:sNx+OLx, 1-OLy:sNy+OLy)
      INTEGER iMin, iMax, jMin, jMax
      INTEGER k, bi, bj
      INTEGER iTracer
      _RL myTime
      INTEGER myIter, myThid

#ifdef ALLOW_PTRACERS
#ifdef ALLOW_SEDIMENT
#ifdef ALLOW_SEDIMENT_SETTLING

C === Local variables ===
      INTEGER i, j, iTr
      _RL ws              ! Settling velocity [m/s]
      _RL C_k             ! Concentration at level k
      _RL C_above         ! Concentration at level k-1 (above)
      _RL flux_in         ! Flux entering from above [kg/m²/s]
      _RL flux_out        ! Flux leaving below [kg/m²/s]
      _RL dz              ! Layer thickness [m]
      _RL recip_dz        ! 1/dz
      _RL settling_tend   ! Settling tendency [kg/m³/s]
      LOGICAL firstCall
      SAVE firstCall
      DATA firstCall /.TRUE./

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Initialize sediment parameters on first call
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
      IF ( firstCall ) THEN
        CALL SEDIMENT_READPARMS( myThid )
        CALL SEDIMENT_INIT( myThid )
        firstCall = .FALSE.
      ENDIF

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Check if this is the sediment tracer - if not, return early
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
      iTr = SEDIMENT_tracerNum
      IF ( iTracer .NE. iTr ) RETURN

C     Get settling velocity from sediment parameters
      ws = SEDIMENT_ws0

C     Skip if settling velocity is zero or negative
      IF ( ws .LE. 0. _d 0 ) RETURN

C     Get layer thickness (use drF for finite volume)
      dz = drF(k)
      IF ( dz .LE. 0. _d 0 ) RETURN
      recip_dz = 1. _d 0 / dz

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Compute settling tendency for each grid point
C
C     The settling flux is: F = ws * C (positive downward)
C     
C     For each cell, the tendency is:
C       dC/dt = (F_in - F_out) / dz
C             = (ws*C_above - ws*C_k) / dz
C             = ws * (C_above - C_k) / dz
C
C     At surface (k=1): no flux from above, so F_in = 0
C       dC/dt = -ws * C_k / dz
C
C     At bottom (k=Nr or last wet cell): NO FLUX OUT (no deposition)
C       dC/dt = ws * C_above / dz  (only receives from above)
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      DO j = jMin, jMax
        DO i = iMin, iMax

C         Skip land points (maskC = 0)
          IF ( maskC(i,j,k,bi,bj) .EQ. 0. _d 0 ) GOTO 100

C         Get concentration at current level
          C_k = pTracer(i,j,k,bi,bj,iTr)

C         Get concentration from level above (k-1)
          IF ( k .GT. 1 ) THEN
C           Interior: sediment settles in from above
            C_above = pTracer(i,j,k-1,bi,bj,iTr)
C           Check if level above is ocean (not under ice shelf, etc.)
            IF ( maskC(i,j,k-1,bi,bj) .EQ. 0. _d 0 ) THEN
              C_above = 0. _d 0
            ENDIF
          ELSE
C           Surface layer (k=1): no sediment enters from above
            C_above = 0. _d 0
          ENDIF

C         Compute flux IN from above [kg/m²/s]
          flux_in  = ws * C_above

C         Compute flux OUT to below [kg/m²/s]
C         CRITICAL: At bottom cell, set flux_out = 0 (no-flux BC)
C         Check if this is the bottom cell (k=Nr) or if cell below is land
          IF ( k .EQ. Nr ) THEN
C           Bottom of domain: no flux out (sediment accumulates)
            flux_out = 0. _d 0
          ELSEIF ( maskC(i,j,k+1,bi,bj) .EQ. 0. _d 0 ) THEN
C           Cell below is land/bottom: no flux out
            flux_out = 0. _d 0
          ELSE
C           Interior cell: normal settling flux out
            flux_out = ws * C_k
          ENDIF

C         Settling tendency: dC/dt = (flux_in - flux_out) / dz
C         This is negative when C_k > C_above (sediment leaves cell)
C         At bottom: flux_out=0, so tendency is positive (accumulation)
          settling_tend = (flux_in - flux_out) * recip_dz

C         Add to tendency array
C         Note: hFacC scaling is handled by MITgcm's timestepping
          gPtracer(i,j) = gPtracer(i,j) + settling_tend

 100      CONTINUE
        ENDDO
      ENDDO

#endif /* ALLOW_SEDIMENT_SETTLING */
#endif /* ALLOW_SEDIMENT */
#endif /* ALLOW_PTRACERS */

      RETURN
      END

