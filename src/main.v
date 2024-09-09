module main

import math
import oklab
import os
import math.vec

fn invert_image(mut newimg Image, img Image) Image {
	for i in 0 .. img.width * img.height * img.nr_channels {
		newimg.data[i] = u8(math.clamp(255 - img.data[i], min_u8, max_u8))
	}
	return newimg
}

fn brightness_image(mut newimg Image, img Image, brightness f64) Image {
	for i in 0 .. img.width * img.height * img.nr_channels {
		newimg.data[i] = u8(math.clamp(img.data[i] + brightness, min_u8, max_u8))
	}
	return newimg
}

fn contrast_image(mut newimg Image, img Image, contrast f64) Image {
	for i in 0 .. img.width * img.height * img.nr_channels {
		newimg.data[i] = u8(math.clamp(img.data[i] * contrast, min_u8, max_u8))
	}
	return newimg
}

fn saturate_image(mut newimg Image, img Image, saturation f64) Image {
	for yy in 0 .. img.height {
		for xx in 0 .. img.width {
			pixel := img.get_pixel(xx, yy)
			mut hsv := rgb2hsv(pixel)
			hsv.s = hsv.s * saturation
			newimg.set_pixel(xx, yy, hsv2rgb(hsv))
		}
	}
	return newimg
}

fn color_image(mut newimg Image, img Image, color RGB) Image {
	for yy in 0 .. img.height {
		for xx in 0 .. img.width {
			pixel := img.get_pixel(xx, yy)
			newimg.set_pixel(xx, yy, RGB{
				r: pixel.r * color.r
				g: pixel.g * color.g
				b: pixel.b * color.b
			})
		}
	}
	return newimg
}

fn color_image_gamut_clip_preserve_chroma(mut newimg Image, img Image, amount f64) Image {
	for yy in 0 .. img.height {
		for xx in 0 .. img.width {
			pixel := img.get_pixel(xx, yy)
			pixel_rgbf64 := rgbu8_to_rgbf64(pixel)
			pixel_oklab := oklab.linear_srgb_to_oklab(oklab.RGB{
				r: pixel_rgbf64.r
				g: pixel_rgbf64.g
				b: pixel_rgbf64.b
			})
			mut pixel_lch := oklab.oklab_to_lch(pixel_oklab)
			pixel_lch.c = pixel_lch.c * amount
			new_pixel_oklab := oklab.lch_to_oklab(pixel_lch)
			mut new_pixel_rgbf64 := oklab.oklab_to_linear_srgb(new_pixel_oklab)
			// new_pixel = oklab.gamut_clip_preserve_chroma(new_pixel_rgbf64)
			new_pixel_rgbf64 = oklab.gamut_clip_project_to_0_5(new_pixel_rgbf64)
			new_pixel_rgbu8 := clamp_rgbf64_to_rgbu8(RGBf64{
				r: new_pixel_rgbf64.r
				g: new_pixel_rgbf64.g
				b: new_pixel_rgbf64.b
			})
			newimg.set_pixel(xx, yy, new_pixel_rgbu8)
		}
	}
	return newimg
}

type RGBf64Modifier = fn (RGBf64) RGBf64

fn modify_image_rgbf64(mut newimg Image, img Image, modifier RGBf64Modifier) Image {
	for yy in 0 .. img.height {
		for xx in 0 .. img.width {
			pixel := img.get_pixel(xx, yy)
			pixel_rgbf64 := rgbu8_to_rgbf64(pixel)
			new_pixel_rgbf64 := modifier(pixel_rgbf64)
			clamped_rgb := clamp_rgbf64_to_rgbu8(new_pixel_rgbf64)
			newimg.set_pixel(xx, yy, clamped_rgb)
		}
	}
	return newimg
}

type OKLABModifier = fn (oklab.Lab) oklab.Lab

fn modify_image_oklab(mut newimg Image, img Image, modifier OKLABModifier) Image {
	for yy in 0 .. img.height {
		for xx in 0 .. img.width {
			pixel := img.get_pixel(xx, yy)
			pixel_rgbf64 := rgbu8_to_rgbf64(pixel)
			pixel_oklab := oklab.linear_srgb_to_oklab(oklab.RGB{
				r: pixel_rgbf64.r
				g: pixel_rgbf64.g
				b: pixel_rgbf64.b
			})
			new_pixel_oklab := modifier(pixel_oklab)
			mut new_pixel_rgbf64 := oklab.oklab_to_linear_srgb(new_pixel_oklab)
			new_pixel_rgbu8 := clamp_rgbf64_to_rgbu8(RGBf64{
				r: new_pixel_rgbf64.r
				g: new_pixel_rgbf64.g
				b: new_pixel_rgbf64.b
			})
			newimg.set_pixel(xx, yy, new_pixel_rgbu8)
		}
	}
	return newimg
}

fn rgb2hsv(rgb RGB) HSV {
	r := rgb.r / 255
	g := rgb.g / 255
	b := rgb.b / 255
	max := math.max(r, math.max(g, b))
	min := math.min(r, math.min(g, b))
	delta := max - min
	mut h := 0.0
	mut s := 0.0
	v := max
	if delta != 0 {
		if max == r {
			h = 60 * (math.fmod((g - b) / delta, 6))
		} else if max == g {
			h = 60 * ((b - r) / delta + 2)
		} else if max == b {
			h = 60 * ((r - g) / delta + 4)
		}
		if max != 0 {
			s = delta / max
		}
	}
	return HSV{
		h: h
		s: s
		v: v
	}
}

fn hsv2rgb(hsv HSV) RGB {
	c := hsv.v * hsv.s
	x := c * (1 - math.abs(math.fmod((hsv.h / 60), 2) - 1))
	m := hsv.v - c
	mut rgb := RGBf64{
		r: 0
		g: 0
		b: 0
	}
	if hsv.h < 60 {
		rgb.r = c
		rgb.g = x
	} else if hsv.h < 120 {
		rgb.r = x
		rgb.g = c
	} else if hsv.h < 180 {
		rgb.g = c
		rgb.b = x
	} else if hsv.h < 240 {
		rgb.g = x
		rgb.b = c
	} else if hsv.h < 300 {
		rgb.r = x
		rgb.b = c
	} else {
		rgb.r = c
		rgb.b = x
	}
	rgb.r = rgb.r + m
	rgb.g = rgb.g + m
	rgb.b = rgb.b + m
	clamped_rgb := clamp_rgbf64_to_rgbu8(rgb)
	return clamped_rgb
}


fn hue2rgb(hue f64) RGBf64 {
	r := math.abs(hue * 6 - 3) - 1
	g := 2 - math.abs(hue * 6 - 2)
	b := 2 - math.abs(hue * 6 - 4)
	return RGBf64{
		r: r
		g: g
		b: b
	}
}


fn hsl2rgb(hsl HSL) RGBf64 {
	c := (1 - math.abs(2 * hsl.l - 1)) * hsl.s
	x := c * (1 - math.abs(math.fmod((hsl.h / 60), 2) - 1))
	m := hsl.l - c / 2
	mut rgb := RGBf64{
		r: 0
		g: 0
		b: 0
	}
	if hsl.h < 60 {
		rgb.r = c
		rgb.g = x
	} else if hsl.h < 120 {
		rgb.r = x
		rgb.g = c
	} else if hsl.h < 180 {
		rgb.g = c
		rgb.b = x
	} else if hsl.h < 240 {
		rgb.g = x
		rgb.b = c
	} else if hsl.h < 300 {
		rgb.r = x
		rgb.b = c
	} else {
		rgb.r = c
		rgb.b = x
	}
	rgb.r = rgb.r + m
	rgb.g = rgb.g + m
	rgb.b = rgb.b + m
	return rgb
}


fn rgb2hcv(rgb RGBf64) HSV {
	epsilon := 1e-10
	mut p := vec.vec4[f64](0, 0, 0, 0)
	mut q := vec.vec4[f64](0, 0, 0, 0)
	if rgb.g < rgb.b {
		p = vec.vec4[f64](rgb.b, rgb.g, -1, 2 / 3)
	} else {
		p = vec.vec4[f64](rgb.g, rgb.b, 0, -1 / 3)
	}
	if rgb.r < p.x {
		q = vec.vec4[f64](p.x, p.y, p.w, rgb.r)
	} else {
		q = vec.vec4[f64](rgb.r, p.y, p.z, p.x)
	}
	c := q.x - math.min(q.w, q.y)
	h := math.abs((q.w - q.y) / (6 * c + epsilon) + q.z)
	return HSV{
		h: h
		s: c
		v: q.x
	}
}

fn rgb2hsl(rgb RGBf64) HSL {
	r := rgb.r
	g := rgb.g
	b := rgb.b
	max := math.max(r, math.max(g, b))
	min := math.min(r, math.min(g, b))
	c := max - min
	mut hue := 0.0
	if c == 0 {
		hue = 0
	} else {
		if max == r {
			segment := (g - b) / c
			mut shift := 0 / 60
			if segment < 0 {
				shift = 360 / 60
			}
			hue = segment + shift
		} else if max == g {
			segment := (b - r) / c
			shift := 120 / 60
			hue = segment + shift
		} else if max == b {
			segment := (r - g) / c
			shift := 240 / 60
			hue = segment + shift
		}
	}
	mut h := hue * 60

	// Make negative hues positive behind 360°
	if h < 0 {
		h = 360 + h
	}

	l := (max + min) / 2
	mut s := 0.0
	if c != 0 {
		s = c / (1 - math.abs(2 * l - 1))
	} else {
		s = 0
	}

	return HSL{
		h: h
		s: s
		l: l
	}
}


fn mix_colors(color1 RGBf64, color2 RGBf64, amount f64) RGBf64 {
	// Mix two colors together
	// https://stackoverflow.com/questions/726549/algorithm-for-additive-color-mixing-for-rgb-values
	// https://registry.khronos.org/OpenGL-Refpages/gl4/html/mix.xhtml
	a := math.clamp(amount, 0, 1)
	r := color1.r * (1 - a) + color2.r * a
	g := color1.g * (1 - a) + color2.g * a
	b := color1.b * (1 - a) + color2.b * a
	return RGBf64{
		r: r
		g: g
		b: b
	}
}

fn luminance(color RGBf64) f64 {
	fmin := math.min(math.min(color.r, color.g), color.b)
	fmax := math.max(math.max(color.r, color.g), color.b)
	return (fmax + fmin) / 2.0
}

fn adjust_temp(pixel RGBf64, temperature f64, amount f64) RGBf64 {
	// adjust the temperature of the image
	// https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
	// https://www.shadertoy.com/view/lsSXW1

	// Temperature must be between 1000 and 40000
	temp := math.clamp(temperature, 1000, 40000) / 100
	mut r := f64(0)
	mut g := f64(0)
	mut b := f64(0)

	// this is for RGB 0-1
	if temp <= 66 {
		r = 1
		g = math.log(temp) * 0.39008157876901960784 - 0.63184144378862745098
	} else {
		t := temp - 60
		r = math.pow(t, -0.1332047592) * 1.29293618606274509804
		g = math.pow(t, -0.0755148492) * 1.12989086089529411765
	}

	if temp >= 66 {
		b = 1
	} else if temp <= 19 {
		b = 0
	} else {
		b = math.log(temp - 10) * 0.54320678911019607843 - 1.19625408914
	}

	color_temp := RGBf64{
		r: r
		g: g
		b: b
	}
	color_temp_times_pixel := RGBf64{
		r: pixel.r * color_temp.r
		g: pixel.g * color_temp.g
		b: pixel.b * color_temp.b
	}
	original_luminance := luminance(pixel)
	blended := mix_colors(pixel, color_temp_times_pixel, amount)
	mut result_hsl := rgb2hsl(blended)
	result_hsl.l = original_luminance
	result_rgb := hsl2rgb(result_hsl)
	return result_rgb
	// return color_temp
}

fn main() {
	// input_image := 'Lenna.png'
	input_image := 'LIT_9419.JPG'
	image := load_image(input_image)
	// COPY IMAGE
	mut image_color_image_gamut_clip_preserve_chroma := image

	// EDIT IMAGE
	// invert_image(mut inverted_image, image)
	// brightness_image(mut inverted_image, image, 40)
	// contrast_image(mut inverted_image, image, 1.5)
	// saturate_image(mut inverted_image, image, 1.5)
	// color_image(mut inverted_image, image, RGB{r: 1.5, g: 1, b: 1})
	// color_image_gamut_clip_preserve_chroma(mut image_color_image_gamut_clip_preserve_chroma,
	// 	image, 1.5)
	// println(inverted_image.get_pixel(0, 0))

	// modify_image_rgbf64(mut image_color_image_gamut_clip_preserve_chroma, image,
	// 	fn (rgb RGBf64) RGBf64 {
	// 		return RGBf64{
	// 			r: rgb.r * 1.5
	// 			g: rgb.g
	// 			b: rgb.b
	// 		}
	// 	})

	// increase the chroma of the colors
	// modify_image_oklab(mut image_color_image_gamut_clip_preserve_chroma, image,
	// 	fn (lab oklab.Lab) oklab.Lab {
	// 		mut pixel_lch := oklab.oklab_to_lch(lab)
	// 		pixel_lch.c = pixel_lch.c * 4.5
	// 		return oklab.lch_to_oklab(pixel_lch)
	// 	})

	// increase the chroma of the colors
	modify_image_rgbf64(mut image_color_image_gamut_clip_preserve_chroma, image, fn (pixel_rgbf64 RGBf64) RGBf64 {
		// mut pixel_rgbu8 := rgbf64_to_rgbu8(pixel_rgbf64)
		temp_pixel_rgbf64 := adjust_temp(pixel_rgbf64, 4500, 1.0)
		// pixel_rgbf64 = rgbu8_to_rgbf64(pixel_rgbu8)
		mut pixel_oklab := oklab.linear_srgb_to_oklab(oklab.RGB{
			r: temp_pixel_rgbf64.r
			g: temp_pixel_rgbf64.g
			b: temp_pixel_rgbf64.b
		})
		mut pixel_lch := oklab.oklab_to_lch(pixel_oklab)
		pixel_lch.l = pixel_lch.l * 1.2
		pixel_lch.c = pixel_lch.c * 2.5
		colorized_pixel_oklab := oklab.lch_to_oklab(pixel_lch)
		mut new_pixel_rgbf64 := oklab.oklab_to_linear_srgb(colorized_pixel_oklab)
		// new_pixel_rgbf64 = oklab.gamut_clip_preserve_chroma(new_pixel_rgbf64)
		new_pixel_rgbf64 = oklab.gamut_clip_project_to_0_5(new_pixel_rgbf64)
		return RGBf64{
			r: new_pixel_rgbf64.r
			g: new_pixel_rgbf64.g
			b: new_pixel_rgbf64.b
		}
	})

	output_image := '${input_image}_edit.bmp'
	os.rm(output_image) or { println('Failed to remove the file') }
	image_color_image_gamut_clip_preserve_chroma.save_bmp(output_image)

}
