const Koa = require('koa')
const Redis = require('ioredis')
const cors = require('koa2-cors')
const Router = require('koa-router')
const static = require('koa-static')
const bodyParser = require('koa-bodyparser')

const app = new Koa()
const Routers = new Router()
const redis = new Redis({ port: 6379, host: '127.0.0.1', db: 2 })

const staticPath = './static'
const CortexNodeList = 'CortexNodeList'

app.use(static(__dirname + staticPath))

Routers.get('/nodelist', async ctx => {
    ctx.body = 'home'
}).get('/nodelist/show', async ctx => {
    let nodes = await redis.get(CortexNodeList)
    nodes = nodes ? JSON.parse(nodes) : []
    for (let i = 0; i < nodes.length; ++i) {
        let t = await redis.get(nodes[i])
        nodes[i] = JSON.parse(t)
    }
    ctx.body = nodes
}).post('/nodelist/send', async ctx => {
    const ip = ctx.request.headers['x-forwarded-for'] || ctx.request.connection.remoteAddress
    const gpuinfo = ctx.request.body.gpu
    const mac = ctx.request.body.mac
    const logs = ctx.request.body.log
    const sysinfo = ctx.request.body.info
    const time = new Date()
    let blockNumber = 0
    for (let x of logs) {
        let matchResult = x.match(/number=[0-9]+/g)
        if (!matchResult) continue
        blockNumber = parseInt(matchResult[0].substr(8))
    }
    let nodes = await redis.get(CortexNodeList)
    nodes = nodes ? JSON.parse(nodes) : []
    if (nodes.indexOf(mac) == -1) {
        nodes.push(mac)
    }

    if (blockNumber == 0) {
        let olddata_raw = await redis.get(mac)
        let olddata = JSON.parse(olddata_raw)
        if (olddata.blockNumber != 0) {
            blockNumber = olddata.blockNumber
        }
    }

    let data = { ip, mac, sysinfo, gpuinfo, logs, blockNumber, time }
    await redis.set(mac, JSON.stringify(data))
    await redis.set(CortexNodeList, JSON.stringify(nodes))

    ctx.body = ip
})

app.use(cors())
app.use(bodyParser())
app.use(Routers.routes())
app.use(async ctx => {
    console.log(ctx.url, ctx.method)
})

app.listen(8899)

