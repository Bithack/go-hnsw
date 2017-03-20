# go-hnsw

go-hnsw is a GO implementation of the HNSW approximate nearest-neighbour search algorithm implemented in C++ in https://github.com/searchivarius/nmslib and described in https://arxiv.org/abs/1603.09320

## Usage

Simple usage example. See examples folder for more.
Note that both index building and searching can be safely done in parallel with multiple goroutines.
You can always extend the index, even while searching.

```go
package main

import (
	"fmt"
	"math/rand"
	"time"

	"github.com/Bithack/go-hnsw"
)

func main() {

	const (
		M              = 32
		efConstruction = 400
		efSearch       = 100
		K              = 10
	)

	var zero hnsw.Point = make([]float32, 128)

	h := hnsw.New(M, efConstruction, zero)
	h.Grow(10000)

    // Note that added ID:s must start from 1
	for i := 1; i <= 10000; i++ {
		h.Add(randomPoint(), uint32(i))
		if (i)%1000 == 0 {
			fmt.Printf("%v points added\n", i)
		}
	}
	
	start := time.Now()
	for i := 0; i < 1000; i++ {
		Search(randomPoint, efSearch, K)
	}
	stop := time.Since(start)

	fmt.Printf("%v queries / second (single thread)\n", 1000.0/stop.Seconds())	
}

func randomPoint() hnsw.Point {
	var v hnsw.Point = make([]float32, 128)
	for i := range v {
		v[i] = rand.Float32()
	}
	return v
}

```