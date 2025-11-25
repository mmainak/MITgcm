C---SEDIMENT MODULE BEGIN
C
C     sediment_eos.F
C
C     Equation of state coupling for sediment tracer - Cycle 2
C
C     PURPOSE:
C     --------
C     Compute the buoyancy contribution from suspended sediment.
C     This modifies the density/buoyancy field to account for the
C     weight of suspended sediment particles.
C
C     PHYSICS:
C     --------
C     The equation of state for seawater with suspended sediment:
C
C       ρ = ρ₀[1 - αT(T - T₀) + βS(S - S₀) + γC·C]
C
C     where:
C       ρ₀ = reference density (rhoConst) [kg/m³]
C       αT = thermal expansion coefficient [1/K]
C       βS = haline contraction coefficient [1/psu]
C       γC = sediment density expansion coefficient [m³/kg]
C       C  = sediment concentration [kg/m³]
C
C     The buoyancy field (used in momentum equations):
C
C       b = -g(ρ - ρ₀)/ρ₀ = g[αT(T - T₀) - βS(S - S₀) - γC·C]
C
C     Sediment contribution to buoyancy:
C
C       b_sed = -g·γC·C
C
C     Note the NEGATIVE sign: more sediment → higher density → 
C     more negative buoyancy → downward force.
C
C     INTEGRATION:
C     --------
C     This routine can be called:
C     1. From compute_buoyancy.F to add sediment contribution to b-field
C     2. From eos_linear.F to modify density directly
C     3. As standalone diagnostic
C
C     For Cycle 2, we provide a standalone routine that can be
C     integrated into the MITgcm EOS system.
C
C     CALLING SEQUENCE:
C     ----------------
C     In compute_buoyancy.F or similar, add after temperature/salinity:
C
C       #ifdef ALLOW_SEDIMENT_EOS
C       CALL SEDIMENT_EOS_BUOYANCY( theta, salt, tracer, buoyancy, 
C      &                            bi, bj, myThid )
C       #endif
C
C---SEDIMENT MODULE END

#include "CPP_EEOPTIONS.h"
#include "SEDIMENT_OPTIONS.h"

#ifdef ALLOW_SEDIMENT_EOS

      SUBROUTINE SEDIMENT_EOS_BUOYANCY(
     I     bi, bj, iMin, iMax, jMin, jMax,
     I     tracer,
     U     buoyancy,
     I     myThid )

      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "sediment.h"

C     === Routine arguments ===
      INTEGER bi, bj
      INTEGER iMin, iMax, jMin, jMax
      _RL tracer(1-OLx:sNx+OLx, 1-OLy:sNy+OLy, Nr, nSx, nSy)
      _RL buoyancy(1-OLx:sNx+OLx, 1-OLy:sNy+OLy, Nr)
      INTEGER myThid

C     === Local variables ===
      INTEGER i, j, k
      _RL sedConc, buoy_sed
      _RL gOverRho0

C---SEDIMENT MODULE: Compute Sediment Buoyancy Contribution
C
C     This routine adds the sediment contribution to the buoyancy field.
C     The buoyancy is modified in-place (argument buoyancy is intent INOUT).
C
C     Physics:
C       Sediment makes water denser → reduces buoyancy
C       b_sed = -g * gammaC * C
C
C     where:
C       g      = gravity [m/s²] (from PARAMS: gravity or g0)
C       gammaC = density expansion coeff [m³/kg]
C       C      = sediment concentration [kg/m³]

C     Compute g/rho0 factor
C     In MITgcm, gravity is typically available as 'gravity'
C     For buoyancy: b = g * (ρ0 - ρ)/ρ0, so we need g
      gOverRho0 = gravity

C     Loop over all grid points
      DO k = 1, Nr
        DO j = jMin, jMax
          DO i = iMin, iMax

C           Get sediment concentration at this point
            sedConc = tracer(i,j,k,bi,bj)

C           Compute sediment buoyancy contribution
C           b_sed = -g * gammaC * C
C           (Negative because sediment increases density)
            buoy_sed = -gOverRho0 * SEDIMENT_gammaC * sedConc

C           Add to total buoyancy field
C           (buoyancy already contains T,S contributions)
            buoyancy(i,j,k) = buoyancy(i,j,k) + buoy_sed

          ENDDO
        ENDDO
      ENDDO

      RETURN
      END

C---SEDIMENT MODULE: Alternative interface for density
C
C     This version computes density modification instead of buoyancy.
C     Can be called from eos_linear.F or similar.
C
C     Density equation:
C       ρ = ρ₀[1 + γC·C]  (sediment contribution only)
C
C     or as an additive term:
C       Δρ = ρ₀ · γC · C

      SUBROUTINE SEDIMENT_EOS_DENSITY(
     I     bi, bj, iMin, iMax, jMin, jMax,
     I     tracer,
     U     rhoLocal,
     I     myThid )

      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "sediment.h"

C     === Routine arguments ===
      INTEGER bi, bj
      INTEGER iMin, iMax, jMin, jMax
      _RL tracer(1-OLx:sNx+OLx, 1-OLy:sNy+OLy, Nr, nSx, nSy)
      _RL rhoLocal(1-OLx:sNx+OLx, 1-OLy:sNy+OLy, Nr)
      INTEGER myThid

C     === Local variables ===
      INTEGER i, j, k
      _RL sedConc, delta_rho

C---SEDIMENT MODULE: Compute Sediment Density Contribution
C
C     This routine adds the sediment contribution to density.
C     The density is modified in-place (argument rhoLocal is intent INOUT).
C
C     Physics:
C       Sediment increases density
C       Δρ = ρ₀ · γC · C

      DO k = 1, Nr
        DO j = jMin, jMax
          DO i = iMin, iMax

C           Get sediment concentration at this point
            sedConc = tracer(i,j,k,bi,bj)

C           Compute sediment density contribution
C           Δρ = ρ₀ * gammaC * C
C           (Using rhoConst as ρ₀)
            delta_rho = rhoConst * SEDIMENT_gammaC * sedConc

C           Add to total density field
C           (rhoLocal already contains T,S contributions)
            rhoLocal(i,j,k) = rhoLocal(i,j,k) + delta_rho

          ENDDO
        ENDDO
      ENDDO

      RETURN
      END

#endif /* ALLOW_SEDIMENT_EOS */


