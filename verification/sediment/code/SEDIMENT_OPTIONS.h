C---SEDIMENT MODULE BEGIN
C
C     SEDIMENT_OPTIONS.h
C
C     Compilation flags for sediment tracer module
C
C---SEDIMENT MODULE END

#ifndef SEDIMENT_OPTIONS_H
#define SEDIMENT_OPTIONS_H

#include "PACKAGES_CONFIG.h"
#include "CPP_OPTIONS.h"

C     ===================================================================
C     SEDIMENT PACKAGE OPTIONS
C     ===================================================================

C     ALLOW_SEDIMENT
C     ===============
C     If defined, enables the sediment tracer module.
C     Can be toggled in CPP_OPTIONS.h or here.
C
C     Cycles 1-6: Sediment physics (settling, EOS, diffusion, boundary)
C     Cycles 7-8: Coupling to NH solver momentum and pressure

#define ALLOW_SEDIMENT

C     ===================================================================
C     CYCLE 1: SETTLING VELOCITY
C     ===================================================================

C     ALLOW_SEDIMENT_SETTLING
C     =======================
C     Enable gravitational settling of sediment tracers.
C     Implements explicit vertical flux divergence: -∂(ws0*C)/∂z
C     
C     Called after PTRACERS_ADVECTION.
C     CFL constraint: ws0*dt/dz < 0.5

#define ALLOW_SEDIMENT_SETTLING

C     ===================================================================
C     CYCLE 2: EOS COUPLING (NOT YET INTEGRATED)
C     ===================================================================

C     ALLOW_SEDIMENT_EOS
C     ==================
C     Enable sediment concentration to modify density via EOS.
C     Adds γC·C term to density or -g·γC·C to buoyancy.
C
C     Physics:
C       ρ = ρ₀[1 - αT(T - T₀) + βS(S - S₀) + γC·C]
C       b = g[αT(T - T₀) - βS(S - S₀) - γC·C]
C
C     Implementation:
C       - SEDIMENT_EOS_BUOYANCY: adds sediment term to buoyancy field
C       - SEDIMENT_EOS_DENSITY: adds sediment term to density field
C
C     Integration points (requires MITgcm core modifications):
C       - compute_buoyancy.F: call SEDIMENT_EOS_BUOYANCY
C       - eos_linear.F: call SEDIMENT_EOS_DENSITY
C
C     ❌ DISABLED - Code exists but not hooked into MITgcm EOS system
C     Will be enabled in a future cycle when we modify compute_buoyancy.F

#undef ALLOW_SEDIMENT_EOS

C     ===================================================================
C     CYCLE 3: ANISOTROPIC DIFFUSIVITY (Later)
C     ===================================================================

C     ALLOW_SEDIMENT_ANISO_DIFFUSION
C     ===============================
C     Enable anisotropic (horizontal vs vertical) diffusivity.
C     Separate KCz and KCh clamped to physical ranges.
C
C     Currently disabled; will be enabled in Cycle 3
C     #undef ALLOW_SEDIMENT_ANISO_DIFFUSION

C     ===================================================================
C     CYCLE 4: BOUNDARY FLUXES (Later)
C     ===================================================================

C     ALLOW_SEDIMENT_DEPOSITION
C     =========================
C     Enable bottom deposition of settling sediment.
C     Tracks sediment removal from domain at seafloor.
C
C     Currently disabled; will be enabled in Cycle 4
C     #undef ALLOW_SEDIMENT_DEPOSITION

C     ALLOW_SEDIMENT_ICE_REMOVAL
C     ==========================
C     Enable sediment removal at top (ice melt or surface sink).
C     Optional; for plume/lock-exchange type experiments.
C
C     Currently disabled; will be enabled in Cycle 4
C     #undef ALLOW_SEDIMENT_ICE_REMOVAL

C     ===================================================================
C     CYCLE 5: DIAGNOSTICS (Later)
C     ===================================================================

C     ALLOW_SEDIMENT_DIAGNOSTICS
C     ==========================
C     Enable sediment-specific diagnostics output.
C     Registers: WS_EFF, KCZ, KCH, CFLSET, DEPSED, ICESED, etc.
C
C     Currently disabled; will be enabled in Cycle 5
C     #undef ALLOW_SEDIMENT_DIAGNOSTICS

C     ===================================================================
C     CYCLE 6: FLOCCULATION (Later)
C     ===================================================================

C     ALLOW_SEDIMENT_FLOCCULATION
C     ===========================
C     Enable adaptive settling velocity via flocculation feedback.
C     wsEff = ws0 * (1 + alphaF * F)
C     where F evolves with shear and concentration.
C
C     Currently disabled; will be enabled in Cycle 6
C     #undef ALLOW_SEDIMENT_FLOCCULATION

C     ===================================================================
C     CYCLE 7-8: SOLVER INTEGRATION (Later)
C     ===================================================================

C     ALLOW_SEDIMENT_BUOYANCY
C     =======================
C     Enable sediment buoyancy coupling to hydrostatic pressure.
C     Adds sediment density contribution: Δρ = ρ₀ * γC * C
C     Modifies: calc_phi_hyd.F (local copy with sediment hook)
C
C     Physics:
C       ρ_mix = ρ_water * (1 + γC * C)
C       where γC ≈ 1.6e-3 m³/kg for quartz sediment
C
C     This affects:
C       - Hydrostatic pressure gradient
C       - Baroclinic flow driven by sediment concentration gradients
C
C     ENABLED for Cycle 7 (Hydrostatic buoyancy coupling)
#define ALLOW_SEDIMENT_BUOYANCY

#endif /* SEDIMENT_OPTIONS_H */


