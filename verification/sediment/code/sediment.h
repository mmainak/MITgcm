C---SEDIMENT MODULE BEGIN
C
C     sediment.h
C
C     Header file for sediment tracer module - Cycle 2: EOS Coupling
C
C     PURPOSE:
C     --------
C     Define sediment tracer parameters and control flags including
C     equation of state (EOS) coupling for sediment-density feedback.
C
C     MODIFICATIONS FROM CYCLE 1:
C     - Added SEDIMENT_gammaC: sediment density expansion coefficient
C     - Added SEDIMENT_rhoSed: reference sediment grain density
C     - Added buoyancy contribution storage
C
C---SEDIMENT MODULE END

#ifdef ALLOW_PTRACERS

C     ===================================================================
C     SEDIMENT PARAMETERS (Read from data.sediment namelist)
C     ===================================================================

C     Settling velocity for sediment tracer [m/s]
C     - Typical fine sediment: 0.001 m/s (very fine silt)
C     - Medium sediment: 0.01 m/s
C     - Coarse sediment: 0.05 m/s (sand)
      _RL SEDIMENT_ws0
      COMMON /SEDIMENT_PARAMS_RL/ SEDIMENT_ws0

C     Sediment tracer index (assigned by PTRACERS package)
C     - Tracer number in the PTRACERS array
      INTEGER SEDIMENT_tracerNum
      COMMON /SEDIMENT_PARAMS_I/ SEDIMENT_tracerNum

C     CFL limit flag and warning counter
C     - SEDIMENT_cflWarn: triggers if CFLset exceeds 0.5
C     - Count violations for diagnostic output
      LOGICAL SEDIMENT_cflWarn
      INTEGER SEDIMENT_cflWarnCount
      COMMON /SEDIMENT_FLAGS/ SEDIMENT_cflWarn, SEDIMENT_cflWarnCount

C     ===================================================================
C     CYCLE 2: EOS COUPLING PARAMETERS
C     ===================================================================

C     Sediment density expansion coefficient [m³/kg]
C     - Controls how sediment concentration affects density
C     - Density: ρ = ρ0[1 + γC*C] (approximately)
C     - Buoyancy: b = -g*γC*C (sediment contribution)
C     - Typical value: γC = (ρ_sed - ρ_0)/ρ_0 / C_ref
C     - For quartz in water: (2650-1000)/1000 = 1.65
C     - If C in kg/m³, then γC ~ 1.65e-3 m³/kg
      _RL SEDIMENT_gammaC
      COMMON /SEDIMENT_EOS_RL/ SEDIMENT_gammaC

C     Reference sediment grain density [kg/m³]
C     - Quartz: 2650 kg/m³
C     - Clay minerals: 2400 kg/m³
C     - Used to compute gammaC if not explicitly provided
      _RL SEDIMENT_rhoSed
      COMMON /SEDIMENT_DENSITY_RL/ SEDIMENT_rhoSed

C     ===================================================================
C     SEDIMENT DIAGNOSTICS AND CHECKS
C     ===================================================================

C     Effective CFL number: CFLset = ws0*dt/dz
C     - Must remain < 0.5 for stability
C     - Computed at initialization
      _RL SEDIMENT_cflSet
      COMMON /SEDIMENT_DIAGNOSTICS_RL/ SEDIMENT_cflSet

C     ===================================================================
C     CYCLE 2: BUOYANCY CONTRIBUTION STORAGE (Optional)
C     ===================================================================
C
C     Storage for sediment buoyancy contribution: b_sed = -g*γC*C
C     This can be used for diagnostics or to decouple computation
C     from main EOS routine.
C
C     NOTE: In Cycle 2 (standalone), this is primarily diagnostic.
C     In Cycles 7-8 (NH coupling), this becomes critical for solver.
C
C     For now, we compute this on-the-fly in the EOS routine.
C     Uncommenting below will allocate global storage:
C
C      _RL SEDIMENT_buoyancy(1-OLx:sNx+OLx, 1-OLy:sNy+OLy, Nr, nSx, nSy)
C      COMMON /SEDIMENT_BUOYANCY_FIELD/ SEDIMENT_buoyancy

#endif /* ALLOW_PTRACERS */


