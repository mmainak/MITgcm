%==========================================================================
% GENERATE_SIMPLE_TEST_IC.m
%
% Create a simple, uniform initial condition for sediment to test if
% the numerical scheme is working without any complex gradients
%==========================================================================

clear; close all; clc;

% Grid parameters (must match SIZE.h)
sNx = 20; sNy = 4; Nr = 40;
nPx = 2; nPy = 2;
Nx = sNx * nPx; Ny = sNy * nPy;

fprintf('Creating simple test initial condition...\n');
fprintf('Grid: %dx%dx%d\n', Nx, Ny, Nr);

%--------------------------------------------------------------------------
% Create uniform sediment field: C = 0.01 kg/m³ everywhere
%--------------------------------------------------------------------------
% This is a safe, non-zero value that should be stable

sediment_test = 0.01 * ones(Nx, Ny, Nr);

% Write to file
fid = fopen('sediment_init_test.bin', 'w', 'ieee-be');
fwrite(fid, sediment_test, 'float64');
fclose(fid);

fprintf('✅ Created sediment_init_test.bin\n');
fprintf('   Uniform value: %.3f kg/m³\n', 0.01);
fprintf('   Size: %dx%dx%d = %d elements\n', Nx, Ny, Nr, numel(sediment_test));

%--------------------------------------------------------------------------
% Verify the file
%--------------------------------------------------------------------------
fid = fopen('sediment_init_test.bin', 'r', 'ieee-be');
verify = fread(fid, [Nx Ny Nr], 'float64');
fclose(fid);

fprintf('\nVerification:\n');
fprintf('   Min: %.6e\n', min(verify(:)));
fprintf('   Max: %.6e\n', max(verify(:)));
fprintf('   Mean: %.6e\n', mean(verify(:)));
fprintf('   NaN count: %d\n', sum(isnan(verify(:))));
fprintf('   Inf count: %d\n', sum(isinf(verify(:))));

if all(verify(:) == 0.01)
    fprintf('✅ File verified successfully!\n');
else
    warning('File verification failed!');
end

%--------------------------------------------------------------------------
% Also create zero OBCS sediment files (no inflow)
%--------------------------------------------------------------------------
fprintf('\nCreating zero OBCS files (no sediment inflow)...\n');

OBWsed_zero = zeros(Ny, Nr);
OBEsed_zero = zeros(Ny, Nr);

fid = fopen('OBWsed_zero.bin', 'w', 'ieee-be');
fwrite(fid, OBWsed_zero, 'float64');
fclose(fid);

fid = fopen('OBEsed_zero.bin', 'w', 'ieee-be');
fwrite(fid, OBEsed_zero, 'float64');
fclose(fid);

fprintf('✅ Created OBWsed_zero.bin and OBEsed_zero.bin\n');
fprintf('   All values = 0 (no boundary forcing)\n');

fprintf('\n=== TEST FILES READY ===\n');
fprintf('To use these files for minimal test:\n');
fprintf('1. On HPC: cp sediment_init_test.bin sediment_init.bin\n');
fprintf('2. On HPC: cp OBWsed_zero.bin OBWsed.bin\n');
fprintf('3. On HPC: cp OBEsed_zero.bin OBEsed.bin\n');
fprintf('4. On HPC: cp data.sediment_NO_SETTLING data.sediment\n');
fprintf('5. On HPC: cp data.ptracers_MINIMAL_TEST data.ptracers\n');
fprintf('6. Run model and check if NaN still appears\n');
