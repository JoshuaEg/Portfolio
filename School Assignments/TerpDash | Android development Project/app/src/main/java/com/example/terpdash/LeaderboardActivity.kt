package com.example.terpdash

import android.os.Bundle
import android.widget.TextView
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.google.firebase.database.*
import android.widget.Button

class LeaderboardActivity : AppCompatActivity() {

    private lateinit var leaderboardTextView: TextView
    private lateinit var leaderboardDatabase: DatabaseReference

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_leaderboard)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        leaderboardTextView = findViewById(R.id.leaderboardTextView)
        leaderboardDatabase = FirebaseDatabase.getInstance().getReference("leaderboard")

        loadLeaderboardData()
        findViewById<Button>(R.id.btnBackLeaderboard).setOnClickListener {
            finish()
        }
    }

    private fun loadLeaderboardData() {
        leaderboardDatabase
            .orderByChild("score")
            .limitToLast(10)
            .addValueEventListener(object : ValueEventListener {
                override fun onDataChange(snapshot: DataSnapshot) {
                    val leaderboardEntries = mutableListOf<LeaderboardEntry>()

                    for (entrySnapshot in snapshot.children) {
                        val entry = entrySnapshot.getValue(LeaderboardEntry::class.java)
                        if (entry != null) {
                            leaderboardEntries.add(entry)
                        }
                    }

                    leaderboardEntries.sortByDescending { it.score }

                    val leaderboardText = StringBuilder()

                    for ((index, entry) in leaderboardEntries.withIndex()) {
                        leaderboardText.append("${index + 1}. ${entry.username}: ${entry.score}\n")
                    }

                    leaderboardTextView.text =
                        if (leaderboardText.isNotEmpty()) leaderboardText.toString()
                        else "No scores yet."
                }

                override fun onCancelled(error: DatabaseError) {
                    leaderboardTextView.text = "Could not load leaderboard: ${error.message}"
                }
            })
    }

}