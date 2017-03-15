package bitsetpool

import (
	"sync"

	"github.com/willf/bitset"
)

type poolItem struct {
	b    bitset.BitSet
	busy bool
}

type BitsetPool struct {
	sync.RWMutex
	pool []poolItem
}

func New() *BitsetPool {
	var bp BitsetPool
	bp.pool = make([]poolItem, 0)
	return &bp
}

func (bp *BitsetPool) Free(i int) {
	bp.Lock()
	bp.pool[i].busy = false
	bp.Unlock()
}

func (bp *BitsetPool) Get() (int, *bitset.BitSet) {
	bp.Lock()
	for i := range bp.pool {
		if !bp.pool[i].busy {
			bp.pool[i].busy = true
			bp.pool[i].b.ClearAll()
			bp.Unlock()
			return i, &bp.pool[i].b
		}
	}
	id := len(bp.pool)
	bp.pool = append(bp.pool, poolItem{})
	bp.Unlock()
	return id, &bp.pool[id].b
}
