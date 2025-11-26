C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C SEDIMENT_ADD_BUOYANCY
C
C Add sediment contribution to density field (for hydrostatic pressure)
C
C Physics:
C   Sediment increases water density:
C     ρ_mix = ρ_water + (ρ_sed - ρ_water) * C / ρ_sed
C     Δρ = ρ₀ * γC * C
C   where γC = (ρ_sed - ρ_water)/(ρ_sed * ρ_water) ≈ 6.2e-4 m³/kg for quartz
C
C   The density anomaly becomes:
C     ρ' = ρ_T,S + ρ₀ * γC * C
C
C   This is added to alphaRho in calc_phi_hyd.F to affect
C   the hydrostatic pressure gradient.
C
C Called from: calc_phi_hyd.F (local copy with sediment hook)
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

#include "CPP_EEOPTIONS.h"
#include "SEDIMENT_OPTIONS.h"

      SUBROUTINE SEDIMENT_ADD_BUOYANCY(
     I                 iMin, iMax, jMin, jMax, k,
     U                 alphaRho,
     I                 bi, bj, myThid )

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
C     iMin,iMax,jMin,jMax :: loop bounds
C     k                   :: vertical level
C     alphaRho            :: density anomaly field (modified in place)
C     bi, bj              :: tile indices
C     myThid              :: thread number
      INTEGER iMin, iMax, jMin, jMax, k
      _RL alphaRho(1-OLx:sNx+OLx, 1-OLy:sNy+OLy)
      INTEGER bi, bj, myThid

#ifdef ALLOW_PTRACERS
#ifdef ALLOW_SEDIMENT
#ifdef ALLOW_SEDIMENT_BUOYANCY

C === Local variables ===
      INTEGER i, j, iTr
      _RL C_sed           ! Sediment concentration [kg/m³]
      _RL deltaRho        ! Density contribution from sediment

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Check if buoyancy coupling is enabled at runtime
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      IF ( .NOT. SEDIMENT_buoyancyOn ) RETURN

C     Get sediment tracer index
      iTr = SEDIMENT_tracerNum

C     Check valid tracer number
      IF ( iTr .LT. 1 .OR. iTr .GT. PTRACERS_num ) RETURN

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Add sediment density contribution to alphaRho
C
C     Physics:
C       Δρ_sed = ρ₀ * γC * C
C
C     where:
C       ρ₀ = rhoConst (reference density, from PARAMS.h)
C       γC = SEDIMENT_gammaC (density expansion coefficient, ~1.6e-3 m³/kg)
C       C  = pTracer (sediment concentration, kg/m³)
C
C     The sediment makes water DENSER (positive Δρ), which:
C       - Increases hydrostatic pressure below
C       - Creates baroclinic pressure gradients
C       - Drives flow from high-sediment to low-sediment regions
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      DO j = jMin, jMax
        DO i = iMin, iMax

C         Skip land points
          IF ( maskC(i,j,k,bi,bj) .EQ. 0. _d 0 ) GOTO 100

C         Get sediment concentration at this point
          C_sed = pTracer(i,j,k,bi,bj,iTr)

C         Ensure non-negative concentration (numerical safety)
          IF ( C_sed .LT. 0. _d 0 ) C_sed = 0. _d 0

C         Compute density contribution: Δρ = ρ₀ * γC * C
C         Note: alphaRho is the density anomaly (ρ - ρ₀)
C         Adding Δρ_sed increases the total density anomaly
          deltaRho = rhoConst * SEDIMENT_gammaC * C_sed

C         Add to density anomaly field
          alphaRho(i,j) = alphaRho(i,j) + deltaRho

 100      CONTINUE
        ENDDO
      ENDDO

#endif /* ALLOW_SEDIMENT_BUOYANCY */
#endif /* ALLOW_SEDIMENT */
#endif /* ALLOW_PTRACERS */

      RETURN
      END

