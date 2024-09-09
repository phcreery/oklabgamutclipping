module oklab

import math

// Finds the maximum saturation possible for a given hue that fits in sRGB
// Saturation here is defined as S = C/L
// a and b must be normalized so a^2 + b^2 == 1
pub fn compute_max_saturation(a f64, b f64) f64 {
	mut k0 := 0.0
	mut k1 := 0.0
	mut k2 := 0.0
	mut k3 := 0.0
	mut k4 := 0.0
	mut wl := 0.0
	mut wm := 0.0
	mut ws := 0.0

	if -1.88170328 * a - 0.80936493 * b > 1 {
		// Red component
		k0 = 1.19086277
		k1 = 1.76576728
		k2 = 0.59662641
		k3 = 0.75515197
		k4 = 0.56771245
		wl = 4.0767416621
		wm = -3.3077115913
		ws = 0.2309699292
	} else if 1.81444104 * a - 1.19445276 * b > 1 {
		// Green component
		k0 = 0.73956515
		k1 = -0.45954404
		k2 = 0.08285427
		k3 = 0.12541070
		k4 = 0.14503204
		wl = -1.2684380046
		wm = 2.6097574011
		ws = -0.3413193965
	} else {
		// Blue component
		k0 = 1.35733652
		k1 = 0.00915799
		k2 = -1.15130210
		k3 = -0.50559606
		k4 = 0.00692167
		wl = -0.0041960863
		wm = -0.7034186147
		ws = 1.7076147010
	}

	// Approximate max saturation using a polynomial:
	mut big_s := k0 + k1 * a + k2 * b + k3 * a * a + k4 * a * b

	// Do one step Halley's method to get closer
	// this gives an error less than 10e6, except for some blue hues where the dS/dh is close to infinite
	// this should be sufficient for most applications, otherwise do two/three steps
	k_l := 0.3963377774 * a + 0.2158037573 * b
	k_m := -0.1055613458 * a - 0.0638541728 * b
	k_s := -0.0894841775 * a - 1.2914855480 * b

	l_ := 1.0 + big_s * k_l
	m_ := 1.0 + big_s * k_m
	s_ := 1.0 + big_s * k_s

	l := l_ * l_ * l_
	m := m_ * m_ * m_
	s := s_ * s_ * s_

	l_d_s := 3.0 * k_l * l_ * l_
	m_d_s := 3.0 * k_m * m_ * m_
	s_d_s := 3.0 * k_s * s_ * s_

	l_d_s2 := 6.0 * k_l * k_l * l
	m_d_s2 := 6.0 * k_m * k_m * m
	s_d_s2 := 6.0 * k_s * k_s * s

	f := wl * l + wm * m + ws * s
	f1 := wl * l_d_s + wm * m_d_s + ws * s_d_s
	f2 := wl * l_d_s2 + wm * m_d_s2 + ws * s_d_s2

	big_s = big_s - f * f1 / (f1 * f1 - 0.5 * f * f2)

	return big_s
}

// finds L_cusp and C_cusp for a given hue
// a and b must be normalized so a^2 + b^2 == 1
struct LC {
	l f64
	c f64
}

pub fn find_cusp(a f64, b f64) LC {
	// First, find the maximum saturation (saturation S = C/L)
	big_s_cusp := compute_max_saturation(a, b)

	// Convert to linear sRGB to find the first point where at least one of r,g or b >= 1:
	rgb_at_max := oklab_to_linear_srgb(Lab{1, big_s_cusp * a, big_s_cusp * b})
	big_l_cusp := math.cbrt(1.0 / math.max(math.max(rgb_at_max.r, rgb_at_max.g), rgb_at_max.b))
	big_c_cusp := big_l_cusp * big_s_cusp

	return LC{big_l_cusp, big_c_cusp}
}

// Finds intersection of the line defined by
// L = L0 * (1 - t) + t * L1;
// C = t * C1;
// a and b must be normalized so a^2 + b^2 == 1
pub fn find_gamut_intersection(a f64, b f64, big_l1 f64, big_c1 f64, big_l0 f64) f64 {
	// Find the cusp
	cusp := find_cusp(a, b)

	// Find the intersection
	mut t := 0.0

	if ((big_l1 - big_l0) * cusp.c - (cusp.l - big_l0) * big_c1) <= 0 {
		// Lower half
		t = cusp.c * big_l0 / (big_c1 * cusp.l + cusp.c * (big_l0 - big_l1))
	} else {
		// Upper half
		// First intersect with triangle
		t = cusp.c * (big_l0 - 1) / (big_c1 * (cusp.l - 1) + cusp.c * (big_l0 - big_l1))

		// Then one step Halley's method
		d_big_l := big_l1 - big_l0
		d_big_c := big_c1

		k_l := 0.3963377774 * a + 0.2158037573 * b
		k_m := -0.1055613458 * a - 0.0638541728 * b
		k_s := -0.0894841775 * a - 1.2914855480 * b

		l_dt := d_big_l + d_big_c * k_l
		m_dt := d_big_l + d_big_c * k_m
		s_dt := d_big_l + d_big_c * k_s

		// If higher accuracy is required, 2 or 3 iterations of the following block can be used:
		big_l := big_l0 * (1 - t) + t * big_l1
		big_c := t * big_c1

		l_ := big_l + big_c * k_l
		m_ := big_l + big_c * k_m
		s_ := big_l + big_c * k_s

		l := l_ * l_ * l_
		m := m_ * m_ * m_
		s := s_ * s_ * s_

		ldt := 3 * l_dt * l_ * l_
		mdt := 3 * m_dt * m_ * m_
		sdt := 3 * s_dt * s_ * s_

		ldt2 := 6 * l_dt * l_dt * l_
		mdt2 := 6 * m_dt * m_dt * m_
		sdt2 := 6 * s_dt * s_dt * s_

		r := 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s - 1
		r1 := 4.0767416621 * ldt - 3.3077115913 * mdt + 0.2309699292 * sdt
		r2 := 4.0767416621 * ldt2 - 3.3077115913 * mdt2 + 0.2309699292 * sdt2

		u_r := r1 / (r1 * r1 - 0.5 * r * r2)
		mut t_r := -r * u_r

		g := -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s - 1
		g1 := -1.2684380046 * ldt + 2.6097574011 * mdt - 0.3413193965 * sdt
		g2 := -1.2684380046 * ldt2 + 2.6097574011 * mdt2 - 0.3413193965 * sdt2

		u_g := g1 / (g1 * g1 - 0.5 * g * g2)
		mut t_g := -g * u_g

		b0 := -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s - 1
		b1 := -0.0041960863 * ldt - 0.7034186147 * mdt + 1.7076147010 * sdt
		b2 := -0.0041960863 * ldt2 - 0.7034186147 * mdt2 + 1.7076147010 * sdt2

		u_b := b1 / (b1 * b1 - 0.5 * b0 * b2)
		mut t_b := -b0 * u_b

		t_r = if u_r >= 0 { t_r } else { math.max_f64 }
		t_g = if u_g >= 0 { t_g } else { math.max_f64 }
		t_b = if u_b >= 0 { t_b } else { math.max_f64 }

		t = t + math.min(t_r, math.min(t_g, t_b))
	}

	return t
}
