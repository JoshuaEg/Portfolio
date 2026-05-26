
const fs = require('fs');
const express = require("express");
const ejs = require("ejs");
const bp = require("body-parser");
const cookieParser = require("cookie-parser");
const path = require("path");
const cheerio = require("cheerio");

const exp = express(); 
const router = express.Router();

exp.engine('shtml', require('ejs').renderFile);
require("dotenv").config({
    path: path.resolve(__dirname, "../envFol/.env"),
 });
router.use(cookieParser());
const { MongoClient, ServerApiVersion } = require("mongodb");
const { time } = require('console');

//const passData = "UserPasswords"
const userData = "UserData"
const userKids = "UserChildren"
router.use(bp.urlencoded({extended:false}));
router.use(bp.json());
const databaseName = "StudyData";
const uri = process.env.MONGO_CONNECTION_STRING;
const client = new MongoClient(uri, { serverApi: ServerApiVersion.v1 });
const portNumber = 7510

router.get("/", async (req, res) => {
    let user = req.cookies.login
    if(!user){
        res.redirect("../")
    }
    user = JSON.parse(user)
    await fetch(`http://localhost:${portNumber}/game/kill`,{
        method: "POST", headers: {
        'Content-Type': 'application/json'
        },
        body: JSON.stringify({login: user})
    })

    await client.connect()
    const collection = client.db(databaseName).collection(userData)
    //process death
    const data = await collection.findOne({name: user.name})
    
    const name = data.name
    const lastIncident = data.data.daysSince
    //const record = data.data.longestSurvived
    const kills = data.data.killCount
    const population = data.data.aliveCount
   
    await fs.readFile("loggedIn.shtml", (_, dat) => {
        const $ = cheerio.load(dat)
        $(".username").text(`${name}`)
        $("#since").text(`${lastIncident}`)
        $("#alive").text(`${population}`)
        $("#total").text(`${population + kills}`)
        res.end($.html())
    })


    client.close
})

router.get("/logout", (_, res) => {
    console.log("Logging out")
    res.clearCookie("login").redirect("/..")
})

router.post("/feedKid", async (req,res) => {
    const name = req.body.name
    const user = JSON.parse(req.cookies.login)
    await client.connect();
    const collection = client.db(databaseName).collection(userKids)
    const kids = await collection.findOne({name: user.name})
    const kid = kids.kids.find(k => k.name === name)
    if(!kid){
        res.status(404).json("error 404: kid not found")
        client.close()
        return
    }
    let {lastFed, deathDay} = kid
    const now = Date.now()
    if(deathDay < now){
        client.close()
        await fetch(`http://localhost:${portNumber}/game/kill`,{
            method: "POST", headers: {
            'Content-Type': 'application/json'
            },
            body: JSON.stringify({login: user})
        })
        res.status(450).json("kid is dead, womp womp")
        return
    }
    if(now-lastFed < hoursToMili(18)){
        client.close()
        res.status(460).json("18 hour cooldown not finished")
        return
    }

    let newTime;
    if(deathDay - now < hoursToMili(2)){
        newTime = deathDay + hoursToMili(24)
    }else{
        newTime = now + hoursToMili(24)
    }

    kid.lastFed = now
    kid.deathDay = newTime
    kid.daysLasted++

    const arr = await collection.updateOne(
        {name: user.name},
        {$set: {kids: kids.kids}}
    )
    client.close();
    res.status(202).json(kid);
})

router.post("/new", async (req, res) => {
    const name = req.body.name
    if(name === "") return
    await client.connect()
    const pet = {
        name: name,
        lastFed: Date.now(),
        deathDay: Date.now() + hoursToMili(24),
        daysLasted: 0
    }
    let user = req.cookies.login
    user = JSON.parse(user)
    const collection = client.db(databaseName).collection(userKids)
    const datCol = client.db(databaseName).collection(userData)
    const a = datCol.updateOne({name: user.name}, {$inc: {"data.aliveCount": 1}})
    const arr = await collection.updateOne(
        {name: user.name},
        {$push: {kids: pet}}
    )
    res.json(pet)
    await a
    client.close()
})

router.get("/dispKid",async (req, res) => {
    
    const name = req.query.name
    if(name === "") return
    await client.connect()
    let user = req.cookies.login
    user = JSON.parse(user)
    const collection = client.db(databaseName).collection(userKids)
    const petsOf = await collection.findOne({name:user.name})
    
    const kid = petsOf.kids.find(k => k.name === name);

    client.close()
    
   if(!kid){
        res.status(404).json({err:"error 404: kid not found"})
        res.end()
        return
   }
   
   res.json(kid)
 
})

router.post("/kill", async (req, res) =>{
    //console.log("actually killing shit")
    await client.connect()
    let user = req.body.login
    //console.log(user)
    const dataCol = client.db(databaseName).collection(userData)
    const kidCol = client.db(databaseName).collection(userKids)
    let data = await dataCol.findOne({name: user.name})
    const kids = await kidCol.findOne({name: user.name})
    const [murder, rem] = killer(kids.kids, kids.deadKids)
    console.log(murder)
    console.log(rem)
    const now = Date.now()
    data = data.data
    console.log(data)
    if(murder){
        data.lastDeath = now
        data.daysSince = 0
        data.killCount += murder
        data.aliveCount -= murder
    } else {
        data.daysSince = Math.floor((now - data.lastDeath) / hoursToMili(24))
        data.longestSurvived = Math.max(data.daysSince, data.longestSurvived)
    }
    console.log("What is  alive")
    console.log(rem)
    await dataCol.updateOne({name: user.name},{$set: {data: data}})
    await kidCol.updateOne({name: user.name},{$set: {kids: rem, deadKids: kids.deadKids}})
    client.close()
    res.end()
})



router.get("/req_data", async (req, res) => {
    let user = req.cookies.login
    user = JSON.parse(user)
    await client.connect()
    const collection = client.db(databaseName).collection(userData)
    const data = await collection.findOne({name: user.name})
    client.close()
    res.json(data)
})
function hoursToMili(hours) {
    return (hours*60)*60*1000
}

function killer(alive, dead){
    let deaths = 0
    const now = Date.now()
    console.log("IN KILLER")
    const rem = alive.filter(k => {
        if(k.deathDay < now){
            console.log("IN KILLED")
            console.log(k.name)
            deaths++
            dead.push(k.name)
            return false
        }
        return true
    })

    console.log("What should be alive")
    console.log(rem)
    return [deaths, rem]
}

module.exports = router;