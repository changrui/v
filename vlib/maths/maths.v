// module to resolve f64 array

module maths

pub fn (f []f64) less(i,j int) bool {


	return false
}

pub fn (f []f64) len() int {


	return 0
}

pub fn (f []f64) swap(i,j int) bool {
	

	return false
}

pub fn (f []f64) sort() {

}

pub fn (f []f64) avg() f64{


	return 0.0
}

pub fn (f []f64) median() f64 {
return 0.0
}

pub fn (f []f64)mode() f64 {
return 0.0
}

fn sort(f []f64) []f64{
	e:=f

	return e.sort()
}

pub fn (f []f64) ajudge() int {
	if f.mode() < f.avg() { 
		if  f.avg()<f.median() {

		} else {

		}

	} else {
		if  f.avg()<f.median() {

		} else {

		}
	}

	return 0
}