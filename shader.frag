//  these external variables are described in the drawFractal(),
//  and sendColorPack() functions in the lua code
extern float window_width;
extern float window_height;
extern float x_center;
extern float y_center;
extern float domain;
extern float color_count;
extern vec3 colors[300];
extern vec3 background_color;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {

  //  only the domain is defined, and then the aspect ratio of the window is
  //   used to calculate the range, this way the fractal is never stretched
  //  TODO: calculate this stuff on the CPU side and use an extern to do these
  //        two calculations for aspect_ratio and range, it should save some
  //        time (most likely marginal)
  float aspect_ratio = window_width / window_height;
  float range = domain / aspect_ratio;

  //  most of this is stolen from the Wikipedia page at:
  //    https://en.wikipedia.org/wiki/Mandelbrot_set#Computer_drawings

  //  normalize the pixel coordinate (supplied in integer pixels) such that the
  //  center of the screen is at x_center and y_center, and the edges of the
  //  screen are domain / 2 and range / 2 away from the center, respectively
  float x0 = x_center + ((float(screen_coords.x) / window_width) * domain) - (domain / 2.0);
  float y0 = y_center + ((float(screen_coords.y) / window_height) * range) - (range / 2.0);

  //  check to see if the point is within the main cardioid (a large portion of
  //  the fractal which never converges and will surely hit the iteration limit)
  //  using some limacon math, if the point is within the cardiod just return
  //  the background color
  //  this is described at:
  //    https://en.wikipedia.org/wiki/Mandelbrot_set#Cardioid_.2F_bulb_checking
  float p = sqrt(pow(x0 - 0.25, 2.0) + pow(y0, 2.0));
  if (x0 < (p - (2.0 * pow(p, 2.0)) + 0.25)) {
    return vec4(background_color, 1.0);
  }

  //  iteration variables
  float x = 0.0;
  float y = 0.0;
  int iteration = 0;
  int max_iterations = 1000;
  float bailout_radius = 256.0;

  //  precalculate the powers of two to prevent them from being calculated twice
  //  every iteration, probably not incredibly significant
  float x_pow_two = pow(x, 2.0);
  float y_pow_two = pow(y, 2.0);

  //  iterate until the bailout_radius or iteration limit is reached
  while((x_pow_two + y_pow_two < bailout_radius) && iteration < max_iterations) {
    float xtemp = x_pow_two - y_pow_two + x0;
    y = 2.0 * x * y + y0;
    x = xtemp;
    iteration += 1;
    x_pow_two = pow(x, 2.0);
    y_pow_two = pow(y, 2.0);
  }

  //  this is an implementation of the continuous coloring escape-time algorithm
  //  described at Wikipedia here:
  //    https://en.wikipedia.org/wiki/Mandelbrot_set#Continuous_.28smooth.29_coloring
  //  and a little better here:
  //    http://yozh.org/2010/12/01/mset005/

  //  store log(2) since it's used a few times
  float log_two = log(2.0);
  if (iteration < max_iterations) {
    float log_zn = log(x_pow_two + y_pow_two) / 2.0;
    float nu = log(log_zn / log_two) / log_two;
    float normalized_iteration = float(iteration) + 1.0 - nu;
    float interp = fract(normalized_iteration);
    vec3 first_color = colors[int(mod(float(iteration), color_count))];
    vec3 second_color = colors[int(mod(float(iteration) + 1.0, color_count))];
    return vec4(mix(first_color, second_color, interp), 1.0);
  } else {
    return vec4(background_color, 1.0);
  }
}
