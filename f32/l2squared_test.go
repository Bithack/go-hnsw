package f32

import (
	"fmt"
	"math/rand"
	"testing"
	"time"
	"unsafe"

	"github.com/stretchr/testify/assert"
)

func DistGo(a, b []float32) (r float32) {
	var d float32
	for i := range a {
		d = a[i] - b[i]
		r += d * d
	}
	return r
}

func Test1(t *testing.T) {
	a := []float32{1}
	b := []float32{4}
	assert.Equal(t, DistGo(a, b), L2Squared(a, b), "Incorrect")
}

func Test4(t *testing.T) {
	a := []float32{1, 2, 3, 4}
	b := []float32{4, 3, 2, 1}
	assert.Equal(t, DistGo(a, b), L2Squared(a, b), "Incorrect")
}

func Test5(t *testing.T) {
	a := []float32{1, 2, 3, 4, 1}
	b := []float32{4, 3, 2, 1, 9}
	assert.Equal(t, DistGo(a, b), L2Squared(a, b), "Incorrect")
}

func Test21(t *testing.T) {
	a := []float32{1, 2, 3, 4, 1, 1, 2, 3, 4, 1, 1, 2, 3, 4, 1, 1, 2, 3, 4, 1, 9}
	b := []float32{4, 3, 2, 1, 9, 4, 3, 2, 1, 9, 4, 3, 2, 1, 9, 4, 3, 2, 1, 9, 0}
	assert.Equal(t, DistGo(a, b), L2Squared(a, b), "Incorrect")
}

func TestAlignment(t *testing.T) {
	for i := 0; i < 10000; i++ {
		a := make([]float32, rand.Intn(256))
		assert.True(t, uintptr(unsafe.Pointer(&a))%16 == 0, "[]float32 Not 16-bytes aligned!")
		assert.True(t, uintptr(unsafe.Pointer(&a))%32 == 0, "[]float32 Not 32-bytes aligned!")
	}
}

func Test24(t *testing.T) {
	a := []float32{1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4}
	b := []float32{4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4}
	assert.Equal(t, DistGo(a, b), L2Squared(a, b), "Incorrect")
	assert.Equal(t, DistGo(b, a), L2Squared8AVX(a, b), "8avx Incorrect")
}

func Test128(t *testing.T) {
	a := []float32{1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4,
		1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4,
		1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4,
		1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4,
	}
	b := []float32{4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4,
		4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4,
		4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4,
		4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4,
	}
	assert.Equal(t, DistGo(a, b), L2Squared(a, b), "Incorrect")
	assert.Equal(t, DistGo(b, a), L2Squared8AVX(a, b), "8avx Incorrect")
}

func TestBenchmark(t *testing.T) {
	a2 := []float32{1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4,
		1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4,
		1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4,
		1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4,
	}
	b2 := []float32{4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4,
		4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4,
		4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4,
		4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4, 4, 3, 1, 4,
	}
	l := 10000000
	fmt.Printf("Testing %v calls with %v dim []float32\n", l, len(a2))

	start := time.Now()
	for i := 0; i < l; i++ {
		L2Squared(a2, b2)
	}
	stop := time.Since(start)
	fmt.Printf("l2squared Done in %v. %v calcs / second\n", stop, float64(l)/stop.Seconds())

	start = time.Now()
	for i := 0; i < l; i++ {
		L2Squared8AVX(a2, b2)
	}
	stop = time.Since(start)
	fmt.Printf("l2squared8AVX Done in %v. %v calcs / second\n", stop, float64(l)/stop.Seconds())

	start = time.Now()
	for i := 0; i < l; i++ {
		DistGo(a2, b2)
	}
	stop = time.Since(start)
	fmt.Printf("Go version done in %v. %v calcs / second\n", stop, float64(l)/stop.Seconds())
}
