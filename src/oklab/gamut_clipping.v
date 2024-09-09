module oklab

import math

// https://bottosson.github.io/posts/gamutclipping/#source-code
fn clamp(x f64, min f64, max f64) f64 {
	if x < min {
		return min
	}
	if x > max {
		return max
	}
	return x
}

fn sgn(x f64) f64 {
	if x < 0 {
		return -1
	}
	return 1
}

pub fn gamut_clip_preserve_chroma(rgb RGB) RGB {
	if rgb.r < 1.0 && rgb.g < 1.0 && rgb.b < 1.0 && rgb.r > 0.0 && rgb.g > 0.0 && rgb.b > 0.0 {
		return rgb
	}

	lab := linear_srgb_to_oklab(rgb)

	big_l := lab.l
	eps := 0.0001
	big_c := math.max(eps, math.sqrt(lab.a * lab.a + lab.b * lab.b))
	a_ := lab.a / big_c
	b_ := lab.b / big_c

	big_l0 := clamp(big_l, 0.0, 1.0)

	t := find_gamut_intersection(a_, b_, big_l, big_c, big_l0)
	big_l_clipped := big_l0 * (1.0 - t) + t * big_l
	big_c_clipped := t * big_c

	lab_clipped := Lab{
		l: big_l_clipped
		a: big_c_clipped * a_
		b: big_c_clipped * b_
	}

	return oklab_to_linear_srgb(lab_clipped)
}

pub fn gamut_clip_project_to_0_5(rgb RGB) RGB {
	if rgb.r < 1.0 && rgb.g < 1.0 && rgb.b < 1.0 && rgb.r > 0.0 && rgb.g > 0.0 && rgb.b > 0.0 {
		return rgb
	}

	lab := linear_srgb_to_oklab(rgb)

	big_l := lab.l
	eps := 0.0001
	big_c := math.max(eps, math.sqrt(lab.a * lab.a + lab.b * lab.b))
	a_ := lab.a / big_c
	b_ := lab.b / big_c

	big_l0 := 0.5

	t := find_gamut_intersection(a_, b_, big_l, big_c, big_l0)
	big_l_clipped := big_l0 * (1.0 - t) + t * big_l
	big_c_clipped := t * big_c

	lab_clipped := Lab{
		l: big_l_clipped
		a: big_c_clipped * a_
		b: big_c_clipped * b_
	}

	return oklab_to_linear_srgb(lab_clipped)
}
