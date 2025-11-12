# Cycle 0: Infrastructure Test (Null Sediment Effect)

## Overview

**Purpose**: Establish baseline MITgcm build with sediment package infrastructure present but disabled/inert. This validates compilation and MPI setup without any physics changes.

**Domain**: 40×40×10 cells (4 km × 4 km × 100 m depth)  
**MPI**: 4 processors (2×2 grid)  
**Physics**: Temperature, salinity, dynamics only (no sediment effect)

## File Structure (code/)

```
cycle0_complete/
├── SIZE.h                    (40x40 global, 2x2 MPI)
├── CPP_OPTIONS.h             (gfd, diagnostics, obcs, ptracers enabled)
├── OBCS_OPTIONS.h            (open boundaries disabled)
├── PTRACERS_OPTIONS.h        (passive tracers enabled, no sediment yet)
└── packages.conf             (gfd, diagnostics, obcs, ptracers)
```

## Deployment

### Copy to HPC

```bash
cp -r cycle0_complete/* $MITGCM_ROOT/verification/sediment/code/
```

### Create input directory structure

```bash
mkdir -p $MITGCM_ROOT/verification/sediment/input
# Add runtime data files here (data, data.diagnostics, data.ptracers, etc.)
# See INPUT_TEMPLATES/ for examples
```

### Build

```bash
cd $MITGCM_ROOT/verification/sediment
rm -rf build run
mkdir build run

cd build
../code_dir/genmake2 -mods ../code -of /path/to/optfile -mpi
make depend
make -j 8
```

### Run (4 MPI processes)

```bash
cd ../run
ln -s ../input/* .
mpirun -np 4 ../build/mitgcmuv
```

## Expected Outcome

- ✅ Compilation succeeds (no undefined references to sediment)
- ✅ Executable runs without errors
- ✅ All 4 MPI processes complete
- ✅ Output files generated (*.data, *.meta)
- ✅ No sediment effect on physics (tracer values, temperature, pressure)

## Key Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Global X | 40 cells × 100 m = 4 km | |
| Global Y | 40 cells × 100 m = 4 km | |
| Depth | 10 levels × 10 m = 100 m | |
| MPI | 2×2 = 4 processors | Each tile: 20×20 cells + halos |
| Timestep | 100 s | Small domain → fast integration |
| Runtime | 36 steps = 1 hour physics | Should complete in seconds |

## Input Requirements (in input/ directory)

**data**: Main MITgcm namelist (temperature/salinity setup, timestep, etc.)  
**data.diagnostics**: Output field definitions  
**data.ptracers**: Passive tracer configuration (passive only, no sediment)  
**theta.init**: Initial temperature field (40×40×10)  
**salt.init**: Initial salinity field (40×40×10)  

## Validation Checklist

- [ ] Build completes without errors
- [ ] Executable size > 1 MB
- [ ] Run completes on 4 MPI ranks
- [ ] STDOUT.0000 shows normal completion
- [ ] No segmentation faults
- [ ] No NaN warnings
- [ ] Output files exist (dynDiag.*.data, etc.)

## Next Steps (After Cycle 0 Validates)

Once Cycle 0 passes, Cycle 1 will add:
- Sediment settling physics
- CFL stability check
- Minimal code under `#ifdef ALLOW_SEDIMENT` guards

Cycle 0 establishes the **null hypothesis**: MITgcm runs identically with/without sediment infrastructure.

