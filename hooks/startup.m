% DESCRIPTION:  Startup script for initlialising project with
%               forced version saving on commits.
% AUTHOR:       James Bennion-Pedley
% DATE CREATED: 13.02.21


% Create temporary file for Git to use in pre_commit hook.
fd = fopen('hooks/locals', 'w');

% Write MATLAB version to temp file.
matlab_info = ver;
fprintf(fd, [char(matlab_info(1).Release), '\n']);

% Write MATLAB executable path to temp file.
fprintf(fd, [fullfile(matlabroot, 'bin'), '\n']);

% Copy shell script to .git/hooks directory.
copyfile 'hooks/pre-commit' '.git/hooks/';

% Close temp file.
fclose(fd);

% Confirm initialisation occurred correctly.
disp('Project Initialised:');