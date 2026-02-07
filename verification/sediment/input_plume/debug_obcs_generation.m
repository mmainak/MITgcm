% DEBUG: Test OBCS array generation
clear all; close all;

% Grid
Ny = 8;
Nr = 40;
dy = 5.0;
dz = 5.0;
Ly = Ny * dy;

% Conduit
conduit_width = 20;
conduit_height = 10;
conduit_j_start = floor((Ly/2 - conduit_width/2) / dy) + 1;
conduit_j_end = floor((Ly/2 + conduit_width/2) / dy);
conduit_k_start = Nr - conduit_height/dz + 1;
conduit_k_end = Nr;

fprintf('=== CONDUIT CALCULATION ===\n');
fprintf('Ly = %.1f m\n', Ly);
fprintf('conduit_width = %.1f m\n', conduit_width);
fprintf('conduit_height = %.1f m\n', conduit_height);
fprintf('dy = %.1f m, dz = %.1f m\n', dy, dz);
fprintf('\nCalculated indices:\n');
fprintf('j: %d to %d (should be 3 to 6)\n', conduit_j_start, conduit_j_end);
fprintf('k: %d to %d (should be 39 to 40)\n', conduit_k_start, conduit_k_end);

% Discharge properties
C_conduit = 1.0;
fprintf('\nC_conduit = %.1f kg/m^3\n', C_conduit);

% Create array
fprintf('\n=== CREATING ARRAY ===\n');
OBWsed = zeros(Ny, Nr);
fprintf('Initialized OBWsed: size %dx%d, all zeros\n', size(OBWsed,1), size(OBWsed,2));

% Fill conduit region
fprintf('\n=== FILLING CONDUIT ===\n');
fprintf('Loop: j=%d:%d, k=%d:%d\n', conduit_j_start, conduit_j_end, conduit_k_start, conduit_k_end);
count = 0;
for j = conduit_j_start:conduit_j_end
    for k = conduit_k_start:conduit_k_end
        OBWsed(j, k) = C_conduit;
        count = count + 1;
        fprintf('  Set OBWsed(%d,%d) = %.1f\n', j, k, C_conduit);
    end
end
fprintf('Total cells filled: %d (should be 8: 4j × 2k)\n', count);

% Check result
fprintf('\n=== VERIFICATION ===\n');
fprintf('Max value: %.6f (should be 1.0)\n', max(OBWsed(:)));
fprintf('Min value: %.6f (should be 0.0)\n', min(OBWsed(:)));
fprintf('Number of non-zero cells: %d (should be 8)\n', sum(OBWsed(:) > 0));
fprintf('\nConduit region values:\n');
disp(OBWsed(conduit_j_start:conduit_j_end, conduit_k_start:conduit_k_end));

% Write file
fprintf('\n=== WRITING FILE ===\n');
fid = fopen('OBWsed_debug.bin', 'w', 'ieee-be');
count = fwrite(fid, OBWsed, 'float64');
fclose(fid);
fprintf('Wrote %d values to OBWsed_debug.bin\n', count);

% Read back
fprintf('\n=== READING BACK ===\n');
fid = fopen('OBWsed_debug.bin', 'r', 'ieee-be');
OBWsed_check = fread(fid, [Ny, Nr], 'float64');
fclose(fid);
fprintf('Read back array size: %dx%d\n', size(OBWsed_check,1), size(OBWsed_check,2));
fprintf('Conduit region after read:\n');
disp(OBWsed_check(conduit_j_start:conduit_j_end, conduit_k_start:conduit_k_end));

if max(abs(OBWsed(:) - OBWsed_check(:))) < 1e-10
    fprintf('\n✓ SUCCESS!\n');
else
    fprintf('\n✗ MISMATCH!\n');
end
