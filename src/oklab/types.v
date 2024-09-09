module oklab

pub struct Lab {
pub mut:
	l f64
	a f64
	b f64
}

pub struct LCh {
pub mut:
	l f64
	c f64
	h f64
}

// RGB values in the range [0, 1].
pub struct RGB {
pub mut:
	r f64
	g f64
	b f64
}
