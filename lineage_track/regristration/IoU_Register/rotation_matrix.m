function R = rotation_matrix(theta_x, theta_y, theta_z)

Rx = [1, 0, 0;
      0, cos(theta_x), -sin(theta_x);
      0, sin(theta_x), cos(theta_x)];

Ry = [cos(theta_y), 0, sin(theta_y);
      0, 1, 0;
      -sin(theta_y), 0, cos(theta_y)];
Rz = [cos(theta_z), -sin(theta_z), 0;
      sin(theta_z), cos(theta_z), 0;
      0, 0, 1];

R = Rx * Ry * Rz;
end

