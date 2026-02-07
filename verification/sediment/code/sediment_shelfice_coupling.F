#include "CPP_EEOPTIONS.h"
#include "SEDIMENT_OPTIONS.h"

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
CBOP
C !ROUTINE: SEDIMENT_SHELFICE_MODIFY_GAMMA

C !INTERFACE: ==========================================================
      SUBROUTINE SEDIMENT_SHELFICE_MODIFY_GAMMA(
     I                bi, bj,
     U                shiTransCoeffT_loc, shiTransCoeffS_loc,
     I                myTime, myIter, myThid )

C !DESCRIPTION:
C     Modify SHELFICE transfer coefficients based on sediment concentration
C     in the ice-ocean boundary layer.
C
C     Physics:
C     --------
C     Sediment in the boundary layer increases turbulence and heat transfer
C     via enhanced roughness at the ice-ocean interface.

C !USES: ===============================================================
      IMPLICIT NONE
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "DYNVARS.h"
#ifdef ALLOW_SHELFICE
#include "SHELFICE.h"
#endif
#ifdef ALLOW_PTRACERS
#include "PTRACERS_SIZE.h"
#include "PTRACERS_FIELDS.h"
#endif
#include "sediment.h"

C !INPUT/OUTPUT PARAMETERS: ============================================
C     bi, bj              :: tile indices
C     shiTransCoeffT_loc  :: heat transfer coefficient (modified in place)
C     shiTransCoeffS_loc  :: salt transfer coefficient (modified in place)
C     myTime              :: current time
C     myIter              :: current iteration
C     myThid              :: thread number
      INTEGER bi, bj
      _RL shiTransCoeffT_loc(1-OLx:sNx+OLx, 1-OLy:sNy+OLy)
      _RL shiTransCoeffS_loc(1-OLx:sNx+OLx, 1-OLy:sNy+OLy)
      _RL myTime
      INTEGER myIter, myThid

#ifdef ALLOW_PTRACERS
#ifdef ALLOW_SEDIMENT
#ifdef ALLOW_SEDIMENT_SHELFICE
#ifdef ALLOW_SEDIMENT_MELT_FEEDBACK

C !LOCAL VARIABLES: ====================================================
      INTEGER i, j, K, Kp1, iTr
      _RL C_BL             ! Boundary layer sediment concentration
      _RL C_sed            ! Sediment at ice-ocean cell
      _RL factor           ! Enhancement factor
      _RL drKp1, recip_drLoc
CEOP

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Check if coupling is enabled
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      IF ( .NOT. SEDIMENT_shelficeOn ) RETURN

C     Get sediment tracer index
      iTr = SEDIMENT_tracerNum
      IF ( iTr .LT. 1 .OR. iTr .GT. PTRACERS_num ) RETURN

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Loop over ice-shelf cells and modify transfer coefficients
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      DO j = 1, sNy
        DO i = 1, sNx
          K = kTopC(i,j,bi,bj)
          
C         Skip if no ice shelf at this point
          IF ( K .EQ. 0 ) GOTO 100
          
C         Get sediment concentration in ice-ocean cell
          C_sed = pTracer(i,j,K,bi,bj,iTr)
          
C         Ensure non-negative
          IF ( C_sed .LT. 0. _d 0 ) C_sed = 0. _d 0
          
C         Average over boundary layer if SHELFICEboundaryLayer is on
          IF ( SHELFICEboundaryLayer .AND. K .LT. Nr ) THEN
            Kp1 = MIN(Nr, K+1)
C           Overlap into lower cell
            drKp1 = drF(K) * ( 1. _d 0 - _hFacC(i,j,K,bi,bj) )
            drKp1 = MIN( drKp1, drF(Kp1) * _hFacC(i,j,Kp1,bi,bj) )
            drKp1 = MAX( drKp1, 0. _d 0 )
            recip_drLoc = 1. _d 0 /
     &           ( drF(K)*_hFacC(i,j,K,bi,bj) + drKp1 )
            
C           Average sediment over boundary layer
            C_BL = ( C_sed * drF(K) * _hFacC(i,j,K,bi,bj)
     &           + MAX(0. _d 0, pTracer(i,j,Kp1,bi,bj,iTr)) * drKp1 )
     &           * recip_drLoc
          ELSE
            C_BL = C_sed
          ENDIF
          
C         Compute enhancement factor: gamma_eff = gamma * (1 + alpha * C)
C         SEDIMENT_meltFactor is alpha [m^3/kg], so alpha*C is dimensionless
          factor = 1. _d 0 + SEDIMENT_meltFactor * C_BL
          
C         Limit enhancement to reasonable bounds (0.5x to 3x)
          factor = MAX( 0.5 _d 0, MIN( 3. _d 0, factor ) )
          
C         Apply enhancement to transfer coefficients
          shiTransCoeffT_loc(i,j) = shiTransCoeffT_loc(i,j) * factor
          shiTransCoeffS_loc(i,j) = shiTransCoeffS_loc(i,j) * factor

 100      CONTINUE
        ENDDO
      ENDDO

#endif /* ALLOW_SEDIMENT_MELT_FEEDBACK */
#endif /* ALLOW_SEDIMENT_SHELFICE */
#endif /* ALLOW_SEDIMENT */
#endif /* ALLOW_PTRACERS */

      RETURN
      END

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
CBOP
C !ROUTINE: SEDIMENT_SHELFICE_SGD_FORCING

C !INTERFACE: ==========================================================
      SUBROUTINE SEDIMENT_SHELFICE_SGD_FORCING(
     I                bi, bj, K,
     O                sedTend,
     I                myTime, myIter, myThid )

C !DESCRIPTION:
C     Apply subglacial discharge (SGD) sediment source at grounding line.
C     Source = SEDIMENT_sgdFlux * SEDIMENT_sgdConc / cellVol [kg/m^3/s]
C
C     Called from: ptracers_apply_forcing.F

C !USES: ===============================================================
      IMPLICIT NONE
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#ifdef ALLOW_SHELFICE
#include "SHELFICE.h"
#endif
#include "sediment.h"

C !INPUT/OUTPUT PARAMETERS: ============================================
C     bi, bj    :: tile indices
C     K         :: vertical level
C     sedTend   :: sediment tendency from SGD [kg/m^3/s]
C     myTime    :: current time
C     myIter    :: current iteration
C     myThid    :: thread number
      INTEGER bi, bj, K
      _RL sedTend(1-OLx:sNx+OLx, 1-OLy:sNy+OLy)
      _RL myTime
      INTEGER myIter, myThid

#ifdef ALLOW_PTRACERS
#ifdef ALLOW_SEDIMENT
#ifdef ALLOW_SEDIMENT_SHELFICE
#ifdef ALLOW_SEDIMENT_SUBGLACIAL_DISCHARGE

C !LOCAL VARIABLES: ====================================================
      INTEGER i, j, n, iSgd, jSgd
      _RL sgdSource
      _RL cellVol
      _RL zBot, zTop, zSgdBot, zSgdTop, overlap
CEOP

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Check if SGD is enabled
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      IF ( .NOT. SEDIMENT_shelficeOn ) RETURN
      IF ( SEDIMENT_sgdNpts .LT. 1 ) RETURN
      IF ( SEDIMENT_sgdFlux .LE. 0. _d 0 ) RETURN

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Initialize tendency to zero
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      DO j = 1-OLy, sNy+OLy
        DO i = 1-OLx, sNx+OLx
          sedTend(i,j) = 0. _d 0
        ENDDO
      ENDDO

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Apply SGD sediment source at grounding line cells
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      DO n = 1, SEDIMENT_sgdNpts
        iSgd = SEDIMENT_sgdI(n)
        jSgd = SEDIMENT_sgdJ(n)
        
C       Check if this SGD point is in this tile
        IF ( iSgd .LT. 1 .OR. iSgd .GT. sNx ) GOTO 200
        IF ( jSgd .LT. 1 .OR. jSgd .GT. sNy ) GOTO 200
        
C       Check if this level is within the SGD injection depth
C       SGD is injected at the ice base, extending down SEDIMENT_sgdDepth
C       
C       Vertical extent of SGD plume:
C       zTop = R_shelfIce (ice base)
C       zBot = R_shelfIce - SEDIMENT_sgdDepth
        zSgdTop = R_shelfIce(iSgd,jSgd,bi,bj)
        zSgdBot = zSgdTop - SEDIMENT_sgdDepth
        
C       Cell boundaries
        zTop = rF(K)
        zBot = rF(K+1)
        
C       Compute overlap between SGD layer and this cell
        overlap = MAX( 0. _d 0,
     &            MIN(zTop, zSgdTop) - MAX(zBot, zSgdBot) )
        
        IF ( overlap .GT. 0. _d 0 ) THEN
C         Cell volume [m^3]
          cellVol = rA(iSgd,jSgd,bi,bj) * drF(K) 
     &              * _hFacC(iSgd,jSgd,K,bi,bj)
          
          IF ( cellVol .GT. 0. _d 0 ) THEN
C           SGD source for this cell [kg/m^3/s]
C           Distribute flux vertically based on overlap
            sgdSource = SEDIMENT_sgdFlux * SEDIMENT_sgdConc
     &                * (overlap / SEDIMENT_sgdDepth)
     &                / cellVol
            
            sedTend(iSgd,jSgd) = sedTend(iSgd,jSgd) + sgdSource
          ENDIF
        ENDIF

 200    CONTINUE
      ENDDO

#endif /* ALLOW_SEDIMENT_SUBGLACIAL_DISCHARGE */
#endif /* ALLOW_SEDIMENT_SHELFICE */
#endif /* ALLOW_SEDIMENT */
#endif /* ALLOW_PTRACERS */

      RETURN
      END
