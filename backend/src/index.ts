import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import { ethers } from 'ethers'

import PiscineV1Exchange from '../../protocole/out/PiscineV1Exchange.sol/PiscineV1Exchange.json' assert { type: 'json' }
import PiscineV1Pool from '../../protocole/out/PiscineV1Pool.sol/PiscineV1Pool.json' assert { type: 'json' }
import lastDeployment from '../../protocole/broadcast/Anvil.s.sol/1/run-latest.json' assert { type: 'json' }

const app = new Hono()
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL)

const exchangeAddress =
  lastDeployment.transactions[lastDeployment.transactions.length - 1]
    .contractAddress

const exchange = new ethers.Contract(
  exchangeAddress,
  PiscineV1Exchange.abi,
  provider
)

app.get('/api/pools-infos', async (c) => {
  type PoolInfos = {
    address: string
    token0: string
    token1: string
    balance0: string
    balance1: string
  }

  try {
    const poolsLength: number = await exchange.getPoolsLength()
    const poolInfos: PoolInfos[] = []

    for (let i = 0; i < poolsLength; i++) {
      const address = await exchange.pools(i)
      const tokensAndBalances = await exchange.getPoolTokensAndBalances(address)

      const { token0, token1, balance0, balance1 } = tokensAndBalances

      poolInfos.push({
        address,
        token0,
        token1,
        balance0: balance0.toString(),
        balance1: balance1.toString(),
      })
    }

    return c.json(poolInfos)
  } catch (error) {
    return c.json({ error: error }, 500)
  }
})

app.get('/api/swaps-number', async (c) => {
  try {
    const poolsLength: number = await exchange.getPoolsLength()
    let swapsNumber = 0

    for (let i = 0; i < poolsLength; i++) {
      const address = await exchange.pools(i)
      const pool = new ethers.Contract(address, PiscineV1Pool.abi, provider)
      const poolEvents = await pool.queryFilter('TokensSwapped')

      swapsNumber += poolEvents.length
    }

    return c.json(swapsNumber)
  } catch (error) {
    return c.json({ error: error }, 500)
  }
})

app.get('/api/users-addresses', async (c) => {
  try {
    const poolsLength: number = await exchange.getPoolsLength()
    const usersAddresses: string[] = []

    for (let i = 0; i < poolsLength; i++) {
      const address = await exchange.pools(i)
      const pool = new ethers.Contract(address, PiscineV1Pool.abi, provider)
      const poolEvents = await pool.queryFilter('TokensSwapped')

      for (const event of poolEvents) {
        const typedEvent = event as ethers.EventLog
        const swapper = typedEvent.args.swapper

        if (!usersAddresses.includes(swapper)) usersAddresses.push(swapper)
      }

      return c.json(usersAddresses)
    }
  } catch (error) {
    return c.json({ error: error }, 500)
  }
})

app.get('/api/liquidity-providers-addresses', async (c) => {
  try {
    const poolsLength: number = await exchange.getPoolsLength()
    const liquidityProvidersAddresses: string[] = []

    for (let i = 0; i < poolsLength; i++) {
      const address = await exchange.pools(i)
      const pool = new ethers.Contract(address, PiscineV1Pool.abi, provider)
      const poolEvents = await pool.queryFilter('LiquidityAdded')

      for (const event of poolEvents) {
        const typedEvent = event as ethers.EventLog
        const liquidityProvider = typedEvent.args.liquidityProvider

        if (!liquidityProvidersAddresses.includes(liquidityProvider))
          liquidityProvidersAddresses.push(liquidityProvider)
      }
    }

    return c.json(liquidityProvidersAddresses)
  } catch (error) {
    return c.json({ error: error }, 500)
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
