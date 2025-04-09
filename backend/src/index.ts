import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import { ethers } from 'ethers'

const app = new Hono()
const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545/')

const blockNumber = await provider.getBlockNumber()

app.get('/', (c) => {
  return c.text(blockNumber.toString())
})

serve(
  {
    fetch: app.fetch,
    port: 3000,
  },
  (info) => {
    console.log(`Server is running on http://localhost:${info.port}`)
  }
)
