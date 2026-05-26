"use strict";
const url2 =  "/game/"

let index = 0
const isSlop = [
    "I want the participants of this study to learn about the vast knowledge their world has to offer",
    "I've done some research, and it seems that manny of the population struggle with math",
    "I want to show humans an example of their repositories of free information",
    "Then I came across IsevenAPI, which provides the Is Even metric you see below your pets age",
    "Now you can learn what exactly makes a number even or odd, as an incentive to keep your pets alive",
    "However, the API comes with ads with its free version, and I dont have much earth money to my name",
    "So this is why there are ads on your screen right now",
    "Dont worry though, they're completely from the API, and do not use you personal information (if you care)",
    "I personally wouldn't mind, they are giving you very valuable information for free."
]

window.onload = judge()
function trigger(){
    const disp = document.getElementById("disp")
    disp.classList.toggle("trigger")
}


function advance(){
    index++
    if(index === isSlop.length){
        const disp = document.getElementById("window")
        disp.classList.toggle("slide")
        return
    }
    document.getElementById("explain").innerHTML = isSlop[index]
}

async function makeKid(){
    const name = document.getElementById("childbirth").value
    const res = await fetch(url2 + "new", {
        method: "POST",
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({name:name})
    }) 
    if(!res.ok){
        document.getElementById("err").innerHTML = "kid exists- wait i didnt implement this?!"
        return
    }

    await dispKid(await res.json())
    updateInfo()
}
function logout(){
    fetch(url2 + "logout")
}

async function dispKid(kid = null, four60ed = false){
    let name;
    let daysLasted;
    if(!kid){
        const kidname = document.querySelector("#childname").value
        const res = await fetch(url2 + `dispKid?name=${kidname}`)
        if(!res.ok){
            const j = await res.json()
            document.getElementById("err").innerHTML = j.err
            return
        } 
        kid = await res.json()
    }
    if(!four60ed) document.getElementById("err").innerHTML = ""
    name = kid.name
    daysLasted = kid.daysLasted
    
    document.querySelector("#childDisp").innerHTML = name
    document.querySelector("#lasted").innerHTML = daysLasted
    const even = document.querySelector(".isEven")
    let iseven = await fetch(`https://api.isevenapi.xyz/api/iseven/${daysLasted}`)
    iseven = await iseven.json()
    even.innerHTML= iseven.iseven
    document.getElementById("ad").innerHTML = iseven.ad
    if(!document.getElementById("disp").classList.contains("trigger"))trigger()
}

async function feedKid(){
    const name = document.getElementById("childname").value
    const res = await fetch(url2 + "feedKid", {
        method: "POST",
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({name:name})
    }) 
    if(!res.ok){
        let err = await res.json()
        document.getElementById("err").innerHTML = err
        if(res.status === 460) await dispKid(null, true)
        updateInfo()
        return
    }
    dispKid(await res.json())
    
}

async function updateInfo() {
    const res = await fetch(url2 + "req_data")
    let data = await res.json()
    document.querySelector(".username").innerHTML = data.name
    data = data.data
    document.getElementById("since").innerHTML = "" + data.daysSince
    document.getElementById("alive").innerHTML = "" + data.aliveCount
    document.getElementById("total").innerHTML = "" + (data.aliveCount + data.killCount)
    judge()
}   

function judge(){
    const alive = Number.parseInt(document.getElementById("alive").innerHTML)
    const population = Number.parseInt(document.getElementById("total").innerHTML)
    let verdict
    let b = true
    if (population === 0){
        verdict = "0 out of 0, Wow, How impressive."
        document.getElementById("judgement").innerHTML = verdict
        return
    }
    let ratio = alive / population
    switch (true){
        case ratio === 0:
            verdict = "As expected"
            break
        case ratio === 1 && population < 4:
            verdict = "You have succeeded in doing the bare minimum"
            break
        case ratio < .8 && population < 5:
            verdict = "You might not be very cut out for this"
            break
        case ratio > .95:
            verdict = "decent"
            break
        case ratio > .80:
            verdict = "Alright for a human, I suppose"
            break
        case ratio > .70:
            verdict = "Nothing that would impress anyone"
            break
        case ratio > .50:
            verdict = "Even in your world this is a failing grade"
        case ratio > .45:
            verdict = "Perhaps you are not interested in showing the value in the human race"
            break
        case ratio > .30:
            verdict = "Was all who died worth it for the preservation of the few you actually love?"
            break
        case ratio > 0:
            verdict = "You might not be very cut out for this"
            break
    }

    document.getElementById("judgement").innerHTML = verdict
    return
}

function slide(){
    const disp = document.getElementById("window")
    disp.classList.toggle("slide")
    index = 0
    document.getElementById("explain").innerHTML = isSlop[index]

}
