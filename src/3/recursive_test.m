% Testing recursive struct method

model = struct;
model.L = 1:10;
model.R = 1:5;

% disp(model);

out = struct_combinations(model);

disp(out);

% Function for generating the combinations of all struct inputs.
function output = struct_combinations(input)
    for i = 1:length(input)
        % Get first field with non-scalar value.
        fn = fieldnames(input(i));
        head = 1;
        for j = 1:length(fn)
            if length(input(i).(fn{j})) > 1
                break;
            end
            head = head + 1;
        end
        disp(head);
        disp(input(i));
        
        % Create next struct dimension.
        output = 
        for j = 1:length(input(i).(fn{head}))
            output(i, j) = input(i);
            output(i, j).(fn{head}) = input(i).(fn{head})(j);
        end

        % Recurse if vectors still exist.
        if head >= length(fn)
            % Recursion is done!
            return;
        else
            output = struct_combinations(output);
        end
    end
end