package com.example.terpdash

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.view.View

class TerpDashView(context: Context, private val game: TerpDash, private val screenWidth: Int, private val screenHeight: Int) : View(context) {

    var onScoreUpdateListener: ((Int) -> Unit)? = null

    private val lanePaint = Paint().apply {
        color = Color.WHITE
        strokeWidth = 10f
        style = Paint.Style.STROKE
    }

    private val textPaint = Paint().apply {
        color = Color.BLACK
        textSize = 120f
        textAlign = Paint.Align.CENTER
        isFakeBoldText = true
    }

    private val laneWidth = screenWidth / 3
   // private val enemyBitmap: Bitmap = BitmapFactory.decodeResource(resources, R.drawable.enemy_cone)

    private val replayRect = RectF()


    private val prefs = context.getSharedPreferences("TerpDashPrefs", Context.MODE_PRIVATE)
    private val skinColor = prefs.getInt("skin_color", Color.GREEN)

    private val enemyPaint = Paint().apply {
        color = Color.RED
        style = Paint.Style.FILL
        isAntiAlias = true
    }
    private val playerPaint = Paint().apply {
        color = skinColor
        style = Paint.Style.FILL
        isAntiAlias = true
    }
    private val buttonPaint = Paint().apply { color = Color.BLUE }
    val buttonTextPaint = Paint().apply {
        color = Color.WHITE
        textSize = 80f
        textAlign = Paint.Align.CENTER
        isFakeBoldText = true
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)


        //canvas.drawColor(Color.DKGRAY)

        canvas.drawLine(laneWidth.toFloat(), 0f, laneWidth.toFloat(), screenHeight.toFloat(), lanePaint)
        canvas.drawLine((laneWidth * 2).toFloat(), 0f, (laneWidth * 2).toFloat(), screenHeight.toFloat(), lanePaint)

        onScoreUpdateListener?.invoke(game.getScore())

        synchronized(game.listLock) {
            for (line in game.getEnemyRows()) {
                for (enemy in line.getEnemies()) {
                    if (enemy != null) {
                        val cx = enemy.getCenter().x.toFloat()
                        val cy = enemy.getCenter().y.toFloat()
                        val r = enemy.getRadius().toFloat()

                        //val destRect = RectF(cx - r, cy - r, cx + r, cy + r
                        //canvas.drawBitmap(enemyBitmap, null, destRect, null)
                        canvas.drawCircle(cx, cy, r, enemyPaint)
                    }
                }
            }
        }
        val player = game.getPlayer()
        val px = player.getCenter().x.toFloat()
        val py = player.getCenter().y.toFloat()
        val pr = player.getRadius().toFloat()

        canvas.drawCircle(px, py, pr, playerPaint)
        canvas.drawText(game.getScore().toString(), screenWidth / 2f, 350f, textPaint)

        if (game.amIDead()) {
            textPaint.color = Color.RED

            canvas.drawText("GAME OVER", screenWidth / 2f, screenHeight / 2f - 100f, textPaint)
            textPaint.color = Color.BLACK

            replayRect.set(
                screenWidth / 4f,
                screenHeight / 2f + 50f,
                (screenWidth * 3) / 4f,
                screenHeight / 2f + 250f
            )

            canvas.drawRoundRect(replayRect, 40f, 40f, buttonPaint)
            canvas.drawText("REPLAY", screenWidth / 2f, screenHeight / 2f + 180f, buttonTextPaint)

        }
    }

    fun isReplayButtonClicked(x: Float, y: Float): Boolean {
        return game.amIDead() && replayRect.contains(x, y)
    }
}