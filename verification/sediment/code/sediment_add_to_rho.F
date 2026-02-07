#include "CPP_EEOPTIONS.h"
#include "SEDIMENT_OPTIONS.h"

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
CBOP
C !ROUTINE: SEDIMENT_ADD_TO_RHO

C !INTERFACE: ==========================================================
      SUBROUTINE SEDIMENT_ADD_TO_RHO(
     I                iMin, iMax, jMin, jMax, k,
     U                rhoLoc,
     I                bi, bj, myThid )

C !DESCRIPTION:
C     Add sediment contribution to a 2D density field.
C     Called after FIND_RHO_2D to include sediment effect in density.
C
C     This enables TWO-WAY COUPLING:
C       1. Sediment affects density -> buoyancy -> momentum (already done)
C       2. Sediment affects density -> stability -> convection/mixing (THIS)
C
C     Physics:
C       rho_total = rho_sw(T,S) + alphaC * C
C
C     where:
C       alphaC = (rho_sed - rho_sw) / rho_sed = 0.62 for quartz (2650 kg/m3)
C       C  = sediment concentration [kg/m3]
C
C     Note: This is consistent with the buoyancy coupling in calc_phi_hyd.F
C           but uses alphaC (dimensionless) rather than gammaC (m3/kg):
C           alphaC = gammaC * rho0
C
C     Called from:
C       - convective_adjustment.F (after FIND_RHO_2D)
C       - calc_ivdc.F (implicit vertical diffusion for convection)
C       - Any routine that computes density for stability checks

C !USES: ===============================================================
      IMPLICIT NONE
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#ifdef ALLOW_PTRACERS
#include "PTRACERS_SIZE.h"
#include "PTRACERS_FIELDS.h"
#include "sediment.h"
#endif

C !INPUT/OUTPUT PARAMETERS: ============================================
C  iMin,iMax,jMin,jMax :: loop bounds
C  k                   :: vertical level
C  rhoLoc              :: density field (modified in place)
C  bi, bj              :: tile indices
C  myThid              :: thread number
      INTEGER iMin, iMax, jMin, jMax, k
      _RL rhoLoc(1-OLx:sNx+OLx, 1-OLy:sNy+OLy)
      INTEGER bi, bj, myThid

#ifdef ALLOW_PTRACERS
#ifdef ALLOW_SEDIMENT
#ifdef ALLOW_SEDIMENT_DENSITY

C !LOCAL VARIABLES: ====================================================
      INTEGER i, j, iTr
      _RL C_sed
      _RL alphaC
      _RL deltaRho
CEOP

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Check if density coupling is enabled at runtime
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      IF ( .NOT. SEDIMENT_densityOn ) RETURN

C     Get sediment tracer index
      iTr = SEDIMENT_tracerNum
      IF ( iTr .LT. 1 .OR. iTr .GT. PTRACERS_num ) RETURN

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Compute density coefficient alphaC
C
C     Physical derivation (same as in sediment_add_buoyancy.F):
C       rho_mix = (1 - phi) * rho_sw + phi * rho_sed
C       where phi = C / rho_sed (volume fraction)
C
C       Substituting:
C       rho_mix = rho_sw + (rho_sed - rho_sw) * C / rho_sed
C               = rho_sw + alphaC * C
C
C       where alphaC = (rho_sed - rho_sw) / rho_sed
C
C     For quartz (rho_sed = 2650 kg/m3) in seawater (rho_sw = 1027 kg/m3):
C       alphaC = (2650 - 1027) / 2650 = 0.612
C
C     Note: This is consistent with gammaC used in buoyancy:
C       gammaC = alphaC / rho0 = 0.612 / 1035 = 5.9e-4 m3/kg
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      alphaC = ( SEDIMENT_rhoSed - rhoConst ) / SEDIMENT_rhoSed

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Add sediment contribution to density
C
C     rhoLoc already contains rho_sw(T,S) - rhoConst from FIND_RHO_2D
C     We add: deltaRho = alphaC * C
C     Result: rhoLoc = rho_sw - rho0 + alphaC*C = rho_mix - rho0
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      DO j = jMin, jMax
        DO i = iMin, iMax

C         Skip land points
          IF ( maskC(i,j,k,bi,bj) .EQ. 0. _d 0 ) GOTO 100

C         Get sediment concentration at this point
          C_sed = pTracer(i,j,k,bi,bj,iTr)

C         Ensure non-negative (numerical safety)
          IF ( C_sed .LT. 0. _d 0 ) C_sed = 0. _d 0

C         Compute density contribution: deltaRho = alphaC * C
          deltaRho = alphaC * C_sed

C         Add to density anomaly field
          rhoLoc(i,j) = rhoLoc(i,j) + deltaRho

 100      CONTINUE
        ENDDO
      ENDDO

#endif /* ALLOW_SEDIMENT_DENSITY */
#endif /* ALLOW_SEDIMENT */
#endif /* ALLOW_PTRACERS */

      RETURN
      END

