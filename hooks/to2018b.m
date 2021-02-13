% DESCRIPTION:  Script called by Git hook to re-version simulink files.
% AUTHOR:       James Bennion-Pedley
% DATE CREATED: 13.02.21

function to2018b(paths)
    disp(paths);
    fd = fopen('buf.test', 'w');
    fwrite(fd, paths);
    fclose(fd);
    
    % Example file change
end