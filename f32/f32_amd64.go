//+build !noasm,!appengine

package f32

func L2Squared(x, y []float32) float32

func L2Squared8AVX(x, y []float32) float32
