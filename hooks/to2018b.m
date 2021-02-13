% DESCRIPTION:  Script called by Git hook to re-version simulink files.
% AUTHOR:       James Bennion-Pedley
% DATE CREATED: 13.02.21

function to2018b(paths)
    files = split(paths, '*');
    for file = files
        if endsWith(file, '.slx')
            disp(file);
        end
    end

    % Example file changes
end
