module main

import os
import stbi
import arrays

// RGB values in the range [0, 255] (u8).
pub struct RGB {
mut:
	r u8
	g u8
	b u8
}

// RGB values in the range [0, 1] (f64).
struct RGBf64 {
mut:
	r f64
	g f64
	b f64
}

pub struct HSV {
mut:
	h f64
	s f64
	v f64
}

pub struct HSL {
mut:
	h f64
	s f64
	l f64
}

pub struct Image {
	width       int
	height      int
	nr_channels int
mut:
	data []u8
}

pub fn (img Image) get_pixel(x int, y int) RGB {
	if img.nr_channels != 3 {
		panic('nr_channels must be 3')
	}
	index := (y * img.width + x) * img.nr_channels
	return RGB{
		r: img.data[index]
		g: img.data[index + 1]
		b: img.data[index + 2]
	}
}

pub fn (mut img Image) set_pixel(x int, y int, rgb RGB) {
	if img.nr_channels != 3 {
		panic('nr_channels must be 3')
	}
	index := (y * img.width + x) * img.nr_channels
	// img.data[index] = u8(math.clamp(rgb.r, min_u8, max_u8))
	// img.data[index + 1] = u8(math.clamp(rgb.g, min_u8, max_u8))
	// img.data[index + 2] = u8(math.clamp(rgb.b, min_u8, max_u8))
	img.data[index] = rgb.r
	img.data[index + 1] = rgb.g
	img.data[index + 2] = rgb.b
}

fn load_image(image_path string) Image {
	// load image
	params := stbi.LoadParams{
		desired_channels: 0
	}
	buffer := os.read_bytes(image_path) or { panic('failed to read image') }
	img := stbi.load_from_memory(buffer.data, buffer.len, params) or {
		panic('failed to load image')
	}
	data := unsafe {
		arrays.carray_to_varray[u8](img.data, img.width * img.height * img.nr_channels)
	}
	image := Image{
		data:        data
		width:       img.width
		height:      img.height
		nr_channels: img.nr_channels
	}
	return image
}

fn (img Image) save_bmp(image_path string) {
	stbi.stbi_write_bmp(image_path, img.width, img.height, img.nr_channels, img.data.data) or {
		panic('failed to write image')
	}
}
