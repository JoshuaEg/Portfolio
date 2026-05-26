package com.example.terpdash

import android.graphics.Point
import android.util.Log
import java.util.Timer
import java.util.TimerTask
import kotlin.math.pow

class TerpDash {
    class Circle{
        private var center : Point
        private var radius = 0
        constructor(center : Point, radius : Int) {
            this.center = center
            this.radius = radius
        }

        fun intersect(circle : Circle) : Boolean{
            val distx = (this.center.x - circle.center.x).toDouble().pow(2.toDouble())
            val disty = (this.center.y - circle.center.y).toDouble().pow(2.toDouble())
            return (distx + disty) < (this.radius + circle.radius).toDouble().pow(2)
        }

        fun getCenter(): Point {
            return center
        }
        fun getRadius() : Int {
            return radius
        }
    }

    class EnemyLine{
        private var enemies : Array<Circle?>
        var startCenter = 0
        constructor(screenWidth : Int, screenHieght : Int){
            val laneWidth = screenWidth/3
            val radius = (laneWidth*7)/16
            val center = (screenWidth/2) - laneWidth
            var counter = 0
            startCenter = -radius
            enemies = Array(3, {i ->
                val create = (0..1).random()
                if(create == 1 && counter != 2) {
                    counter++
                    val p = Point(center + (i * laneWidth), startCenter)
                    return@Array Circle(p, radius)
                }
                null
            })
        }

        fun ifIntersects(player : Circle) : Boolean{
            for(e in enemies){
                if(e == null) continue
                if(e.intersect(player)) return true
            }
            return false
        }
        fun getEnemies(): Array<Circle?> {
            return enemies
        }
    }

    val LEFT = 0
    val RIGHT = 1
    private lateinit var player : Circle
    private lateinit var newEnemieSchedual : Timer
    private lateinit var scoreCounter : Timer

    private var isDead = false
    private var score = 0
    private var speed = 1.5f
    private var playerSpeed = 2f
    private var isPlayerMoving = false
    private var playerDest = 0
    private var playerDir = false
    private var screenWidth = 0
    private var screenHeight = 0
    private var enemyRows : ArrayList<EnemyLine> = ArrayList()
    private var laneWidth = 0
    private var interval = 1000L
    private var lastMilestone = 0
    private var currentEnemyTask: TimerTask? = null
    val listLock = Any()

    constructor(width: Int, height: Int){
        screenWidth = width
        screenHeight = height
        laneWidth = width/3
        newEnemieSchedual = Timer()
        scoreCounter = Timer()
        var p = Point(screenWidth/2, (screenHeight*4)/5)
        player = Circle(p,laneWidth/8)
    }

    fun getScore() : Int { return score }

    fun start(){
        resetGame()
        scoreCounter = Timer()
        newEnemieSchedual = Timer()
        scoreCounter.schedule(Counter(), 0, 1000)
        changeSchedule()
    }

    fun update(){
        if(!isDead){
            if(isPlayerMoving) movePlayer()
            moveEnemies()
            checkProgressBar()
        }
    }

    private fun changeSchedule(){
        currentEnemyTask?.cancel()
        currentEnemyTask = EnemyIntro()
        newEnemieSchedual.schedule(currentEnemyTask, 1000L ,interval)
    }

    fun resetGame(){
        isPlayerMoving = false
        interval = 1000L
        score = 0
        speed = 1.5f
        lastMilestone = 0
        enemyRows.clear()
        player.getCenter().x = screenWidth/2
        isDead = false
    }

    fun kill(){
        isDead = true
        newEnemieSchedual.cancel()
        scoreCounter.cancel()
    }

    fun checkProgressBar(){
        if (score > 0 && score % 5 == 0 && score != lastMilestone) {
            lastMilestone = score
            if (score % 10 == 0) {
                speed += 0.5f
            } else {
                interval = interval * 9 / 10
                changeSchedule()
            }
        }
    }

    fun moveEnemies(){
        synchronized(listLock) {
            for (line in enemyRows) {
                for (circle in line.getEnemies()) {
                    if (circle == null) continue
                    val center = circle.getCenter()
                    center.y += (FRAME_RATE * speed).toInt()
                    if (circle.intersect(player)) kill()
                }
                line.startCenter += (FRAME_RATE * speed).toInt()
            }
        }
    }

    fun movePlayer(){
        val move = (playerSpeed * FRAME_RATE).toInt()
        if(playerDir){
            player.getCenter().x += move
            playerDest -= move
            if(playerDest <= 0) {
                player.getCenter().x += playerDest
                playerDest = 0
                isPlayerMoving = false
            } else if (player.getCenter().x >= screenWidth) player.getCenter().x -= screenWidth
        }else{
            player.getCenter().x -= move
            playerDest += move
            if(playerDest >= 0) {
                player.getCenter().x += playerDest
                playerDest = 0
                isPlayerMoving = false
            } else if (player.getCenter().x <= 0) player.getCenter().x += screenWidth
        }
    }

    fun amIDead() : Boolean { return isDead }

    fun moveBegin(direction : Int){
        playerDest = if (direction == RIGHT) laneWidth else -laneWidth
        playerDir = (direction == RIGHT)
        isPlayerMoving = true
    }

    fun isPlayerMove() : Boolean { return isPlayerMoving }

    private inner class EnemyIntro : TimerTask() {
        override fun run() {
            synchronized(listLock) {
                enemyRows.add(EnemyLine(screenWidth, screenHeight))
            }
        }
    }

    private inner class Counter : TimerTask() {
        override fun run() { score++ }
    }

    companion object{ const val FRAME_RATE = 16L }

    fun getPlayer(): Circle { return player }
    fun getEnemyRows(): ArrayList<EnemyLine> { return enemyRows }
    fun getRowsOfEnemies() : ArrayList<EnemyLine> { return enemyRows }
}
