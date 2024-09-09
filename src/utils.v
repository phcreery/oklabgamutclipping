module main

import math

pub fn clamp_rgbf64_to_rgbu8(c RGBf64) RGB {
	return RGB{
		r: u8(math.clamp(c.r * 255, min_u8, max_u8))
		g: u8(math.clamp(c.g * 255, min_u8, max_u8))
		b: u8(math.clamp(c.b * 255, min_u8, max_u8))
	}
}

pub fn rgbu8_to_rgbf64(c RGB) RGBf64 {
	return RGBf64{
		r: f64(c.r) / 255
		g: f64(c.g) / 255
		b: f64(c.b) / 255
	}
}

pub fn rgbf64_to_rgbu8(c RGBf64) RGB {
	return RGB{
		r: u8(math.clamp(c.r, min_u8, max_u8))
		g: u8(math.clamp(c.g, min_u8, max_u8))
		b: u8(math.clamp(c.b, min_u8, max_u8))
	}
}
