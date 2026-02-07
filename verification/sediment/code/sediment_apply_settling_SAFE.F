C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C SEDIMENT_APPLY_SETTLING - SAFE VERSION
C
C This version adds explicit checks to prevent exponential growth
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
      _RL ws, C_k, C_above
      _RL flux_in, flux_out
      _RL dz, recip_dz
      _RL settling_tend
      _RL MAX_TEND
      PARAMETER ( MAX_TEND = 1.0 _d 0 )  ! Max tendency [kg/m³/s]

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Check if this is the sediment tracer
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
      iTr = SEDIMENT_tracerNum
      IF ( iTracer .NE. iTr ) RETURN

C     Get settling velocity
      ws = SEDIMENT_ws0
      IF ( ws .LE. 0. _d 0 ) RETURN

C     Get layer thickness
      dz = drF(k)
      IF ( dz .LE. 0. _d 0 ) RETURN
      recip_dz = 1. _d 0 / dz

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Compute settling tendency with safety checks
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      DO j = jMin, jMax
        DO i = iMin, iMax

C         Skip land points
          IF ( maskC(i,j,k,bi,bj) .EQ. 0. _d 0 ) GOTO 100

C         Get current concentration
          C_k = pTracer(i,j,k,bi,bj,iTr)
          
C         SAFETY: Clip negative values
          IF ( C_k .LT. 0. _d 0 ) C_k = 0. _d 0

C         Get concentration from above (k-1 is shallower)
          IF ( k .GT. 1 ) THEN
            C_above = pTracer(i,j,k-1,bi,bj,iTr)
            IF ( maskC(i,j,k-1,bi,bj) .EQ. 0. _d 0 ) THEN
              C_above = 0. _d 0
            ENDIF
          ELSE
            C_above = 0. _d 0
          ENDIF
          
C         SAFETY: Clip negative values
          IF ( C_above .LT. 0. _d 0 ) C_above = 0. _d 0

C         Compute fluxes
          flux_in  = ws * C_above
          flux_out = ws * C_k

C         Compute tendency: dC/dt = (flux_in - flux_out) / dz
C         This is NEGATIVE when C_k > C_above (normal settling)
C         This is POSITIVE only when C_above > C_k (sediment from above)
          settling_tend = (flux_in - flux_out) * recip_dz

C         SAFETY: Limit tendency magnitude to prevent instability
          IF ( ABS(settling_tend) .GT. MAX_TEND ) THEN
            settling_tend = SIGN(MAX_TEND, settling_tend)
          ENDIF
          
C         SAFETY: Don't add sediment if C_k already very high
          IF ( C_k .GT. 100. _d 0 .AND. settling_tend .GT. 0. _d 0 ) THEN
            settling_tend = 0. _d 0
          ENDIF

C         Add to tendency
          gPtracer(i,j) = gPtracer(i,j) + settling_tend

 100      CONTINUE
        ENDDO
      ENDDO

#endif /* ALLOW_SEDIMENT_SETTLING */
#endif /* ALLOW_SEDIMENT */
#endif /* ALLOW_PTRACERS */

      RETURN
      END
