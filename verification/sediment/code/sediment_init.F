C---SEDIMENT MODULE BEGIN
C
C     sediment_init.F
C
C     Initialization routine for sediment tracer module - Cycle 2
C
C     PURPOSE:
C     --------
C     - Read sediment parameters from data.sediment namelist
C     - Initialize sediment tracer in PTRACERS package
C     - Compute and verify CFL stability criterion
C     - Initialize EOS coupling parameters
C     - Print diagnostics
C
C     PARAMETERS REQUIRED IN data.sediment:
C     SEDIMENT_ws0    = settling velocity [m/s]
C     SEDIMENT_gammaC = density expansion coefficient [m³/kg]
C     SEDIMENT_rhoSed = grain density [kg/m³] (optional)
C
C     KEY CHECKS:
C     - CFLset = ws0 * deltaT / min(delZ) must be < 0.5
C     - gammaC should be O(1e-3) for typical sediment
C
C---SEDIMENT MODULE END

#include "CPP_EEOPTIONS.h"
#include "SEDIMENT_OPTIONS.h"

      SUBROUTINE SEDIMENT_INIT( myThid )
      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "sediment.h"

C     === Routine arguments ===
      INTEGER myThid

C     === Local variables ===
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      _RL minDelZ, cflCheck
      INTEGER k, kMin
      LOGICAL errFlag

C---SEDIMENT MODULE: Read Sediment Parameters
C
C     This section reads parameters from the data.sediment namelist.
C     All parameters have defaults but should be explicitly set for
C     new configurations.

      IF ( myThid .EQ. 1 ) THEN
       WRITE(msgBuf,'(A)') 'SEDIMENT_INIT: Initializing sediment module'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                     SQUEEZE_RIGHT, myThid )
      ENDIF

C     Read from data.sediment namelist (handled by S/R _READPARMS)
C     SEDIMENT_ws0, SEDIMENT_gammaC should be set there

C     ===================================================================
C     CYCLE 1: SETTLING VELOCITY AND CFL CHECK
C     ===================================================================

      IF ( myThid .EQ. 1 ) THEN

C       Find minimum vertical grid spacing
        minDelZ = 1.E20
        kMin = 1
        DO k = 1, Nr
          IF ( delZ(k) .LT. minDelZ ) THEN
            minDelZ = delZ(k)
            kMin = k
          ENDIF
        ENDDO

C       Compute CFL number for settling: CFLset = ws0*dt/dz_min
        IF ( minDelZ .GT. 0. ) THEN
          cflCheck = SEDIMENT_ws0 * deltaT / minDelZ
        ELSE
          cflCheck = 0.
        ENDIF
        SEDIMENT_cflSet = cflCheck

C       Check stability
        errFlag = .FALSE.
        IF ( cflCheck .GE. 0.5 ) THEN
          SEDIMENT_cflWarn = .TRUE.
          SEDIMENT_cflWarnCount = SEDIMENT_cflWarnCount + 1
          WRITE(msgBuf,'(A,1PE12.4)') 
     &      'WARNING: Sediment CFL exceeds 0.5: CFLset = ', cflCheck
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                        SQUEEZE_RIGHT, myThid )
          WRITE(msgBuf,'(A,1PE12.4,A,1PE12.4)') 
     &      '  ws0=', SEDIMENT_ws0, ' dt=', deltaT
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                        SQUEEZE_RIGHT, myThid )
          WRITE(msgBuf,'(A,I3,A,1PE12.4)') 
     &      '  min(delZ) at k=', kMin, ' is ', minDelZ
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                        SQUEEZE_RIGHT, myThid )
        ENDIF

C     ===================================================================
C     CYCLE 2: EOS COUPLING CHECKS
C     ===================================================================

#ifdef ALLOW_SEDIMENT_EOS
C       Check that gammaC is reasonable
C       Typical range: 1e-4 to 1e-2 m³/kg
        IF ( SEDIMENT_gammaC .LT. 1.E-6 .OR. 
     &       SEDIMENT_gammaC .GT. 1.E-1 ) THEN
          WRITE(msgBuf,'(A,1PE12.4)') 
     &      'WARNING: SEDIMENT_gammaC outside typical range: ', 
     &      SEDIMENT_gammaC
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                        SQUEEZE_RIGHT, myThid )
          WRITE(msgBuf,'(A)') 
     &      '  Expected range: 1e-4 to 1e-2 m³/kg'
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                        SQUEEZE_RIGHT, myThid )
        ENDIF

C       If rhoSed is provided, compute implied gammaC
C       gammaC = (rhoSed - rho0) / rho0
C       (This is informational; we use the namelist value)
        IF ( SEDIMENT_rhoSed .GT. 0. ) THEN
          WRITE(msgBuf,'(A,1PE12.4,A)') 
     &      '  Reference sediment density rhoSed = ', 
     &      SEDIMENT_rhoSed, ' kg/m³'
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                        SQUEEZE_RIGHT, myThid )
        ENDIF
#endif /* ALLOW_SEDIMENT_EOS */

C       Print diagnostics
        WRITE(msgBuf,'(A)') 
     &    '---SEDIMENT_INIT: Parameters---'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A,1PE12.4,A)') 
     &    '  Settling velocity ws0 = ', SEDIMENT_ws0, ' m/s'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A,1PE12.4)') 
     &    '  Time step deltaT = ', deltaT
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A,1PE12.4,A,I3)') 
     &    '  Min grid spacing = ', minDelZ, ' m (at k=', kMin, ')'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A,1PE12.4)') 
     &    '  CFL number CFLset = ', SEDIMENT_cflSet
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )

#ifdef ALLOW_SEDIMENT_EOS
        WRITE(msgBuf,'(A,1PE12.4,A)') 
     &    '  Density expansion coeff gammaC = ', 
     &    SEDIMENT_gammaC, ' m³/kg'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
#endif

        WRITE(msgBuf,'(A)') 
     &    '---SEDIMENT_INIT: End---'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )

      ENDIF

      RETURN
      END



