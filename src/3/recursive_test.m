% Testing recursive struct method
clc;clear;close all;

model = struct;
model.L = 1:5;
model.R = 1:4;
model.X = 1:3;

% disp(model);

out = struct_combinations(model);

disp(out);

% Function for generating the combinations of all struct inputs.
function output = struct_combinations(input)
    % Get fields and lengths.
    fn = fieldnames(input);
    output_dim = zeros(1, length(fn));
    for i = 1:length(fn)
        output_dim(i) = length(input.(fn{i}));
    end

    % Create dynamic slicing parameters (remove trailing singleton).
    output_dim = output_dim(1:find(output_dim - 1,1,'last'));
    dim = length(output_dim);
    slice = repmat({':'}, 1, length(output_dim));

    % Preallocate output struct.
    output = repmat(input, [output_dim, 1]);

    % Fill struct slices recursively.
    for i = 1:size(output, dim)
         temp = input;
         temp.(fn{dim}) = input.(fn{dim})(i);
         slice{dim} = i;
         disp(temp);
         % Check if recursion has reached limit.
        if dim > 1
                 output(slice{:}) = struct_combinations(temp);
        else
            % Pass input if singleton.
            output(slice{:}) = temp;
        end
    end
end