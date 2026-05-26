"use strict";

const bcrypt = require('bcrypt');
const fs = require('fs');
const express = require("express");
const ejs = require("ejs");
const bp = require("body-parser");
const cookieParser = require("cookie-parser");
const path = require("path");
const cheerio = require("cheerio");
const game = require("./game/game");

const exp = express();
exp.use(cookieParser());


exp.use("/game", game);

const p = path.join(__dirname, "/..")
exp.use(express.static(p))

exp.engine('shtml', require('ejs').renderFile);
require("dotenv").config({
    path: path.resolve(__dirname, "envFol/.env"),
 });

exp.set("view engine", "shtml");
exp.set("views", path.resolve(__dirname, "/.."))
const { MongoClient, ServerApiVersion } = require("mongodb");
const { time } = require('console');
const portNumber = 7510;

const passData = "UserPasswords"
const userData = "UserData"
const userKids = "UserChildren"

exp.use(bp.urlencoded({extended:false}));
exp.use(bp.json());
//exp.use( express.json())

const hash = (pass) => {
    return bcrypt.hashSync(pass, bcrypt.genSaltSync(4))
}
const confirmHash = bcrypt.compareSync

require("dotenv").config({
    path: path.resolve(__dirname, "envFol/.env"),
 });

const databaseName = "StudyData";
//const collectionName = "collection";
const uri = process.env.MONGO_CONNECTION_STRING;
const client = new MongoClient(uri, { serverApi: ServerApiVersion.v1 });

let defaulDat = () => {
    let dat = {
        longestSurvived: 0,
        daysSince: 0,
        killCount: 0,
        aliveCount: 0,
        lastDeath: Date.now(),
        isEven: false
    } //todo
    return dat
}

 exp.get("/", (req, res) => {
    fs.readFile("Index.shtml", (_, dat) => {
        res.end(dat)
    })
 })

 exp.get("/login", (req, res) => {
    res.redirect("/")
 })

 exp.post("/login", async (req, res) => {
    const newUser = req.body.name
    console.log("posted")
    console.log(newUser)
    await client.connect()
    console.log("toasted")
    const collection = client.db(databaseName).collection(passData)
    const users = await collection.findOne({name: newUser})
    if(!users){
        fs.readFile("Index.shtml", (_, dat) => {
            const $ = cheerio.load(dat)
            $("#error_message").text("User does not exist")
            res.end($.html())
            client.close();
        })
        return
    }
    const confirm = confirmHash(req.body.pass, users.password)
    
    if(confirm){
        res.cookie("login",JSON.stringify(users), {httpOnly: true})
        res.redirect("/game")
        client.close();
        return
    }
    fs.readFile("Index.shtml", (_, dat) => {
        const $ = cheerio.load(dat)
        $("#error_message").text("Password Failed")
        res.end($.html())
    })
    client.close();
 })

 exp.post("/checkAvail", async (req, res) => {
    const newUser = req.body.name
    const collectionName = "UserPasswords"
    await client.connect()
    const collection = client.db(databaseName).collection(collectionName)
    const users = await collection.findOne({name: newUser})
    let bool = !!users
    console.log(bool)
    res.json({exists: bool})
    client.close();
 })

 exp.post("/create", async (req, res) => {
    const newUser = req.body.name
    await client.connect()
    const passwords = client.db(databaseName).collection(passData)
    const userDat = client.db(databaseName).collection(userData)
    const child = client.db(databaseName).collection(userKids)
    const pass = {
                    name: newUser,
                    password: hash(req.body.pass)
                }
    const data = {
                    name: newUser,
                    data: defaulDat()
                }
    const kids = {
                    name: newUser,
                    kids: [],
                    deadKids: []
                }
    await passwords.insertOne(pass)
    await userDat.insertOne(data)
    await child.insertOne(kids)

    client.close();
    //res.end();d
    res.cookie("login",JSON.stringify(pass), {httpOnly: true})
    res.redirect("/game");
 })



 exp.listen(portNumber);
 console.log(`main URL http://localhost:${portNumber}/`);

