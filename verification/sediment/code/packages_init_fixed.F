#include "PACKAGES_CONFIG.h"
#include "CPP_OPTIONS.h"
#include "SEDIMENT_OPTIONS.h"

CBOP
C     !ROUTINE: PACKAGES_INIT_FIXED
C     !INTERFACE:
      SUBROUTINE PACKAGES_INIT_FIXED( myThid )

C     !DESCRIPTION: \bv
C     *==========================================================*
C     | SUBROUTINE PACKAGES_INIT_FIXED
C     | o Does initialisation of package-related fixed fields
C     |   Modified to include SEDIMENT_INIT call
C     *==========================================================*
C     \ev

C     !USES:
      IMPLICIT NONE
C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"

C     !INPUT/OUTPUT PARAMETERS:
      INTEGER myThid
CEOP

#ifdef ALLOW_DEBUG
      IF (debugMode) CALL DEBUG_ENTER('PACKAGES_INIT_FIXED',myThid)
#endif

#ifdef ALLOW_RUNCLOCK
      IF ( useRunClock ) THEN
        CALL RUNCLOCK_INIT( myThid )
      ENDIF
#endif

#ifdef ALLOW_CAL
      IF ( useCAL ) THEN
        CALL CAL_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_DIAGNOSTICS
      IF ( useDiagnostics ) THEN
        CALL DIAGNOSTICS_INIT_EARLY( myThid )
        CALL DIAGNOSTICS_MAIN_INIT( myThid )
      ENDIF
#endif

#ifdef ALLOW_NEST2W_COMMON
      IF ( useNest2W_parent .OR. useNest2W_child ) THEN
        CALL NEST2W_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_GENERIC_ADVDIFF
      CALL GAD_INIT_FIXED( myThid )
#endif

#ifdef ALLOW_MOM_COMMON
      IF ( momStepping ) THEN
        CALL MOM_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_CD_CODE
      IF (useCDscheme) THEN
        CALL CD_CODE_INIT_FIXED(myThid)
      ENDIF
#endif

#ifdef ALLOW_OBCS
      IF (useOBCS) THEN
        CALL OBCS_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_SHAP_FILT
      IF (useSHAP_FILT) THEN
        CALL SHAP_FILT_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_ZONAL_FILT
      IF (useZONAL_FILT) THEN
        CALL ZONAL_FILT_INIT(myThid)
      ENDIF
#endif

#ifdef ALLOW_EXF
      IF ( useEXF ) THEN
        CALL EXF_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_CHEAPAML
      IF ( useCheapAML ) THEN
        CALL CHEAPAML_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_OPPS
      IF (useOPPS) THEN
        CALL OPPS_INIT( myThid )
      ENDIF
#endif

#ifdef ALLOW_PP81
      IF ( usePP81 ) THEN
        CALL PP81_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_KL10
      IF ( useKL10 ) THEN
        CALL KL10_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_MY82
      IF ( useMY82 ) THEN
        CALL MY82_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_GGL90
      IF ( useGGL90 ) THEN
        CALL GGL90_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_KPP
      IF ( useKPP ) THEN
        CALL KPP_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_GMREDI
      IF ( useGMRedi ) THEN
        CALL GMREDI_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_BBL
      IF ( useBBL ) THEN
        CALL BBL_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_DOWN_SLOPE
      IF ( useDOWN_SLOPE ) THEN
        CALL DWNSLP_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_SEAICE
      IF (useSEAICE) THEN
        CALL SEAICE_COST_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_ECCO
      IF (useECCO) THEN
        CALL ECCO_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_PROFILES
      IF (usePROFILES) THEN
        CALL PROFILES_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_FLT
      IF ( useFLT ) THEN
        CALL FLT_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_LONGSTEP
      IF (usePTRACERS) THEN
        CALL LONGSTEP_INIT_FIXED(myThid)
      ENDIF
#endif

#ifdef ALLOW_PTRACERS
      IF (usePTRACERS) THEN
        CALL PTRACERS_INIT_FIXED(myThid)
      ENDIF
#endif

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     SEDIMENT PACKAGE: Initialize sediment module
C     This must be called AFTER PTRACERS_INIT_FIXED
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
#ifdef ALLOW_SEDIMENT
      CALL SEDIMENT_INIT( myThid )
#endif

#ifdef ALLOW_GCHEM
      IF (useGCHEM) THEN
        CALL GCHEM_INIT_FIXED(myThid)
      ENDIF
#endif

#ifdef ALLOW_RBCS
      IF (useRBCS) THEN
        CALL RBCS_INIT_FIXED(myThid)
      ENDIF
#endif

#ifdef ALLOW_STREAMICE
      IF (useStreamIce) THEN
#ifndef ALLOW_OPENAD
       CALL STREAMICE_INIT_FIXED( myThid )
#else
       CALL OPENAD_STREAMICE_INIT_FIXED( myThid )
#endif
      ENDIF
#endif

#ifdef ALLOW_SHELFICE
      IF (useShelfIce) THEN
        CALL SHELFICE_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_STEEP_ICECAVITY
      IF (useSTIC) THEN
        CALL STIC_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_SMOOTH
      IF (useSMOOTH) THEN
        CALL SMOOTH_INIT_FIXED(myThid)
      ENDIF
#endif

#ifdef ALLOW_ICEFRONT
      IF (useICEFRONT) THEN
        CALL ICEFRONT_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_FRAZIL
      IF (useFRAZIL) THEN
        CALL FRAZIL_INIT_FIXED(myThid)
      ENDIF
#endif

#ifdef ALLOW_SEAICE
      IF (useSEAICE) THEN
        CALL SEAICE_INIT_FIXED(myThid)
      ENDIF
#endif

#ifdef ALLOW_SALT_PLUME
      IF (useSALT_PLUME) THEN
        CALL SALT_PLUME_INIT_FIXED(myThid)
      ENDIF
#endif

#ifdef ALLOW_THSICE
      IF (useThSIce) THEN
        CALL THSICE_INIT_FIXED(myThid)
      ENDIF
#endif

#ifdef ALLOW_LAND
      IF ( useLand ) THEN
        CALL LAND_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_ATM2D
      IF ( useAtm2d ) THEN
        CALL ATM2D_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_AIM
      IF (useAIM) THEN
        CALL AIM_INITIALISE( myThid )
      ENDIF
#endif

#ifdef ALLOW_ATM_PHYS
      IF ( useAtm_Phys ) THEN
        CALL ATM_PHYS_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_FIZHI
      IF (useFIZHI) THEN
        CALL FIZHI_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_GRIDALT
      IF (useGRIDALT) then
        CALL GRIDALT_INITIALISE( myThid )
      ENDIF
#endif

#ifdef ALLOW_REGRID
      IF ( useREGRID ) THEN
        CALL REGRID_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_LAYERS
      IF ( useLayers ) THEN
        CALL LAYERS_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef COMPONENT_MODULE
      IF ( useCoupler ) THEN
        CALL CPL_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_OASIS
      IF (useOASIS) THEN
        CALL OASIS_INIT_FIXED(myThid)
      ENDIF
#endif

#ifdef ALLOW_EMBED_FILES
      IF ( useEMBED_FILES ) THEN
        CALL EMBED_FILES_INIT( myThid )
      ENDIF
#endif

#ifdef ALLOW_MYPACKAGE
      IF (useMYPACKAGE) THEN
        CALL MYPACKAGE_INIT_FIXED(myThid)
      ENDIF
#endif

#ifdef ALLOW_CTRL
      IF (useCTRL) THEN
        CALL CTRL_INIT_FIXED( myThid )
      ENDIF
# ifdef ALLOW_ADMTLM
      IF (useCTRL) THEN
        CALL CTRL_ADMTLM( myThid )
      ENDIF
# endif
#endif

#ifdef ALLOW_DIAGNOSTICS
      IF ( useDiagnostics ) THEN
        CALL DIAGNOSTICS_INIT_FIXED( myThid )
      ENDIF
#endif

#ifdef ALLOW_DEBUG
      IF (debugMode) CALL DEBUG_LEAVE('PACKAGES_INIT_FIXED',myThid)
#endif

      RETURN
      END
