C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C SEDIMENT_READPARMS
C
C Read sediment parameters from data.sediment namelist
C
C Called from: packages_readparms.F (via PACKAGES_INIT_FIXED)
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

#include "CPP_EEOPTIONS.h"
#include "SEDIMENT_OPTIONS.h"

      SUBROUTINE SEDIMENT_READPARMS( myThid )

      IMPLICIT NONE

C === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "sediment.h"

C === Routine arguments ===
      INTEGER myThid

#ifdef ALLOW_PTRACERS
#ifdef ALLOW_SEDIMENT

C === Local variables ===
      CHARACTER*(MAX_LEN_FNAM) namBuf
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER iUnit, errIO

C === Namelist variables ===
C     SEDIMENT_ws0       :: Settling velocity [m/s]
C     SEDIMENT_gammaC    :: Density expansion coefficient [m³/kg]
C     SEDIMENT_rhoSed    :: Reference sediment grain density [kg/m³]
C     SEDIMENT_tracerNum :: Which ptracer is the sediment (default 1)
C     SEDIMENT_buoyancyOn :: Enable buoyancy coupling (Cycle 7)
      NAMELIST /SEDIMENT_PARM01/
     &     SEDIMENT_ws0,
     &     SEDIMENT_gammaC,
     &     SEDIMENT_rhoSed,
     &     SEDIMENT_tracerNum,
     &     SEDIMENT_buoyancyOn

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Set defaults
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

C     Default settling velocity: 0.01 m/s (medium sediment)
      SEDIMENT_ws0 = 0.01 _d 0

C     Default density expansion coefficient: 6.2e-4 m³/kg (quartz in water)
C     γC = (ρ_sed - ρ_w) / (ρ_sed * ρ_w) = (2650-1000)/(2650*1000)
      SEDIMENT_gammaC = 6.2 _d -4

C     Default grain density: 2650 kg/m³ (quartz)
      SEDIMENT_rhoSed = 2650. _d 0

C     Default tracer number: 1 (first passive tracer)
      SEDIMENT_tracerNum = 1

C     Default buoyancy coupling: OFF (passive tracer mode)
C     Set to .TRUE. in data.sediment to enable Cycle 7 coupling
      SEDIMENT_buoyancyOn = .FALSE.

C     Initialize CFL warning flag
      SEDIMENT_cflWarn = .FALSE.
      SEDIMENT_cflWarnCount = 0
      SEDIMENT_cflSet = 0. _d 0

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Read namelist from data.sediment
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      IF ( myThid .EQ. 1 ) THEN
        WRITE(msgBuf,'(A)') 
     &    'SEDIMENT_READPARMS: Reading data.sediment'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
      ENDIF

C     Open file
      CALL OPEN_COPY_DATA_FILE(
     I                   'data.sediment', 'SEDIMENT_READPARMS',
     O                   iUnit,
     I                   myThid )

C     Read namelist
      READ(UNIT=iUnit,NML=SEDIMENT_PARM01,IOSTAT=errIO)
      IF ( errIO .LT. 0 ) THEN
        WRITE(msgBuf,'(A)')
     &    'SEDIMENT_READPARMS: Error reading data.sediment'
        CALL PRINT_ERROR( msgBuf, myThid )
        WRITE(msgBuf,'(A)')
     &    'Check that SEDIMENT_PARM01 namelist exists'
        CALL PRINT_ERROR( msgBuf, myThid )
        STOP 'ABNORMAL END: S/R SEDIMENT_READPARMS'
      ENDIF

#ifdef SINGLE_DISK_IO
      CLOSE(iUnit)
#else
      CLOSE(iUnit,STATUS='DELETE')
#endif

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Print parameters
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      IF ( myThid .EQ. 1 ) THEN
        WRITE(msgBuf,'(A)') 
     &    '---SEDIMENT_READPARMS: Parameters read---'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        
        WRITE(msgBuf,'(A,1PE12.4,A)') 
     &    '  SEDIMENT_ws0    = ', SEDIMENT_ws0, ' m/s'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        
        WRITE(msgBuf,'(A,1PE12.4,A)') 
     &    '  SEDIMENT_gammaC = ', SEDIMENT_gammaC, ' m³/kg'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        
        WRITE(msgBuf,'(A,1PE12.4,A)') 
     &    '  SEDIMENT_rhoSed = ', SEDIMENT_rhoSed, ' kg/m³'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        
        WRITE(msgBuf,'(A,I2)') 
     &    '  SEDIMENT_tracerNum = ', SEDIMENT_tracerNum
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )

#ifdef ALLOW_SEDIMENT_BUOYANCY
        IF ( SEDIMENT_buoyancyOn ) THEN
          WRITE(msgBuf,'(A)') 
     &      '  SEDIMENT_buoyancyOn = TRUE (density coupling ENABLED)'
        ELSE
          WRITE(msgBuf,'(A)') 
     &      '  SEDIMENT_buoyancyOn = FALSE (passive tracer mode)'
        ENDIF
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
#endif
        
        WRITE(msgBuf,'(A)') 
     &    '---SEDIMENT_READPARMS: End---'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
      ENDIF

#endif /* ALLOW_SEDIMENT */
#endif /* ALLOW_PTRACERS */

      RETURN
      END

