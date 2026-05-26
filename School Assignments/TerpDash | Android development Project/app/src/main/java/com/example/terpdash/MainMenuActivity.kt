package com.example.terpdash

import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdView
import com.google.android.gms.ads.MobileAds
import android.widget.EditText
import androidx.core.content.edit

class MainMenuActivity : AppCompatActivity() {

    private lateinit var prefs: SharedPreferences
    private lateinit var circlePreview: ImageView
    private lateinit var adView: AdView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main_menu)

        prefs = getSharedPreferences("TerpDashPrefs", MODE_PRIVATE)
        circlePreview = findViewById(R.id.circlePreview)
        val usernameEditText = findViewById<EditText>(R.id.usernameEditText)
        usernameEditText.setText(prefs.getString("username", ""))


        MobileAds.initialize(this) {}

        adView = findViewById(R.id.adBanner)
        val adRequest = AdRequest.Builder().build()
        adView.loadAd(adRequest)

        findViewById<Button>(R.id.btnPlay).setOnClickListener {
            val username = usernameEditText.text.toString().trim()
            if(prefs.getString("username", "") != username){
                GameActivity.resetScore()
            }
            prefs.edit {
                putString("username", if (username.isNotEmpty()) username else "Player")
            }

            val intent = Intent(this, GameActivity::class.java)
            startActivity(intent)
        }

        findViewById<Button>(R.id.btnLeaderboard).setOnClickListener {
            val intent = Intent(this, LeaderboardActivity::class.java)
            startActivity(intent)
        }

        findViewById<Button>(R.id.btnSkins).setOnClickListener {
            val intent = Intent(this, SkinSelectionActivity::class.java)
            startActivity(intent)
        }

        updateCirclePreview()
    }

    override fun onResume() {
        super.onResume()
        updateCirclePreview()
    }

    private fun updateCirclePreview() {
        val savedColor = prefs.getInt("skin_color", Color.RED)
        val circle = GradientDrawable()
        circle.shape = GradientDrawable.OVAL
        circle.setColor(savedColor)
        circlePreview.setImageDrawable(circle)
    }
}