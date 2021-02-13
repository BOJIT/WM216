% DESCRIPTION:  Script called by Git hook to re-version simulink files.
% AUTHOR:       James Bennion-Pedley
% DATE CREATED: 13.02.21

function to2018b(paths)
    files = split(paths, '*');
    for file = files'
        if endsWith(file, ".slx")
            fprintf("Converting File: %s\n", file);
            try
                % Try to close system if it is already open.
                close_system(file, 0);
            catch
                % Nothing here for now.
            end
            % Rename files with 'temp_' prefix.
            [path, name, ext] = fileparts(file);
            tempfile = fullfile(path, strcat("temp_", name, ext));
            movefile(file, tempfile);
            
            % Create r2018b version.
            load_system(tempfile);
            Simulink.exportToVersion(bdroot, file, 'R2018b');
            close_system(tempfile);
            
            % Remove temporary file.
            delete(tempfile);
        end
    end

    % Example file changes
end
