module oklab

import math

pub fn linear_srgb_to_oklab(c RGB) Lab {
	// https://bottosson.github.io/posts/oklab/#converting-from-linear-srgb-to-oklab
	// https://bottosson.github.io/posts/oklab/#source-code
	l := 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b
	m := 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b
	s := 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b

	l_ := math.cbrt(l)
	m_ := math.cbrt(m)
	s_ := math.cbrt(s)

	return Lab{
		l: 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
		a: 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
		b: 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
	}
}

pub fn oklab_to_linear_srgb(c Lab) RGB {
	// https://bottosson.github.io/posts/oklab/#converting-from-oklab-to-linear-srgb
	// https://bottosson.github.io/posts/oklab/#source-code
	l_ := c.l + 0.3963377774 * c.a + 0.2158037573 * c.b
	m_ := c.l - 0.1055613458 * c.a - 0.0638541728 * c.b
	s_ := c.l - 0.0894841775 * c.a - 1.2914855480 * c.b

	l := l_ * l_ * l_
	m := m_ * m_ * m_
	s := s_ * s_ * s_

	return RGB{
		r: 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
		g: -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
		b: -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
	}
}

pub fn oklab_to_lch(lab Lab) LCh {
	// https://bottosson.github.io/posts/oklab/#converting-from-lab-to-lch
	// https://bottosson.github.io/posts/oklab/#source-code
	l := lab.l
	c := math.sqrt(lab.a * lab.a + lab.b * lab.b)
	mut h := math.atan2(lab.b, lab.a)
	if h < 0 {
		h += 2 * math.pi
	}
	return LCh{
		l: l
		c: c
		h: h
	}
}

pub fn lch_to_oklab(lch LCh) Lab {
	// https://bottosson.github.io/posts/oklab/#converting-from-lch-to-lab
	// https://bottosson.github.io/posts/oklab/#source-code
	l := lch.l
	a := lch.c * math.cos(lch.h)
	b := lch.c * math.sin(lch.h)
	return Lab{
		l: l
		a: a
		b: b
	}
}
