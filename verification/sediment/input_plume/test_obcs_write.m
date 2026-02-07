% Simple test script to verify OBCS file writing
% Run this on HPC to check if files are written correctly

clear all; close all;

% Grid parameters (must match your setup)
Ny = 8;
Nr = 40;
dy = 5.0;
dz = 5.0;

% Conduit parameters
conduit_j_start = 3;
conduit_j_end = 6;
conduit_k_start = 39;
conduit_k_end = 40;
C_conduit = 1.0;

% Create test array
fprintf('Creating OBWsed array: Ny=%d, Nr=%d\n', Ny, Nr);
OBWsed = zeros(Ny, Nr);

% Fill conduit region
for j = conduit_j_start:conduit_j_end
    for k = conduit_k_start:conduit_k_end
        OBWsed(j, k) = C_conduit;
    end
end

% Print statistics BEFORE writing
fprintf('\n=== BEFORE WRITING ===\n');
fprintf('Array size: %d x %d\n', size(OBWsed,1), size(OBWsed,2));
fprintf('Conduit region (j=%d:%d, k=%d:%d):\n', conduit_j_start, conduit_j_end, conduit_k_start, conduit_k_end);
disp(OBWsed(conduit_j_start:conduit_j_end, conduit_k_start:conduit_k_end));
fprintf('Min value in conduit: %.6f\n', min(min(OBWsed(conduit_j_start:conduit_j_end, conduit_k_start:conduit_k_end))));
fprintf('Max value in conduit: %.6f\n', max(max(OBWsed(conduit_j_start:conduit_j_end, conduit_k_start:conduit_k_end))));
fprintf('Min value overall: %.6f\n', min(OBWsed(:)));
fprintf('Max value overall: %.6f\n', max(OBWsed(:)));
fprintf('Number of non-zero values: %d\n', sum(OBWsed(:) > 0));

% Write file
fprintf('\n=== WRITING FILE ===\n');
filename = 'OBWsed_test.bin';
fid = fopen(filename, 'w', 'ieee-be');
if fid == -1
    error('Could not open file for writing!');
end
count = fwrite(fid, double(OBWsed), 'float64');
fclose(fid);
fprintf('Wrote %d values to %s\n', count, filename);

% Read file back
fprintf('\n=== READING FILE BACK ===\n');
fid = fopen(filename, 'r', 'ieee-be');
if fid == -1
    error('Could not open file for reading!');
end
OBWsed_read = fread(fid, [Ny, Nr], 'float64');
fclose(fid);
fprintf('Read array size: %d x %d\n', size(OBWsed_read,1), size(OBWsed_read,2));

% Compare
fprintf('\n=== VERIFICATION ===\n');
fprintf('Conduit region after read-back:\n');
disp(OBWsed_read(conduit_j_start:conduit_j_end, conduit_k_start:conduit_k_end));
fprintf('Min value in conduit: %.6f\n', min(min(OBWsed_read(conduit_j_start:conduit_j_end, conduit_k_start:conduit_k_end))));
fprintf('Max value in conduit: %.6f\n', max(max(OBWsed_read(conduit_j_start:conduit_j_end, conduit_k_start:conduit_k_end))));
fprintf('Max difference: %.2e\n', max(abs(OBWsed(:) - OBWsed_read(:))));

if max(abs(OBWsed(:) - OBWsed_read(:))) < 1e-10
    fprintf('\n✓ SUCCESS: File written and read correctly!\n');
else
    fprintf('\n✗ ERROR: Values do not match after read-back!\n');
end

% Also check file size
fileinfo = dir(filename);
expected_size = Ny * Nr * 8;  % 8 bytes per float64
fprintf('\nFile size: %d bytes (expected: %d)\n', fileinfo.bytes, expected_size);
if fileinfo.bytes == expected_size
    fprintf('✓ File size correct\n');
else
    fprintf('✗ File size WRONG!\n');
end
