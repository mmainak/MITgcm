C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C SEDIMENT_APPLY_OUTFLOW_BC
C
C Apply zero-gradient outflow boundary condition for sediment at east boundary
C This allows sediment to exit the domain without accumulation
C
C Physics:
C   At outflow boundary: ∂C/∂x = 0 (zero gradient)
C   Implementation: C(i=Nx) = C(i=Nx-1) (copy from interior)
C
C Called from: After OBCS_APPLY_PTRACER to handle tracer outflow
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

#include "CPP_EEOPTIONS.h"
#include "SEDIMENT_OPTIONS.h"

      SUBROUTINE SEDIMENT_APPLY_OUTFLOW_BC(
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
      INTEGER bi, bj, myThid

#ifdef ALLOW_PTRACERS
#ifdef ALLOW_SEDIMENT

C === Local variables ===
      INTEGER i, j, k, iTr

C     Get sediment tracer index
      iTr = SEDIMENT_tracerNum
      IF ( iTr .LT. 1 .OR. iTr .GT. PTRACERS_num ) RETURN

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Apply zero-gradient BC at domain boundaries
C
C     For east boundary (i=sNx on eastern-most tiles):
C       Set C(i=sNx) = C(i=sNx-1) to allow outflow
C
C     This is applied AFTER OBCS, so it overrides any OBCS prescription
C     at the east boundary, creating a zero-gradient outflow condition
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

C     Loop over all vertical levels and y-coordinates
      DO k = 1, Nr
        DO j = 1, sNy
C         Check if this is an ocean point
          IF ( maskC(sNx,j,k,bi,bj) .GT. 0. _d 0 ) THEN
C           Zero-gradient: copy from interior cell
            pTracer(sNx,j,k,bi,bj,iTr) = 
     &           pTracer(sNx-1,j,k,bi,bj,iTr)
          ENDIF
        ENDDO
      ENDDO

#endif /* ALLOW_SEDIMENT */
#endif /* ALLOW_PTRACERS */

      RETURN
      END
