function [Transform, E] = IoU_register(x, y, rx, ry, weight, numTrials)

% probably bad guess
DOF0 = [0; 0; 0; zeros(3, 1)];

obj_handle = @(DOF) objective(DOF, x, y, rx, ry, weight);

% get a good guess
DOF0_best = DOF0;
E0_best = obj_handle(DOF0);
for ii = 1:numTrials
    theta_x = 2 * pi * rand;
    theta_y = 2 * pi * rand;
    theta_z = 2 * pi * rand;
    DOF0 = [theta_x; theta_y; theta_z; zeros(3, 1)];
    E0 = obj_handle(DOF0);

    if E0 < E0_best
        E0_best = E0;
        DOF0_best = DOF0;
    end
end

% refine best guess
options = optimoptions('fminunc', 'Display', 'none');
DOF_min = fminunc(obj_handle, DOF0_best, options);

theta_x_min = DOF_min(1);
theta_y_min = DOF_min(2);
theta_z_min = DOF_min(3);
Transform.R = rotation_matrix(theta_x_min, theta_y_min, theta_z_min);
Transform.t = reshape(DOF_min(4:6), 3, 1);
Transform.s = 1;
Transform.method = 'rigid';

y_transform = y * Transform.R.' + Transform.t.';

N = size(x, 1);
M = size(y, 1);

P = sphere_IoU(x, y_transform, rx, ry);
p = (1 - weight) * sum(P, 2) / M + weight / N;
E = -sum(log(p)) / N;

end

function E = objective(DOF, x, y, rx, ry, weight)

theta_x = DOF(1);
theta_y = DOF(2);
theta_z = DOF(3);
rotation = rotation_matrix(theta_x, theta_y, theta_z);
translation = reshape(DOF(4:6), 1, 3);

y_transform = y * rotation.' + translation;

N = size(x, 1);
M = size(y, 1);

P = sphere_IoU(x, y_transform, rx, ry);
p = (1 - weight) * sum(P, 2) / M + weight / N;
E = -sum(log(p)) / N;

end

