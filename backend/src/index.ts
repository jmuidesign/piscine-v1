import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import { ethers } from 'ethers'

import PiscineV1Exchange from '../../protocole/out/PiscineV1Exchange.sol/PiscineV1Exchange.json' assert { type: 'json' }
import PiscineV1Pool from '../../protocole/out/PiscineV1Pool.sol/PiscineV1Pool.json' assert { type: 'json' }
import lastDeployment from '../../protocole/broadcast/Anvil.s.sol/1/run-latest.json' assert { type: 'json' }

const app = new Hono()
const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545/')

const exchangeAddress =
  lastDeployment.transactions[lastDeployment.transactions.length - 1]
    .contractAddress

const exchange = new ethers.Contract(
  exchangeAddress,
  PiscineV1Exchange.abi,
  provider
)

app.get('/api/pools-tokens-and-balances', async (c) => {
  try {
    const poolsLength = await exchange.getPoolsLength()
    const pools = []

    for (let i = 0; i < poolsLength; i++) {
      const address = await exchange.pools(i)
      const tokensAndBalances = await exchange.getPoolTokensAndBalances(address)

      const { token0, token1, balance0, balance1 } = tokensAndBalances

      pools.push({
        address,
        token0,
        token1,
        balance0: balance0.toString(),
        balance1: balance1.toString(),
      })
    }

    return c.json(pools)
  } catch (error) {
    console.error(error)
  }
})

app.get('/api/swaps-number', async (c) => {
  try {
    let swapsNumber = 0
    const poolsLength = await exchange.getPoolsLength()

    for (let i = 0; i < poolsLength; i++) {
      const address = await exchange.pools(i)
      const pool = new ethers.Contract(address, PiscineV1Pool.abi, provider)
      const poolEvents = await pool.queryFilter('TokensSwapped')

      swapsNumber += poolEvents.length
    }

    return c.json(swapsNumber)
  } catch (error) {
    console.error(error)
  }
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
