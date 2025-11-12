C---SEDIMENT MODULE BEGIN
C
C     sediment_settling.F
C
C     Settling velocity implementation for sediment tracer - Cycle 1
C
C     PURPOSE:
C     --------
C     Modify PTRACERS vertical flux to include gravitational settling.
C     This subroutine computes the effective vertical flux including
C     settling and applies it as a tracer sink in each cell.
C
C     PHYSICS:
C     --------
C     The tracer conservation equation including settling:
C
C       ∂C/∂t + ∇·[u*C] = ∇·(K_C*∇C) - ∂(w_s*C)/∂z
C
C     where w_s is the settling velocity (downward positive).
C
C     Discretization (finite-volume):
C       Flux at top face:    Fw(k)   = ws0 * C(k)
C       Flux at bottom face: Fw(k+1) = ws0 * C(k+1)
C
C       Net source/sink: dC/dt_sink = -(Fw(k+1) - Fw(k)) / dz
C
C     In flux-form update:
C       C_new = C_old - dt/dz * [Fw(k+1) - Fw(k)]
C             = C_old - dt/dz * ws0 * [C(k+1) - C(k)]
C
C     For forward Euler with settling applied after advection:
C       C_new = C_adv - dt * ws0 * dC_dz
C
C     Here we use explicit forward time-stepping within the
C     PTRACERS tracer step to apply the settling sink directly.
C
C     INTEGRATION:
C     --------
C     Called after PTRACERS_ADVECTION and before PTRACERS_DIFFUSION
C     in the main timestepping loop.
C
C     CALLING SEQUENCE (in main timestepping):
C       1. PTRACERS_ADVECTION      → compute advective fluxes
C       2. SEDIMENT_SETTLING       → apply settling (THIS ROUTINE)
C       3. PTRACERS_DIFFUSION      → apply diffusive smoothing
C       4. PTRACERS_BOUNDARY       → apply boundary fluxes
C
C---SEDIMENT MODULE END

#include "SEDIMENT_OPTIONS.h"

      SUBROUTINE SEDIMENT_SETTLING(
     I     bi, bj, k,
     I     iMin, iMax, jMin, jMax,
     I     tracer,
     I     myThid )

      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "sediment.h"

C     === Routine arguments ===
      INTEGER bi, bj, k
      INTEGER iMin, iMax, jMin, jMax
      _RL tracer(1-OLx:sNx+OLx, 1-OLy:sNy+OLy, Nr, nSx, nSy)
      INTEGER myThid

C     === Local variables ===
      INTEGER i, j
      _RL settlingFlux, dC_dz, dz
      _RL dt_over_dz
      _RL dC_above, dC_below
      _RL cFlux_above, cFlux_below
      CHARACTER*(MAX_LEN_MBUF) msgBuf

C---SEDIMENT MODULE: Apply Settling Velocity to Tracer
C
C     This routine implements explicit settling as a flux divergence.
C     The settling velocity ws0 is applied to the tracer concentration
C     in a flux-conservative manner:
C
C       dC/dt_settling = -∂(ws0*C)/∂z (vertical flux divergence)
C
C     For each grid cell, we compute the flux of sediment leaving
C     through the top and bottom faces, then update the tracer.

      IF ( k .EQ. 0 ) THEN
C       Surface layer (k=1): no settling from above
        RETURN
      ENDIF

C     Get vertical grid spacing for this layer
      dz = delZ(k)

C     Safety check
      IF ( dz .LE. 0. ) THEN
        IF ( myThid .EQ. 1 ) THEN
          WRITE(msgBuf,'(A,I3,A)') 
     &      'ERROR: Invalid delZ at k=', k, ' in SEDIMENT_SETTLING'
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                        SQUEEZE_RIGHT, myThid )
        ENDIF
        RETURN
      ENDIF

C     Pre-compute time-step divided by spacing
      dt_over_dz = deltaT / dz

C---SEDIMENT MODULE: Main settling loop
C
C     For each grid point in this layer, compute the vertical
C     flux divergence due to settling and update the tracer.
C
C     STABILITY CONDITION (CFL):
C       dt * ws0 / dz < 0.5
C     This is checked in sediment_init.F and stored in SEDIMENT_cflSet.
C     If violated, a warning is issued but the code continues to allow
C     for investigative debugging.

      DO j = jMin, jMax
        DO i = iMin, iMax

C         Settling flux at top of cell (k): Fw_top = ws0 * C(k)
C         Settling flux at bottom (k+1): Fw_bot = ws0 * C(k+1)
C
C         If k=1 (surface), flux_top = 0 (no sediment enters from above)
C         Otherwise flux_top = ws0 * tracer(i,j,k-1,...)

          IF ( k .EQ. 1 ) THEN
C           Surface: no flux from above
            cFlux_above = 0. _d 0
          ELSE
C           Interior: sediment settling from above
            cFlux_above = SEDIMENT_ws0 * tracer(i,j,k-1,bi,bj)
          ENDIF

C         Bottom flux (into cell k+1, out of cell k)
          IF ( k .LT. Nr ) THEN
            cFlux_below = SEDIMENT_ws0 * tracer(i,j,k,bi,bj)
          ELSE
C           Bottom layer: sediment exits but is handled separately
C           (deposition at bottom will be in Cycle 4)
            cFlux_below = SEDIMENT_ws0 * tracer(i,j,k,bi,bj)
          ENDIF

C         Flux divergence: tracer loss due to settling
C         ∆C/∆t = -(Flux_below - Flux_above) / dz
C               = -(ws0*C(k) - ws0*C(k-1)) / dz
C               = -ws0 * (C(k) - C(k-1)) / dz

          settlingFlux = cFlux_below - cFlux_above
          dC_dz = settlingFlux / dz

C         Update tracer: C := C - dt * (flux_divergence)
C         Conservative form (tracer is a volume concentration [kg/m³]):
C           C_new = C_old - dt/dz * [ws0*C(k) - ws0*C(k-1)]

          tracer(i,j,k,bi,bj) = tracer(i,j,k,bi,bj) 
     &                         - dt_over_dz * settlingFlux

C         SANITY CHECK: Warn if tracer becomes negative
C         (This should not occur for small CFL, but log if it does)
          IF ( tracer(i,j,k,bi,bj) .LT. 0. ) THEN
            tracer(i,j,k,bi,bj) = 0. _d 0
            IF ( myThid .EQ. 1 ) THEN
              WRITE(msgBuf,'(A,I3,A,I4,A,I4)') 
     &          'WARNING: Negative tracer set to zero at k=',k,
     &          ' i=',i,' j=',j
              CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                            SQUEEZE_RIGHT, myThid )
            ENDIF
          ENDIF

        ENDDO
      ENDDO

      RETURN
      END


