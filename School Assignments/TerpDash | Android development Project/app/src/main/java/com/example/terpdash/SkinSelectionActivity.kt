package com.example.terpdash

import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.BaseAdapter
import android.widget.Button
import android.widget.ImageView
import android.widget.ListView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.graphics.toColorInt
import androidx.core.content.edit

class SkinSelectionActivity : AppCompatActivity() {

    private lateinit var prefs: SharedPreferences
    private lateinit var circlePreview: ImageView
    private lateinit var listView: ListView
    private var selectedColor: Int = Color.RED
    private var selectedIndex: Int = 0

    data class SkinOption(val name: String, val color: Int)

    private val skinOptions = listOf(
        SkinOption("Red", Color.RED),
        SkinOption("Blue", Color.BLUE),
        SkinOption("Green", Color.GREEN),
        SkinOption("Yellow", Color.YELLOW),
        SkinOption("Magenta", Color.MAGENTA),
        SkinOption("Cyan", Color.CYAN),
        SkinOption("Orange", "#FF6600".toColorInt()),
        SkinOption("Purple", Color.parseColor("#800080"))
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_skin_selection)

        prefs = getSharedPreferences("TerpDashPrefs", MODE_PRIVATE)
        circlePreview = findViewById(R.id.skinCirclePreview)
        listView = findViewById(R.id.skinListView)

        selectedColor = prefs.getInt("skin_color", Color.RED)
        selectedIndex = skinOptions.indexOfFirst { it.color == selectedColor }
        if (selectedIndex < 0) selectedIndex = 0
        updatePreview()

        val adapter = SkinAdapter()
        listView.adapter = adapter


        listView.setOnItemClickListener { _, _, position, _ ->
            selectedIndex = position
            selectedColor = skinOptions[position].color
            updatePreview()
            adapter.notifyDataSetChanged()
        }

        findViewById<Button>(R.id.btnSaveSkin).setOnClickListener {
            prefs.edit { putInt("skin_color", selectedColor) }
            Toast.makeText(this, "Skin saved!", Toast.LENGTH_SHORT).show()
            finish()
        }

        findViewById<Button>(R.id.btnBack).setOnClickListener {
            finish()
        }
    }

    private fun updatePreview() {
        val circle = GradientDrawable()

        circle.shape = GradientDrawable.OVAL
        circle.setColor(selectedColor)
        circlePreview.setImageDrawable(circle)
    }

    inner class SkinAdapter : BaseAdapter() {
        override fun getCount(): Int = skinOptions.size
        override fun getItem(position: Int): SkinOption = skinOptions[position]
        override fun getItemId(position: Int): Long = position.toLong()

        override fun getView(position: Int, convertView: View?, parent: ViewGroup?): View {
            val view = convertView ?: LayoutInflater.from(this@SkinSelectionActivity)
                .inflate(R.layout.item_skin, parent, false)

            val skin = skinOptions[position]

            val colorCircle = view.findViewById<ImageView>(R.id.itemColorCircle)
            val colorName = view.findViewById<TextView>(R.id.itemColorName)

            val circle = GradientDrawable()
            circle.shape = GradientDrawable.OVAL
            circle.setColor(skin.color)
            colorCircle.setImageDrawable(circle)

            colorName.text = skin.name

            if (position == selectedIndex) {
                view.setBackgroundColor("#2A2A4A".toColorInt())
            } else {
                view.setBackgroundColor(Color.TRANSPARENT)
            }

            return view
        }
    }
}