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
      _RL relax_tend      ! Boundary relaxation tendency [kg/m³/s]
      _RL relax_timescale ! Relaxation timescale [s]
      _RL max_tend_mag    ! Track max tendency
      INTEGER i_maxT, j_maxT, k_maxT  ! Location of max
      LOGICAL firstCall
      SAVE firstCall
      DATA firstCall /.TRUE./
      CHARACTER*(MAX_LEN_MBUF) msgBuf

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

C     Get layer thickness (use drF for reference, will apply hFacC per cell)
      dz = drF(k)
      IF ( dz .LE. 0. _d 0 ) RETURN
      recip_dz = 1. _d 0 / dz
      
C     Note: For partial cells, we should use dz_eff = drF(k) * hFacC
C     but MITgcm's tendency framework handles this automatically
C     via the volume weighting in the time-stepping routine

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Initialize diagnostic tracking
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
      max_tend_mag = 0. _d 0
      i_maxT = 0
      j_maxT = 0
      k_maxT = k

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
          
C         Skip WEST OBCS CONDUIT INFLOW cells only (j=3-6, k=39-40)
C         These cells have prescribed inflow via OBWptrFile
C         All other boundary cells will get zero-gradient BC below
          IF ( i .EQ. 1 .AND. j .GE. 3 .AND. j .LE. 6 .AND. 
     &         k .GE. 39 .AND. k .LE. 40 ) GOTO 100

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
C         Allow settling flux everywhere (deposition BC at bottom)
C         Sediment that settles below the bottom cell is deposited and removed
          flux_out = ws * C_k

C         Settling tendency: dC/dt = (flux_in - flux_out) / dz
C         This is negative when C_k > C_above (sediment leaves cell)
          settling_tend = (flux_in - flux_out) * recip_dz
          
C         STABILITY: Prevent settling from creating negative concentrations
C         Limit removal rate to ensure C remains positive
          IF ( settling_tend .LT. 0. _d 0 ) THEN
C           Check if tendency would make C negative
            IF ( C_k + settling_tend*deltaT .LT. 0. _d 0 ) THEN
C             Limit to just reach zero (no overshoot)
              settling_tend = -C_k / deltaT
            ENDIF
          ENDIF
          
C         STABILITY: Prevent excessive accumulation (cap growth rate)
C         Max accumulation rate: 10 kg/m³/s (prevents exponential blow-up)
          IF ( settling_tend .GT. 10. _d 0 ) THEN
            settling_tend = 10. _d 0
          ENDIF
          
C         STABILITY: Don't add sediment if concentration already very high
C         This prevents runaway growth at boundaries
          IF ( C_k .GT. 50. _d 0 .AND. settling_tend .GT. 0. _d 0 ) THEN
            settling_tend = 0. _d 0
          ENDIF

C         Add to tendency array
C         Note: hFacC scaling is handled by MITgcm's timestepping
          gPtracer(i,j) = gPtracer(i,j) + settling_tend
          
C         Track maximum tendency magnitude for diagnostics
          IF ( ABS(settling_tend) .GT. max_tend_mag ) THEN
            max_tend_mag = ABS(settling_tend)
            i_maxT = i
            j_maxT = j
          ENDIF

 100      CONTINUE
        ENDDO
      ENDDO
      
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Apply zero-gradient outflow BC via gentle relaxation
C
C     Instead of directly modifying pTracer (which gets overwritten by
C     timestepping), we enforce the BC by setting the tendency (gPtracer)
C     to a relaxation term:
C       gPtracer(boundary) = (C_interior - C_boundary) / tau_relax
C
C     where tau_relax >> dt for numerical stability.
C     This gently forces the boundary cell toward its interior neighbor,
C     effectively implementing dC/dx = 0 at boundaries without causing
C     oscillations from overly strong forcing.
C
C     Boundaries where sediment can EXIT:
C       - EAST (i=sNx): outflow
C       - WEST outside conduit (i=1, except j=3-6 k=39-40): potential outflow
C       - NORTH/SOUTH (j=1, j=sNy): wall BC but allows tracer flux
C       - BOTTOM (k=Nr): deposition (handled by settling BC above)
C     
C     Boundaries where sediment CANNOT exit:
C       - WEST at conduit (i=1, j=3-6, k=39-40): OBCS prescribes inflow
C       - TOP (k=1): free surface (no flux from above)
C       - Ice shelf: masked cells (maskC=0)
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

C     EAST boundary (all tiles with global east edge)
C     Apply very strong relaxation to enforce zero-gradient: C(sNx) = C(sNx-1)
C     Use relaxation timescale of ~2*dt for nearly instantaneous removal
      relax_timescale = 2.0 _d 0 * deltaT
      IF ( bi .EQ. nSx ) THEN
        DO j = jMin, jMax
          IF ( maskC(sNx,j,k,bi,bj) .GT. 0. _d 0 ) THEN
C           Relax boundary toward interior value over relax_timescale
            relax_tend = (pTracer(sNx-1,j,k,bi,bj,iTr) 
     &                  - pTracer(sNx,j,k,bi,bj,iTr)) / relax_timescale
C           Override any settling tendency at boundary
            gPtracer(sNx,j) = relax_tend
          ENDIF
        ENDDO
      ENDIF

C     WEST boundary outside conduit (tiles with global west edge)
C     Skip conduit cells (j=3-6, k=39-40) which have prescribed inflow via OBCS
      IF ( bi .EQ. 1 ) THEN
        DO j = jMin, jMax
C         Skip conduit inflow cells - OBCS controls these
          IF ( .NOT. (j .GE. 3 .AND. j .LE. 6 .AND. 
     &                k .GE. 39 .AND. k .LE. 40) ) THEN
            IF ( maskC(1,j,k,bi,bj) .GT. 0. _d 0 ) THEN
C             Relax boundary toward interior value (gentle relaxation)
              relax_tend = (pTracer(2,j,k,bi,bj,iTr) 
     &                    - pTracer(1,j,k,bi,bj,iTr)) / relax_timescale
              gPtracer(1,j) = relax_tend
            ENDIF
          ENDIF
        ENDDO
      ENDIF

C     NORTH/SOUTH boundaries if domain has open boundaries there
C     (Currently free-slip walls, but ready for future OBCS)
      IF ( bj .EQ. nSy ) THEN
        DO i = iMin, iMax
          IF ( maskC(i,sNy,k,bi,bj) .GT. 0. _d 0 ) THEN
            relax_tend = (pTracer(i,sNy-1,k,bi,bj,iTr) 
     &                  - pTracer(i,sNy,k,bi,bj,iTr)) / relax_timescale
            gPtracer(i,sNy) = relax_tend
          ENDIF
        ENDDO
      ENDIF
      IF ( bj .EQ. 1 ) THEN
        DO i = iMin, iMax
          IF ( maskC(i,1,k,bi,bj) .GT. 0. _d 0 ) THEN
            relax_tend = (pTracer(i,2,k,bi,bj,iTr) 
     &                  - pTracer(i,1,k,bi,bj,iTr)) / relax_timescale
            gPtracer(i,1) = relax_tend
          ENDIF
        ENDDO
      ENDIF
      
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Print diagnostic at first few timesteps (k=1 and k=Nr only)
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
      IF ( myIter .LE. 10 .AND. (k.EQ.1 .OR. k.GE.35) ) THEN
        _BEGIN_MASTER( myThid )
        WRITE(msgBuf,'(A,I6,A,I3,A,E10.3,A,I3,A,I3)')
     &    'SETTLE iter=', myIter, ' k=', k,
     &    ' maxTend=', max_tend_mag,
     &    ' at i=', i_maxT, ' j=', j_maxT
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        _END_MASTER( myThid )
      ENDIF

#endif /* ALLOW_SEDIMENT_SETTLING */
#endif /* ALLOW_SEDIMENT */
#endif /* ALLOW_PTRACERS */

      RETURN
      END

