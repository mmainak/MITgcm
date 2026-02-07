# NaN Debugging Guide for Sediment Tracer

## Problem

The sediment tracer (PTRACER01) is going to NaN immediately or after a few timesteps. This indicates:
- Corrupted input files (NaN in initial conditions or boundary files)
- Numerical instability (division by zero, extreme gradients)
- Bug in sediment code (settling, buoyancy coupling)

## Systematic Debugging Strategy

### Phase 1: Verify Input Files (LOCAL)

**Run verification script locally:**

```bash
cd /Users/pinta/Documents/Work/Code_bases/MITgcm/verification/sediment/input_plume
matlab -nodisplay -nosplash -r "verify_input_files; exit"
```

**Expected output:**
- All NaN counts should be **0**
- All Inf counts should be **0**
- OBWsed.bin should have non-zero values in conduit region

**If any NaN/Inf detected:**
```bash
# Regenerate ALL input files
matlab -nodisplay -nosplash -r "generate_plume_inputs; exit"
# Re-verify
matlab -nodisplay -nosplash -r "verify_input_files; exit"
```

### Phase 2: Transfer Clean Files to HPC

**Only after Phase 1 passes:**

```bash
# Transfer to HPC
scp T_init.bin S_init.bin sediment_init.bin \
    OBWu.bin OBWv.bin OBWt.bin OBWs.bin OBWsed.bin \
    OBEu.bin OBEv.bin OBEt.bin OBEs.bin OBEsed.bin \
    bathy.bin shelfice_topo.bin \
    HPC:/scratch/mm10845/sediment_test/sediment_devl2/run/
```

### Phase 3: Minimal Test (NO Settling, NO Buoyancy)

**Goal:** Test if advection alone works without NaN

**On HPC:**

```bash
cd /scratch/mm10845/sediment_test/sediment_devl2/run

# Use minimal test configuration
cp data.sediment_NO_SETTLING data.sediment
cp data.ptracers_MINIMAL_TEST data.ptracers

# Also generate simple uniform IC locally first:
# matlab: generate_simple_test_IC.m
# Then transfer sediment_init_test.bin and use it:
cp sediment_init_test.bin sediment_init.bin

# Run short test (10 timesteps)
sbatch run_job.sh  # or mpirun -np 4 ./mitgcmuv
```

**Check results:**

```bash
grep "trcstat_ptracer01" STDOUT.0000 | tail -5
```

**Expected:**
- Max/Min/Mean should be **0.01** (uniform field, no settling)
- **NO NaN**

**If still NaN:**
- Problem is in OBCS or advection, not settling
- Try using OBWsed_zero.bin (no boundary forcing)
- Check if OBCS package is corrupting the field

**If no NaN:**
- ✅ Advection works
- Problem is in settling or buoyancy coupling
- Proceed to Phase 4

### Phase 4: Add Settling (Still NO Buoyancy)

**Goal:** Test if settling alone causes NaN

**On HPC:**

```bash
cd /scratch/mm10845/sediment_test/sediment_devl2/run

# Edit data.sediment:
# Change: SEDIMENT_ws0 = 0.001,  (enable settling)
# Keep: SEDIMENT_buoyancyOn = .FALSE.,
#       SEDIMENT_densityOn = .FALSE.,

# Use original IC with sediment at conduit
cp sediment_init.bin.original sediment_init.bin

# Run
sbatch run_job.sh
```

**Check results:**

```bash
grep "trcstat_ptracer01_max" STDOUT.0000 | tail -20
```

**Expected:**
- Sediment should settle from initial distribution
- Max should decrease over time (settling removes from domain)
- Values should stay positive and < 10 kg/m³

**If NaN appears:**
- Problem is in settling routine
- Check `code/sediment_apply_settling.F` or `sediment_apply_settling_SAFE.F`
- Verify which version is being used in compilation

**If no NaN:**
- ✅ Settling works
- Problem is in buoyancy coupling
- Proceed to Phase 5

### Phase 5: Add Buoyancy Coupling

**Goal:** Test full physics

**On HPC:**

```bash
cd /scratch/mm10845/sediment_test/sediment_devl2/run

# Edit data.sediment:
# Change: SEDIMENT_buoyancyOn = .TRUE.,
#         SEDIMENT_densityOn = .TRUE.,

# Run
sbatch run_job.sh
```

**Check results:**

```bash
grep "trcstat_ptracer01_max" STDOUT.0000 | tail -20
grep "dynstat_uvel_max" STDOUT.0000 | tail -10
grep "dynstat_wvel_max" STDOUT.0000 | tail -10
```

**Expected:**
- Sediment affects velocity field via buoyancy
- Max sediment < 10 kg/m³
- Velocities remain reasonable (< 1 m/s)

**If NaN or blow-up:**
- Problem is in buoyancy coupling
- Check `code/sediment_add_buoyancy.F`
- Check `code/calc_phi_hyd.F` for `SEDIMENT_ADD_BUOYANCY` call
- Reduce `SEDIMENT_gammaC` to very small value (1e-10) to test

### Phase 6: Tune Numerical Parameters

**If reaching this phase, physics works but needs stability tuning:**

**Advection scheme options (data.ptracers):**
- `PTRACERS_advScheme(1) = 2` - 2nd order centered (most stable, diffusive)
- `PTRACERS_advScheme(1) = 7` - 3rd order with flux limiter (monotonic)
- `PTRACERS_advScheme(1) = 33` - 3rd order DST (accurate but oscillatory)

**Diffusivity tuning (data.ptracers):**
- Increase `PTRACERS_diffKh(1)` if horizontal oscillations
- Increase `PTRACERS_diffKr(1)` if vertical instability
- Start high (1.0, 0.1), then reduce once stable

**Timestep reduction (data):**
- If CFL violations: reduce `deltaT` from 0.25s to 0.1s

## Common Root Causes

### 1. **Corrupted OBCS Files**

**Symptom:** NaN appears immediately at timestep 0

**Diagnosis:**
```bash
# On HPC
cd /scratch/mm10845/sediment_test/sediment_devl2/run
od -f OBWsed.bin | head -20
```

**Fix:** Regenerate locally with MATLAB, verify, then transfer

### 2. **Array Dimension Mismatch in OBCS**

**Symptom:** Sediment appears at wrong depth or NaN

**Cause:** MATLAB writes `(Ny, Nr)` but Fortran expects different order

**Fix:** Check `generate_plume_inputs.m`:
- `fwrite(fid, OBWsed, 'float64')` (NO transpose)
- MITgcm `READ_REC_YZ_RL` expects `(Ny, Nr)` directly

### 3. **Settling Boundary Condition Bug**

**Symptom:** NaN appears after a few timesteps, starting at bottom

**Cause:** `sediment_apply_settling.F` has wrong bottom BC

**Fix:** Use `sediment_apply_settling_SAFE.F` with clipping:
```fortran
C At bottom: allow deposition (flux_out = ws * C_k)
flux_out = ws * C_k
```

### 4. **Advection Scheme Oscillations**

**Symptom:** Checkerboard pattern, then blow-up

**Cause:** Scheme 33 (DST) creates over/undershoots with sharp gradients

**Fix:** Use scheme 7 (flux-limited) or scheme 2 (centered)

### 5. **Insufficient Diffusivity**

**Symptom:** Sharp gradients, grid-scale noise, eventual blow-up

**Cause:** Advection scheme can't handle gradients, needs explicit damping

**Fix:** Increase `PTRACERS_diffKh` and `PTRACERS_diffKr`

## Debugging Checklist

- [ ] **Phase 1:** Verified all input files locally (no NaN)
- [ ] **Phase 2:** Transferred clean files to HPC
- [ ] **Phase 3:** Minimal test passes (no settling, no buoyancy)
- [ ] **Phase 4:** Settling test passes (with settling, no buoyancy)
- [ ] **Phase 5:** Full physics test (with settling and buoyancy)
- [ ] **Phase 6:** Tuned for stability and accuracy

## Quick Commands for HPC

```bash
# Check if NaN
grep "trcstat_ptracer01" STDOUT.0000 | tail -20 | grep NaN

# Check max sediment over time
grep "trcstat_ptracer01_max" STDOUT.0000 | awk '{print $4}'

# Check if simulation completed
tail -20 STDOUT.0000 | grep "PROGRAM MAIN: Execution ended"

# Check for crashes
tail -50 STDOUT.0000 | grep -i "error\|abnormal\|nan"

# Monitor running job
watch -n 5 'tail -30 STDOUT.0000'
```

## Files Created for Debugging

1. `verify_input_files.m` - Check all `.bin` files for NaN/Inf
2. `generate_simple_test_IC.m` - Create uniform test initial condition
3. `data.sediment_NO_SETTLING` - Disable settling for minimal test
4. `data.ptracers_MINIMAL_TEST` - Simple 2nd-order advection, high diffusion
5. `sediment_init_test.bin` - Uniform C=0.01 kg/m³ (generated by script 2)
6. `OBWsed_zero.bin`, `OBEsed_zero.bin` - Zero boundary forcing (generated by script 2)

## Success Criteria

Simulation is working when:
- ✅ No NaN in any tracer statistics
- ✅ Sediment max < 10 kg/m³ (physically reasonable)
- ✅ Sediment min ≥ 0 (no negative concentrations)
- ✅ Velocities reasonable (max < 1 m/s)
- ✅ Simulation completes without crash
- ✅ Sediment distribution makes physical sense (plume, settling)

## Next Steps After Debugging

Once NaN is eliminated and simulation is stable:
1. Visualize results with `analyze_plume.m`
2. Verify plume physics (buoyant rise, entrainment, settling)
3. Compare with expected behavior
4. Write diagnostic code for detailed analysis
5. Run longer simulations (hours to days)
