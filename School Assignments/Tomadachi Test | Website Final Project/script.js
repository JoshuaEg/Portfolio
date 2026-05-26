"use strict";

const url =  "/"

const begin =
["Humanity is an utter joke of an intelligent species.", 
    "I've never heard of any living race that regresses with technical improvement.",
    "Your people have progressed to the point where anything concievable can be sent across\
    the world in miliseconds all represented in a simple binary language",
    "However, your world has taken the knowledge for granted, and the populace grows in fixation\
        of fleeting stimulation",
    "But my peers, with their vast innumerable knowledge that no one like you could ever understand,",
        "say \"Dont understimate the undominable human spirit\" with little regard for all of my \
        inquries.",
    "So I have no choice but to conduct my own investigation to show them its all a farce.",
    "If you wish to prove me wrong, all you must do is construct a profile, create and name a \"child\",\
    and feed them everyday.", "That is all.",
    "If you truly care about proving me wrong, all you must do is are these simple tasks",
    "...", "Which you won't", ""];

let credentials;
let index = 0;
let but = document.getElementById("wth");
let info;
function explain() {
   
    but.innerHTML = "uhm ok"
    let exp = document.getElementById("exp")
    
    exp.innerHTML = "<p>" + begin[index++] + "</p>";
    if(index == 1)exp.scrollIntoView({
        block: "center"
    })
    if (index == begin.length){
        index = 0;
        but.innerHTML = "wth is this"
    }
   


}
let made = 0
function preventReplay(){
    if(made != 0) return false
    return made++ === 0
}


function valid(){
    let user = document.getElementById("rname").value
    let pass = document.getElementById("password").value
    let fail = document.getElementById("failure")
    info = {
        name: user,
        password: pass
    }

    if(user === "" || pass === ""){
        fail.innerHTML = "an element is empty<br>idk what you thought would happen"
        return false
    }

    (async () => { 
        let res = await fetch(url + "checkAvail", {
            method: "POST",
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({name: user})
        })
        let {exists} = await res.json()
        if(exists) {
            fail.innerHTML = "Unfortunatly, someone already has this name\n or smth went wrong idk"
            return false
        }
        
        fail.innerHTML = "<button type= 'submit' class='Impose'> IMPOSE RESPONSIBILITIES </button>"

    })()
    return false;
}