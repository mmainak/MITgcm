C---SEDIMENT MODULE BEGIN
C
C     sediment.h
C
C     Header file for sediment tracer module - Cycle 7: Buoyancy Coupling
C
C     PURPOSE:
C     --------
C     Define sediment tracer parameters and control flags.
C
C     CYCLE HISTORY:
C     - Cycle 1: Basic infrastructure (parameters, initialization)
C     - Cycle 2: Passive tracer test (advection/diffusion via PTRACERS)
C     - Cycle 3: Gravitational settling (tendency-based)
C     - Cycle 7: Buoyancy coupling (hydrostatic, this version)
C     - Cycle 8: Non-hydrostatic coupling (future)
C
C     PARAMETERS DEFINED:
C     - SEDIMENT_ws0: Settling velocity [m/s]
C     - SEDIMENT_tracerNum: Which PTRACER is sediment (default 1)
C     - SEDIMENT_gammaC: Density expansion coefficient [m³/kg]
C     - SEDIMENT_rhoSed: Grain density [kg/m³]
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
C     CYCLE 7: BUOYANCY COUPLING PARAMETERS
C     ===================================================================

C     Sediment density expansion coefficient [m³/kg]
C     - Controls how sediment concentration affects density
C     - Density: ρ = ρ0 * (1 + γC*C)
C     - Buoyancy: b_sed = -g * γC * C (negative = denser = sinks)
C
C     Physical derivation:
C     - Sediment-water mixture density: ρ_mix = ρ_w + (ρ_sed - ρ_w) * φ
C     - Where φ = volume fraction = C / ρ_sed (C in kg/m³)
C     - So: ρ_mix = ρ_w + (ρ_sed - ρ_w) * C / ρ_sed
C     - In code: deltaRho = rhoConst * gammaC * C
C     - So: γC = (ρ_sed - ρ_w) / (ρ_sed * ρ_w)
C     - For quartz: γC = (2650-1000)/(2650*1000) = 6.2e-4 m³/kg
C
C     Typical value: γC = 6.2E-4 m³/kg (quartz, ρ_sed = 2650 kg/m³)
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
C     CYCLE 7: BUOYANCY COUPLING CONTROL
C     ===================================================================

C     Flag to enable/disable buoyancy coupling
C     Read from data.sediment namelist
C     .TRUE. = sediment affects density/buoyancy
C     .FALSE. = sediment is passive (no density effect)
      LOGICAL SEDIMENT_buoyancyOn
      COMMON /SEDIMENT_BUOYANCY_FLAGS/ SEDIMENT_buoyancyOn

#endif /* ALLOW_PTRACERS */
