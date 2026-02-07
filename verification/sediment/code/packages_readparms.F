#include "PACKAGES_CONFIG.h"
#include "CPP_OPTIONS.h"
#include "SEDIMENT_OPTIONS.h"

CBOP
C     !ROUTINE: PACKAGES_READPARMS
C     !INTERFACE:
      SUBROUTINE PACKAGES_READPARMS(myThid)

C     !DESCRIPTION: \bv
C     *==========================================================*
C     | SUBROUTINE PACKAGES_READPARMS
C     | o Read runtime package configuration parameters
C     *==========================================================*
C     |   Modified version that adds SEDIMENT_READPARMS call
C     |   after PTRACERS_READPARMS
C     *==========================================================*
C     \ev

C     !USES:
      IMPLICIT NONE
C     == Global variables ==
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"

C     == Routine arguments ==
      INTEGER myThid
CEOP

#ifdef ALLOW_MNC
C--   if useMNC=T, read run-time flags for MNC; otherwise just return
      CALL MNC_READPARMS( myThid )
#endif

#ifdef ALLOW_CAL
C--   if useCAL=T, set the calendar package parameters.
      CALL CAL_READPARMS( myThid )
#endif

#ifdef ALLOW_EXF
C--   if useEXF=T, set EXF parameters; otherwise just return
      CALL EXF_READPARMS  ( myThid )
#endif

#ifdef ALLOW_OBCS
C--   if useOBCS=T, set OBCS parameters; otherwise just return
      CALL OBCS_READPARMS( myThid )
#endif

#ifdef ALLOW_SHAP_FILT
C--   if useSHAP_FILT=T, set Shapiro-Filter parameters
      CALL SHAP_FILT_READPARMS( myThid )
#endif

#ifdef ALLOW_ZONAL_FILT
C--   if useZONAL_FILT=T, set Zonal-Filter parameters
      CALL ZONAL_FILT_READPARMS( myThid )
#endif

#ifdef ALLOW_OPPS
C--   if useOPPS=T, set OPPS parameters
      CALL OPPS_READPARMS( myThid )
#endif

#ifdef ALLOW_PP81
C--   if usePP81=T, set PP81 parameters
      CALL PP81_READPARMS( myThid )
#endif

#ifdef ALLOW_KL10
C--   if useKL10=T, set KL10 parameters
      CALL KL10_READPARMS( myThid )
#endif

#ifdef ALLOW_MY82
C--   if useMY82=T, set MY82 parameters
      CALL MY82_READPARMS( myThid )
#endif

#ifdef ALLOW_GGL90
C--   if useGGL90=T, set GGL90 parameters
      CALL GGL90_READPARMS( myThid )
#endif

#ifdef ALLOW_KPP
C--   if useKPP=T, set KPP parameters
      CALL KPP_READPARMS( myThid )
#endif

#ifdef ALLOW_GMREDI
C--   if useGMRedi=T, set GM/Redi parameters
      CALL GMREDI_READPARMS( myThid )
#endif

#ifdef ALLOW_BBL
C--   if useBBL=T, set BBL parameters
      CALL BBL_READPARMS( myThid )
#endif

#ifdef ALLOW_DOWN_SLOPE
C--   if useDOWN_SLOPE=T, set Down-Slope flow parameters
      CALL DWNSLP_READPARMS( myThid )
#endif

#ifdef ALLOW_BULK_FORCE
C--   if useBulkForce=T, set BULKF parameters
      CALL BULKF_READPARMS( myThid )
#endif

#ifdef ALLOW_EBM
C--   if useEBM=T, set EBM parameters
      CALL EBM_READPARMS( myThid )
#endif

#ifdef ALLOW_CHEAPAML
C--   if useCheapAML=T, set CheapAML parameters
      CALL CHEAPAML_READPARMS( myThid )
#endif

#ifdef ALLOW_FLT
C--   if useFLT=T, set Floats (FLT) parameters
      CALL FLT_READPARMS( myThid )
#endif

#ifdef ALLOW_LONGSTEP
C--   need to call LONGSTEP_READPARMS before PTRACERS_READPARMS
      CALL LONGSTEP_READPARMS( myThid )
#endif

#ifdef ALLOW_PTRACERS
C--   if usePTRACERS=T, set Passive-Traces parameters
      CALL PTRACERS_READPARMS( myThid )
#endif

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     SEDIMENT PACKAGE: Read parameters from data.sediment
C     This must be called AFTER PTRACERS_READPARMS to know tracer count
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
#ifdef ALLOW_SEDIMENT
      CALL SEDIMENT_READPARMS( myThid )
#endif

#ifdef ALLOW_GCHEM
C--   if useGCHEM=T, set GCHEM parameters
      CALL GCHEM_READPARMS( myThid )
#endif

#ifdef ALLOW_RBCS
C--   if useRBCS=T, set RBCS parameters
      CALL RBCS_READPARMS( myThid )
#endif

#ifdef ALLOW_OFFLINE
C--   if useOffLine=T, set OFFLINE parameters
      CALL OFFLINE_READPARMS( myThid )
#endif

#ifdef ALLOW_MATRIX
C--   if useMATRIX=T, set MATRIX parameters
      CALL MATRIX_READPARMS ( myThid )
#endif

#ifdef ALLOW_STREAMICE
C--   if useStreamIce=T, set STREAMICE parameters
      CALL STREAMICE_READPARMS( myThid )
#endif

#ifdef ALLOW_SHELFICE
C--   if useShelfIce=T, set SHELFICE parameters
      CALL SHELFICE_READPARMS( myThid )
#endif

#ifdef ALLOW_STEEP_ICECAVITY
C--   if useSTIC=T, set STEEP_ICECAVITY parameters
      CALL STIC_READPARMS( myThid )
#endif

#ifdef ALLOW_ICEFRONT
C--   if useICEFRONT=T, set ICEFRONT parameters
      CALL ICEFRONT_READPARMS( myThid )
#endif

#ifdef ALLOW_SEAICE
C--   if useSEAICE=T, set SEAICE parameters
      CALL SEAICE_READPARMS( myThid )
#endif

#ifdef ALLOW_SALT_PLUME
C--   if useSALT_PLUME=T, set SALT_PLUME parameters
      CALL SALT_PLUME_READPARMS( myThid )
#endif

#ifdef ALLOW_THSICE
C--   if useThSIce=T, set Therm.Sea-Ice parameters
      CALL THSICE_READPARMS( myThid )
#endif

#ifdef ALLOW_LAND
C--   if useLand=T, set LAND pkg parameters
      CALL LAND_READPARMS( myThid )
#endif

#ifdef ALLOW_AUTODIFF
C--   Initialise autodiff parameters
      CALL AUTODIFF_READPARMS( myThid )
#endif

#ifdef ALLOW_CTRL
C--   Initialise the optim. parameters
      CALL OPTIM_READPARMS( myThid )
C--   Initialise the control parameters
      CALL CTRL_READPARMS( myThid )
#endif

#ifdef ALLOW_COST
C--   Initialise the cost parameters
      CALL COST_READPARMS( myThid )
#endif

#ifdef ALLOW_GRDCHK
C--   if useGrdChk=T, set gradient-check parameters
      CALL GRDCHK_READPARMS( myThid )
#endif

#ifdef ALLOW_SMOOTH
C--   if useSMOOTH=T, set SMOOTH parameters
      CALL SMOOTH_READPARMS ( myThid )
#endif

#ifdef ALLOW_ECCO
C--   Initialize ECCO package parameters
      CALL ECCO_READPARMS ( myThid )
#endif

#ifdef ALLOW_PROFILES
C--   if usePROFILES=T, set PROFILES parameters
      CALL PROFILES_READPARMS ( myThid )
#endif

#ifdef ALLOW_SBO
C--   if useSBO=T, set SBO parameters
      CALL SBO_READPARMS( myThid )
#endif

#ifdef ALLOW_ATM_PHYS
C--   if useAtm_Phys=T, set Atm_Phys parameters
      CALL ATM_PHYS_READPARMS( myThid )
#endif

#ifdef ALLOW_FIZHI
C--   if useFizhi=T, set fizhi parameters
      CALL FIZHI_READPARMS( myThid )
#endif

#ifdef ALLOW_DIAGNOSTICS
C--   if useDiagnostics=T, set diagnostics choices
      CALL DIAGNOSTICS_READPARMS( myThid )
#endif

#ifdef ALLOW_REGRID
C--   if useREGRID=T, set REGRID parameters
      CALL REGRID_READPARMS( myThid )
#endif

#ifdef ALLOW_LAYERS
C--   if useLayers=T, set layers parameters
      CALL LAYERS_READPARMS( myThid )
#endif

#ifdef ALLOW_NEST_CHILD
C--    Initialize nest(ing) package parameters x CHILD
       IF (useNEST_CHILD) CALL NEST_CHILD_READPARMS ( myThid )
#endif

#ifdef ALLOW_NEST_PARENT
C--    Initialize nest(ing) package parameters x PARENT
       IF (useNEST_PARENT) CALL NEST_PARENT_READPARMS ( myThid )
#endif

#ifdef ALLOW_NEST2W_CHILD
C--    Initialize Child 2-way nest(ing) package parameters
       IF (useNest2W_child) CALL NEST2W_C_READPARMS( myThid )
#endif

#ifdef ALLOW_NEST2W_PARENT
C--    Initialize Parent 2-way nest(ing) package parameters
       IF (useNest2W_parent) CALL NEST2W_P_READPARMS( myThid )
#endif

#ifdef COMPONENT_MODULE
C--   set Coupling parameters
      IF ( useCoupler ) CALL CPL_READPARMS( myThid )
#endif

#ifdef ALLOW_OASIS
       IF (useOASIS) CALL OASIS_READPARMS ( myThid )
#endif

#ifdef ALLOW_RUNCLOCK
C--   if useRunClock=T, set RUNCLOCK parameters
      CALL RUNCLOCK_READPARMS( myThid )
#endif

#ifdef ALLOW_MYPACKAGE
C--   if useMYPACKAGE=T, set mypackage parameters
      CALL MYPACKAGE_READPARMS( myThid )
#endif

      RETURN
      END
