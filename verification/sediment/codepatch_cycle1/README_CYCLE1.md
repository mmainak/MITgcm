# Cycle 1: Minimal Settling Tracer — Quick Reference

## Files in This Directory

| File | Purpose | Lines |
|------|---------|-------|
| `sediment.h` | Common blocks, parameters, diagnostics | 57 |
| `sediment_init.F` | Initialization: read namelist, check CFL | 134 |
| `sediment_settling.F` | Core physics: settling velocity implementation | 186 |
| `SEDIMENT_OPTIONS.h` | Compiler flags for all cycles | 120 |
| `data.sediment.cycle1` | Namelist template | 60 |

**Total Code**: ~560 lines (well-commented, highly readable).

---

## One-Line Summary

**Sediment tracer settles downward with velocity $w_s$, conserving mass, under CFL stability constraint $w_s \Delta t / \Delta z < 0.5$.**

---

## Physics (Compact)

### Conservation Equation
$$\frac{\partial C}{\partial t} + \nabla \cdot [(u - w_s \hat{k}) C] = \nabla \cdot (K_C \nabla C)$$

### Settling Flux Divergence
- Flux at top of cell $k$: $F_{\text{top}}(k) = w_s \cdot C(k-1)$
- Flux at bottom: $F_{\text{bot}}(k) = w_s \cdot C(k)$
- Net sink: $-\frac{1}{\Delta z}[F_{\text{bot}} - F_{\text{top}}] = -\frac{w_s}{\Delta z}[C(k) - C(k-1)]$

### Update Rule
$$C_{\text{new}} = C_{\text{old}} - \Delta t \cdot w_s \cdot \frac{\partial C}{\partial z} \big|_{\text{upwind}}$$

### CFL Criterion
$$\text{CFLset} = \frac{w_s \Delta t}{\min(\Delta z)} \quad \text{must satisfy} \quad \text{CFLset} < 0.5$$

---

## Integration Checklist (3 Steps)

### 1. Copy Files
```bash
cp sediment.h /path/to/MITgcm/verification/sediment/code/
cp sediment_init.F /path/to/MITgcm/verification/sediment/code/
cp sediment_settling.F /path/to/MITgcm/verification/sediment/code/
cp SEDIMENT_OPTIONS.h /path/to/MITgcm/verification/sediment/code/
```

### 2. Update Namelist
Replace or merge into `input/data.sediment`:
```fortran
&SEDIMENT_PARM01
  SEDIMENT_ws0 = 0.01,    ! m/s
&END
```

### 3. Compile & Run
```bash
cd $MITGCM_ROOT/verification/sediment/build
../code_dir/genmake2 -mods ../code -of optfile
make -j 8
cd ../run
ln -s ../input/* .
../build/mitgcmuv
```

---

## Validation (3 Quick Checks)

| Check | Command | Expected |
|-------|---------|----------|
| **No NaNs** | `grep NaN STDOUT.0000` | No output |
| **CFL OK** | `grep CFLset STDOUT.0000` | `CFLset < 0.5` |
| **Files exist** | `ls -lh *.data` | Binary output files |

---

## Code Logic (sediment_settling.F)

```fortran
LOOP over grid cells (i,j,k)
  
  Flux_above = ws0 * C(k-1)      ! Sediment entering from above
  Flux_below = ws0 * C(k)        ! Sediment leaving downward
  
  Flux_divergence = (Flux_below - Flux_above) / dz
  
  C_new = C_old - dt * Flux_divergence
  
  IF C_new < 0: C_new = 0        ! Clamp to physical range
  
ENDLOOP
```

---

## Parameters

| Parameter | Value | Units | Notes |
|-----------|-------|-------|-------|
| `SEDIMENT_ws0` | 0.01 | m/s | Settling velocity; set in data.sediment |
| `deltaT` | 100 | s | Timestep; from data |
| `delZ(k)` | 10 | m | Vertical layer thickness; from code/SIZE.h or data |
| `SEDIMENT_cflSet` | computed | — | CFL number; printed at init |

**CFL Range**: 
- Safe: < 0.3 (always stable)
- Acceptable: 0.3 – 0.5 (usually stable, monitor)
- Risky: > 0.5 (warns but continues; not recommended)

---

## What This Cycle Enables

✅ Settling tracer moves downward  
✅ Flux is conservative (no spurious sources)  
✅ CFL check prevents overshoot  
✅ Framework for later physics (EOS, diffusion, etc.)  

---

## What's NOT Here Yet

❌ Buoyancy coupling (Cycle 2)  
❌ Anisotropic diffusivity (Cycle 3)  
❌ Deposition (Cycle 4)  
❌ Diagnostics (Cycle 5)  
❌ Flocculation (Cycle 6)  
❌ NH solver integration (Cycles 7-8)  

---

## Typical Output Snippet

```
SEDIMENT_INIT: Initializing sediment module
---SEDIMENT_INIT: Parameters---
  Settling velocity ws0 =  1.0000E-02 m/s
  Time step deltaT =  1.0000E+02
  Min grid spacing =  1.0000E+01 m (at k=20)
  CFL number CFLset =  1.0000E-01
---SEDIMENT_INIT: End---
```

---

## Next: Cycle 2

Once Cycle 1 passes, Cycle 2 will:
- Add `gammaC` parameter (sediment density effect)
- Modify `eos_linear.F` to include sediment in density
- Test that sediment-rich regions sink (heavier)
- Verify solver remains stable

See `CYCLE_2_PREVIEW.md` (coming next).

---

## Questions?

- **Physics**: See CYCLE_1_DEPLOYMENT.md § "Physics Verification"
- **Code**: Search for `C---SEDIMENT MODULE` comments in .F files
- **Parameters**: Read namelist section in `data.sediment.cycle1`



