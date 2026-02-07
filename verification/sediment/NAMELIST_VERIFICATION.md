# Namelist Parameter Verification

All parameter files have been checked against MITgcm source code.

## ✅ data.pkg - VERIFIED
**File**: `input/data.pkg`
**Namelist**: `/PACKAGES/`
**Source**: `model/src/packages_boot.F`

All parameters valid:
- `usePTRACERS = .TRUE.`  ✓
- `useKPP = .TRUE.`        ✓
- `useDIAGNOSTICS = .TRUE.` ✓

---

## ✅ data - VERIFIED
**File**: `input/data`
**Namelists**: `/PARM01/`, `/PARM02/`, `/PARM03/`, `/PARM04/`, `/PARM05/`
**Source**: `model/src/ini_parms.F`

### PARM01 - All Valid:
- `viscAh`, `viscAz`, `viscA4` ✓
- `diffKhT`, `diffKzT`, `diffKhS`, `diffKzS` ✓
- `tRef`, `sRef`, `rhonil`, `rhoConstFresh` ✓
- `eosType`, `tAlpha`, `sBeta` ✓
- `implicitDiffusion`, `implicitViscosity`, `implicitFreeSurface` ✓
- `tempAdvScheme`, `saltAdvScheme`, `staggerTimeStep` ✓
- `gravity`, `gBaro`, `rigidLid`, `no_slip_bottom` ✓
- `bottomDragQuadratic` ✓
- `readBinaryPrec`, `writeBinaryPrec`, `useSingleCpuIO` ✓

### PARM02 - All Valid:
- `cg2dMaxIters`, `cg2dTargetResidual` ✓

### PARM03 - All Valid:
- `nIter0`, `nTimeSteps`, `deltaT`, `abEps` ✓
- `pChkptFreq`, `chkptFreq`, `dumpFreq`, `monitorFreq` ✓
- `pickupStrictlyMatch` ✓

### PARM04 - All Valid:
- `usingCartesianGrid`, `usingSphericalPolarGrid` ✓
- `delX`, `delY`, `delZ` ✓
- `xgOrigin`, `ygOrigin` ✓
- `bathyFile` ✓

### PARM05 - All Valid:
- `hydrogThetaFile`, `hydrogSaltFile` ✓

---

## ✅ data.kpp - CORRECTED
**File**: `input/data.kpp`
**Namelist**: `/KPP_PARM01/`
**Source**: `pkg/kpp/kpp_readparms.F`

### Issues Fixed:
❌ **REMOVED**: `KPPmixingMaps` (retired parameter)
❌ **REMOVED**: `KPPdiffKzS`, `KPPdiffKzT`, `KPPnu` (not in namelist - these are internal variables)
❌ **REMOVED**: `BAmult` (not in namelist)
❌ **REMOVED**: `KPPshearInst` (not in namelist)

### Valid Parameters Now Used:
- `KPPwriteState = .TRUE.` ✓
- `minKPPhbl = 10.` ✓
- `epsilon = 0.1` ✓
- `vonk = 0.4` ✓
- `dB_dz = 5.E-5` ✓
- `Riinfty = 0.7` ✓
- `difm0`, `difs0`, `dift0` ✓ (shear instability diffusivities)
- `difmcon`, `difscon`, `diftcon` ✓ (convective diffusivities)
- `Ricr`, `cekman`, `cmonob`, `concv`, `hbf` ✓ (boundary layer depth params)
- `KPPuseDoubleDiff = .FALSE.` ✓

---

## ✅ data.ptracers - VERIFIED
**File**: `input/data.ptracers`
**Namelist**: `/PTRACERS_PARM01/`
**Source**: `pkg/ptracers/ptracers_readparms.F`

All parameters valid:
- `PTRACERS_numInUse = 1` ✓
- `PTRACERS_Iter0 = 0` ✓
- `PTRACERS_dumpFreq`, `PTRACERS_monitorFreq` ✓
- `PTRACERS_names(1)`, `PTRACERS_long_names(1)`, `PTRACERS_units(1)` ✓
- `PTRACERS_advScheme(1) = 33` ✓
- `PTRACERS_diffKh(1)`, `PTRACERS_diffKr(1)` ✓
- `PTRACERS_useGMRedi(1)`, `PTRACERS_useKPP(1)` ✓
- `PTRACERS_initialFile(1)` ✓

---

## ✅ data.sediment - CORRECTED FOR CYCLE 2
**File**: `input/data.sediment`
**Namelist**: `/SEDIMENT_PARM01/`
**Source**: `codepatch_cycle2/sediment.h`, `codepatch_cycle2/sediment_init.F`

### Issues Fixed:
❌ **REMOVED**: Multi-class parameters (`SEDIMENT_nClass`, arrays with (1:2), etc.)
  - These were from a hypothetical multi-class implementation
  - Cycle 2 uses SINGLE sediment tracer only

### Valid Parameters (Cycle 2):
- `SEDIMENT_ws0 = 0.01` ✓ (settling velocity [m/s])
- `SEDIMENT_gammaC = 1.6E-3` ✓ (density expansion coefficient [m³/kg])
- `SEDIMENT_rhoSed = 2650.` ✓ (grain density [kg/m³])

**Note**: These are the ONLY parameters defined in Cycle 2 sediment code!

---

## Summary

### Files Corrected:
1. **data.kpp**: Removed invalid/retired parameters, added proper KPP parameters
2. **data.sediment**: Replaced multi-class parameters with Cycle 2 simple parameters

### Files Verified as Correct:
1. **data.pkg**: All package switches valid
2. **data**: All PARM01-05 parameters valid
3. **data.ptracers**: All tracer parameters valid

### All Namelists Now Ready for HPC Deployment

---

## Cross-Reference

- MITgcm version: checkpoint69g (based on HPC STDOUT)
- Configuration: Cartesian, 100×100×20, 10km×10km×200m
- Packages: gfd, mom_common, mom_fluxform, kpp, ptracers, diagnostics
- Sediment: Cycle 2 (settling + EOS coupling)

**Status**: ✅ ALL NAMELISTS VERIFIED AND CORRECTED

