package com.example.terpdash

import android.content.Context
import android.graphics.Color
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Bundle
import android.util.Log
import android.view.GestureDetector
import android.view.MotionEvent
import android.widget.FrameLayout
import android.widget.ProgressBar
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.graphics.drawable.toDrawable
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.google.firebase.database.FirebaseDatabase
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import java.util.Timer
import java.util.TimerTask

class GameActivity : AppCompatActivity(), SensorEventListener {

    private lateinit var sensorManager : SensorManager
    private var sensor: Sensor? = null
    private var scoreSaved = false
    private lateinit var game: TerpDash
    private lateinit var tdView : TerpDashView
    private lateinit var gestureDetector: GestureDetector

    private lateinit var progressBar: ProgressBar

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContentView(R.layout.activity_game)
        val frameLayout = findViewById<FrameLayout>(R.id.gameFrameLayout)
        progressBar = findViewById(R.id.gameProgressBar)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        sensor = sensorManager.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION)
        var width = resources.displayMetrics.widthPixels
        var height = resources.displayMetrics.heightPixels
        game = TerpDash(width, height)
        tdView = TerpDashView(this, game, width, height)
        frameLayout.addView(tdView, 0)
        tdView.onScoreUpdateListener = {currentScore ->
            runOnUiThread {
                progressBar.progress= currentScore% 5
            }
        }


        ViewCompat.setOnApplyWindowInsetsListener(frameLayout) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }
        //tdView.setBackgroundColor(Color.LTGRAY)

        gestureDetector = GestureDetector(this, Gesture())
        val gt = GameLoop()
        Timer().schedule(gt, 1000L, TerpDash.FRAME_RATE)
        game.start()
    }

    private fun saveScoreToLeaderboard(finalScore: Int) {
        val sharedPreferences = getSharedPreferences("TerpDashPrefs", Context.MODE_PRIVATE)
        val username = sharedPreferences.getString("username", "Player") ?: "Player"

        val leaderboardEntry = LeaderboardEntry(username, finalScore)

        FirebaseDatabase.getInstance()
            .getReference("leaderboard")
            .push()
            .setValue(leaderboardEntry)
    }

    override fun onResume() {
        super.onResume()
        sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)
    }

    override fun onPause(){
        super.onPause()
        sensorManager.unregisterListener(this)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        return gestureDetector.onTouchEvent(event) ||super.onTouchEvent(event)
    }

    fun updateFrame() {
        game.update()
        tdView.postInvalidate()

        if (game.amIDead() && !scoreSaved) {
            val newScore = game.getScore()
            if (score < newScore) { score = newScore }
            saveScoreToLeaderboard(newScore)
            scoreSaved =true
        }
    }

    override fun onDestroy() {
        val new= game.getScore()
        if (score < new) {
            score = new
            saveScoreToLeaderboard(new)
        }
        super.onDestroy()
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onSensorChanged(event: SensorEvent?) {
        if(event != null && !game.amIDead() && !game.isPlayerMove()){
            if(event.values[0] > 2){
                game.moveBegin(game.LEFT)
            } else if(event.values[0] < -2){
                game.moveBegin(game.RIGHT)
            }
        }
    }

    private inner class GameLoop : TimerTask(){
        override fun run(){
            updateFrame()
        }
    }
    private inner class Gesture : GestureDetector.SimpleOnGestureListener() {
        override fun onFling(e1: MotionEvent?, e2: MotionEvent, velocityX: Float, velocityY: Float): Boolean {
            if(e1 != null && !game.isPlayerMove() ) {
                game.moveBegin(if (e1.x < e2.x) game.RIGHT else game.LEFT)
            }
            return super.onFling(e1, e2, velocityX, velocityY)
        }

        override fun onSingleTapUp(e: MotionEvent): Boolean {
            if (game.amIDead()) {
                if (tdView.isReplayButtonClicked(e.x, e.y)) {
                    scoreSaved =false
                    game.start()
                    progressBar.progress=0
                    //tdView.postInvalidate()
                } else {
                    finish()
                }
                return true
            }
            return super.onSingleTapUp(e)
        }
    }

    companion object{
        var score = 0
        fun resetScore() { score = 0}
    }
}
