# Cycle 1: Minimal Settling Tracer — Deployment Guide

## Overview

**Goal**: Implement one settling sediment tracer with CFL stability checking.

**Physics**: Gravitational settling via explicit vertical flux divergence:
$$\frac{\partial C}{\partial t} = -\frac{\partial (w_s C)}{\partial z}$$

where $w_s$ is the settling velocity [m/s], $C$ is concentration [kg/m³].

**Stability Constraint**: 
$$\text{CFL}_{\text{set}} = \frac{w_s \Delta t}{\Delta z_{\min}} < 0.5$$

**Expected Outcome**: 
- ✅ Tracer settles smoothly without NaNs
- ✅ CFL check passes or warns appropriately
- ✅ Mass conservation verified
- ✅ Compilation succeeds with no new errors

---

## File Structure (Local)

```
codepatch_cycle1/
├── sediment.h                      # Header: common blocks, parameters
├── sediment_init.F                 # Init: read namelist, check CFL
├── sediment_settling.F             # Core: settling velocity implementation
├── SEDIMENT_OPTIONS.h              # Compiler flags
└── data.sediment.cycle1            # Namelist for this cycle
```

---

## Integration Steps (On HPC)

### Step 1: Copy Code Files

Copy the four source files to the MITgcm codepatch directory:

```bash
cd $MITGCM_ROOT/verification/sediment/code

# Copy header and sources
cp /path/to/codepatch_cycle1/sediment.h .
cp /path/to/codepatch_cycle1/sediment_init.F .
cp /path/to/codepatch_cycle1/sediment_settling.F .
cp /path/to/codepatch_cycle1/SEDIMENT_OPTIONS.h .
```

**File Permissions**: Ensure files are readable:
```bash
chmod 644 sediment.h sediment_init.F sediment_settling.F SEDIMENT_OPTIONS.h
```

### Step 2: Update Input Namelist

Update the input/data.sediment with Cycle 1 parameters:

```bash
cd $MITGCM_ROOT/verification/sediment/input

# Backup original
cp data.sediment data.sediment.backup

# Replace with Cycle 1 version (or merge manually)
cp /path/to/codepatch_cycle1/data.sediment.cycle1 data.sediment
```

**Key Parameter** (verify in data.sediment):
```fortran
&SEDIMENT_PARM01
  SEDIMENT_ws0 = 0.01,    ! m/s - settling velocity
&END
```

### Step 3: Verify MITgcm Build Configuration

Ensure the following are present in `code/packages.conf`:
```
gfd
diagnostics
mdsio
mnc
sediment         ← CRITICAL for pkg/sediment/ integration
ptracers         ← CRITICAL for tracer advection/diffusion
```

Ensure `code/CPP_OPTIONS.h` includes:
```c
#define ALLOW_DIAGNOSTICS
#define NONLIN_FRSURF
#define ALLOW_NONHYDROSTATIC              /* Cycle 0 should have done this */
#define ALLOW_NONHYDROSTATIC_PRESSURE
#define EXACT_CONSERV                     /* Mass conservation */
```

### Step 4: Compile

```bash
cd $MITGCM_ROOT/verification/sediment

# Clean and rebuild
rm -rf build/ run/
mkdir build run

cd build
../code_dir/genmake2 -mods ../code -of /path/to/optfile
make depend
make -j 8

# Check for compilation errors
echo "Build exit code: $?"
```

**Expected Output**:
- No compilation errors
- Executable: `$MITGCM_ROOT/verification/sediment/build/mitgcmuv`

### Step 5: Run Minimal Test

```bash
cd ../run

# Link input files
ln -s ../input/* .

# Run with 1 MPI process, 1 hour simulation
mpirun -np 1 ../build/mitgcmuv

# Or single-process (if not MPI):
../build/mitgcmuv
```

**Runtime Parameters** (in input/data):
```fortran
&PARM03
  nTimeSteps = 36,        ! 36 * 100 s = 1 hour
  deltaT = 100.,          ! 100 s timestep
  dumpFreq = 3600.,       ! Dump every 1 hour
&END
```

---

## Validation Checklist

After running the test, verify:

### 1. **No NaNs in Output**
```bash
# Check for NaN values in tracer output
grep -i "NaN\|NAN\|nan" STDOUT.0000

# Should return nothing (no NaNs found)
```

### 2. **CFL Check**
Look for CFL warning in stdout:
```
SEDIMENT_INIT: Parameters---
  Settling velocity ws0 =  1.0000E-02 m/s
  Time step deltaT =  1.0000E+02
  Min grid spacing =  1.0000E+01 m (at k=20)
  CFL number CFLset =  1.0000E-01
---SEDIMENT_INIT: End---
```

✅ **Pass** if `CFLset < 0.5` (here: 0.1)
⚠️ **Warn** if `CFLset >= 0.5` (still runs; indicates potential instability)

### 3. **Mass Conservation**
Check diagnostic output for sediment concentration:
- Initial: should match initial condition file
- After settling: total sediment mass should decrease only at domain boundaries (Cycle 4)
- Interior sum should remain positive

### 4. **Solver Iteration Counts**
Compare before/after:
```
# Hydrostatic mode (Cycle 0):
cg2dIters[1] = X iterations

# After Cycle 1 (should be similar):
cg2dIters[1] = Y iterations   (Y ≈ X, not dramatically increased)
```

### 5. **Output File Existence**
```bash
ls -lh STDOUT.0000  # Main output
ls -lh *.data       # Binary data files
ls -lh *.meta       # Metadata for each .data file
```

Should see sediment tracer files (if PTRACERS diagnostics enabled).

---

## Physics Verification (Optional)

### Settling Profile
If tracer is initialized uniformly at depth, after settling it should show:
- **Top levels**: tracer concentration decreases (sediment leaving)
- **Bottom levels**: tracer concentration increases (sediment arriving)
- **Shape**: smooth downward migration with Gaussian profile (if diffusion present)

### CFL Constraint Derivation
Given:
- $\Delta z = 10$ m (typical layer thickness)
- $\Delta t = 100$ s (timestep)
- $w_s = 0.01$ m/s (settling velocity)

$$\text{CFL}_{\text{set}} = \frac{0.01 \times 100}{10} = 0.1 < 0.5$$ ✅

For stability, ensure:
$$w_s < 0.05 \text{ m/s (with current } \Delta t, \Delta z\text{)}$$

---

## Troubleshooting

### Compilation Error: "sediment.h not found"
- ✅ Verify sediment.h is in `code/` directory
- ✅ Verify `packages.conf` includes `sediment`
- ✅ Rerun `genmake2` with `-mods ../code`

### Runtime Error: "Undefined SEDIMENT_ws0"
- ✅ Verify `data.sediment` exists in run directory
- ✅ Verify namelist `&SEDIMENT_PARM01` is present
- ✅ Verify parameter `SEDIMENT_ws0` is set (not commented)

### CFL Warning Appears
- 🔧 **Not Fatal**: Solver may still be stable; check for NaNs
- 🔧 **Fix**: Reduce `SEDIMENT_ws0` or increase `deltaT`, or use finer vertical grid
- 🔧 **Alternative**: Accept warning if output looks physical

### Large Solver Iteration Counts
- 🔧 May indicate pressure solver difficulty after sediment buoyancy is added (Cycle 7)
- 🔧 For Cycle 1, pressure solver should be unchanged
- 🔧 If seen in Cycle 1, investigate orthogonality/conditioning

---

## Next Steps (After Validation)

✅ **If Cycle 1 passes**: Proceed to **Cycle 2** — Couple sediment to EOS (buoyancy).

❌ **If issues arise**: 
1. Review sediment_init.F for parameter read errors
2. Check CFL; may need to reduce ws0
3. Verify PTRACERS package is properly enabled
4. Run with verbose output: `setenv DEBUG 1` (if supported)

---

## Key Physics Notes

### Flux-Conservative Update
The settling update is conservative:
$$C_{\text{new}} = C_{\text{old}} - \frac{\Delta t}{\Delta z} \left[ w_s C(k) - w_s C(k-1) \right]$$

This ensures total sediment mass in domain only decreases due to seafloor deposition (Cycle 4).

### Explicit Time-Stepping
Settling is treated explicitly (forward Euler) in time:
$$C^{n+1} = C^n - \Delta t \frac{\partial}{\partial z}(w_s C^n)$$

This is simpler and more transparent than implicit schemes, especially for diagnostics.

### Integration Point
Settling is applied **after advection** and **before diffusion**:
1. PTRACERS_ADVECTION → computes advective fluxes
2. **SEDIMENT_SETTLING** → applies settling sink ← **THIS CYCLE**
3. PTRACERS_DIFFUSION → applies diffusive smoothing
4. PTRACERS_BOUNDARY → applies boundary conditions

This ordering ensures settling acts on the post-advection field, reducing spurious oscillations.

---

## Summary

**Cycle 1 delivers**:
- ✅ Settling velocity module (sediment_settling.F)
- ✅ CFL stability checker (sediment_init.F)
- ✅ Parameter framework (sediment.h, SEDIMENT_OPTIONS.h)
- ✅ Tracers settle smoothly without NaNs
- ✅ Mass conservation holds (until deposition in Cycle 4)

**Ready for Cycle 2**: Add sediment-buoyancy coupling to equation of state.



