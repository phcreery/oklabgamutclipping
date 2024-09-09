module main

// import v.reflection as ref

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

type PixelRepresenation = RGB | RGBf64

type PixelEditFn = fn (mut PixelRepresenation) PixelRepresenation

// type PixelEditFn = fn (mut RGB) RGB
// 	| fn (mut RGBf64) RGBf64
// 	| fn (mut RGB) RGBf64
// 	| fn (mut RGBf64) RGB


struct PixelEditStep {
pub mut:
	func PixelEditFn = unsafe { nil }
}

struct PixelEditPipeline {
pub mut:
	steps []PixelEditStep
}

fn (mut pipeline PixelEditPipeline) addstep(step PixelEditStep) {
	// pipeline.steps << unsafe { PixelEditFn(step) }
	pipeline.steps << step
}

fn (mut pipeline PixelEditPipeline) exec(mut pixel PixelRepresenation) PixelRepresenation {
	mut newpixel := pixel
	for step in pipeline.steps {
		dump(step)
		dump(newpixel)

		if pixel is RGB {
			// Cast pixel type to RGB
			println('RGB')
			dump(pixel)
			pixel = step.func(mut pixel)
			dump(newpixel)
		} else if pixel is RGBf64 {
			// Cast pixel type to RGBf64
			println('RGBf64')
			pixel = step.func(mut newpixel)
		} else {
			println('no match')
			return pixel
		}

		// dump(pix2)
		// dump(PixelRepresenation(pix).type_name()) // input type name
		// dump(pix2.type_name()) // output type name
		// dump(pix2.type_name() is RGB) // output type name
	}
	return newpixel
}

// A function from external library
fn pixfn1(mut pixel RGB) RGB {
	println('modifying pixel')
	dump(pixel)
	pixel.r = 2
	dump(pixel)
	return pixel
}

fn main() {
	mut pix := RGB{
		r: 1
		g: 2
		b: 3
	}

	mut pipeline := PixelEditPipeline{
		steps: []PixelEditStep{}
	}

	step := PixelEditStep{
		// func: unsafe {PixelEditFn(pixfn1)} // this works but reference gets lost somewhere
		func: pixfn1 // erros because of type mismatch
	}
	pipeline.addstep(step)
	newpix := pipeline.exec(mut PixelRepresenation(pix))

	println(newpix)

	// println(PixelRepresenation(pix))
	// println((PixelRepresenation(pix) as RGB).r)
	// println(typeof(pixfn1))
	// println(typeof(pixfn1))
	// println(typeof(pixfn1).name)
	// println(typeof(pix).name)

	// println((ref.type_of(oklab.gamut_clip_project_to_0_5).sym.info as ref.Function).return_typ)
	// println(ref.type_of(oklab.gamut_clip_project_to_0_5).sym.info)
	// println(ref.type_of(oklab.gamut_clip_project_to_0_5))
}
