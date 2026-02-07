C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C SEDIMENT_DIAGNOSTICS
C
C Print diagnostic information about sediment field at first timestep
C to verify OBCS is working correctly
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

#include "CPP_EEOPTIONS.h"
#include "SEDIMENT_OPTIONS.h"

      SUBROUTINE SEDIMENT_DIAGNOSTICS(
     I                 myTime, myIter, myThid )

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_FIELDS.h"
#include "sediment.h"

C === Routine arguments ===
      _RL myTime
      INTEGER myIter, myThid

#ifdef ALLOW_PTRACERS
#ifdef ALLOW_SEDIMENT

C === Local variables ===
      INTEGER i, j, k, bi, bj, iTr
      _RL C_max, C_sum, C_val
      INTEGER i_max, j_max, k_max
      INTEGER bi_max, bj_max
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      
C     Only print diagnostics at specific iterations
      IF ( myIter .NE. 1 .AND. myIter .NE. 10 .AND. 
     &     myIter .NE. 100 ) RETURN
      
      iTr = SEDIMENT_tracerNum
      IF ( iTr .LT. 1 .OR. iTr .GT. PTRACERS_num ) RETURN
      
C     Find maximum sediment value and its location
      C_max = 0. _d 0
      i_max = 0
      j_max = 0
      k_max = 0
      bi_max = 0
      bj_max = 0
      C_sum = 0. _d 0
      
      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)
        DO k = 1, Nr
         DO j = 1, sNy
          DO i = 1, sNx
           IF ( maskC(i,j,k,bi,bj) .GT. 0. _d 0 ) THEN
             C_val = pTracer(i,j,k,bi,bj,iTr)
             C_sum = C_sum + C_val
             IF ( C_val .GT. C_max ) THEN
               C_max = C_val
               i_max = i
               j_max = j
               k_max = k
               bi_max = bi
               bj_max = bj
             ENDIF
           ENDIF
          ENDDO
         ENDDO
        ENDDO
       ENDDO
      ENDDO
      
      _BEGIN_MASTER( myThid )
      
      WRITE(msgBuf,'(A,I8)') 
     &  '=== SEDIMENT DIAGNOSTIC at iter=', myIter
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
     
      WRITE(msgBuf,'(A,E12.4)') 
     &  'Max sediment concentration: ', C_max
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
     
      WRITE(msgBuf,'(A,I4,A,I4,A,I4)') 
     &  'Location: i=', i_max, ' j=', j_max, ' k=', k_max
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
     
      WRITE(msgBuf,'(A,I2,A,I2)') 
     &  'Tile: bi=', bi_max, ' bj=', bj_max
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
     
      IF ( k_max .LE. 5 ) THEN
        WRITE(msgBuf,'(A)') 
     &    'WARNING: Max sediment near SURFACE (k<=5)!'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
      ELSEIF ( k_max .GE. 35 ) THEN
        WRITE(msgBuf,'(A)') 
     &    'Expected: Max sediment near BOTTOM (k>=35)'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
      ELSE
        WRITE(msgBuf,'(A)') 
     &    'Sediment in mid-depth (unexpected for conduit at bottom)'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
      ENDIF
      
      _END_MASTER( myThid )

#endif /* ALLOW_SEDIMENT */
#endif /* ALLOW_PTRACERS */

      RETURN
      END
