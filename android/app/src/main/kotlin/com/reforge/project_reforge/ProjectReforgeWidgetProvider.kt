package com.reforge.project_reforge

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import kotlin.math.roundToInt

/**
 * Project Reforge home screen widget.
 * Renders a live progress ring and gamified stats pushed from Flutter.
 * Subclassed by ReforgeWidgetSmall/Medium/Large so each size can pick its layout.
 */
open class ProjectReforgeWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    widgetData: SharedPreferences,
  ) {
    val raw = widgetData.getString("stateJson", null) ?: "{}"
    val data = try {
      JSONObject(raw)
    } catch (e: Exception) {
      JSONObject()
    }

    for (widgetId in appWidgetIds) {
      val info = appWidgetManager.getAppWidgetInfo(widgetId) ?: continue
      val receiver = info.provider?.className ?: continue
      val layoutRes = when {
        receiver.contains("Small") -> R.layout.widget_small
        receiver.contains("Medium") -> R.layout.widget_medium
        else -> R.layout.widget_large
      }
      val views = RemoteViews(context.packageName, layoutRes)
      bind(context, views, data, layoutRes)
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private fun zoneColor(pct: Double): Int = when {
    pct >= 1.0 -> Color.parseColor("#FFE07A")
    pct >= 0.75 -> Color.parseColor("#2BD67B")
    pct >= 0.5 -> Color.parseColor("#4F8CFF")
    pct >= 0.25 -> Color.parseColor("#FF8A3D")
    else -> Color.parseColor("#FF5B5B")
  }

  private fun ringBitmap(progress: Double, color: Int): Bitmap {
    val size = 240
    val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bmp)
    val stroke = 20f
    val rect = RectF(stroke / 2f, stroke / 2f, size - stroke / 2f, size - stroke / 2f)
    val bgPaint = Paint().apply {
      this.color = 0x26FFFFFF
      style = Paint.Style.STROKE
      strokeWidth = stroke
      strokeCap = Paint.Cap.ROUND
    }
    canvas.drawOval(rect, bgPaint)
    val fgPaint = Paint().apply {
      this.color = color
      style = Paint.Style.STROKE
      strokeWidth = stroke
      strokeCap = Paint.Cap.ROUND
    }
    canvas.drawArc(rect, -90f, (360f * progress).toFloat(), false, fgPaint)
    return bmp
  }

  private fun bind(context: Context, views: RemoteViews, d: JSONObject, layout: Int) {
    fun opt(name: String, def: Double): Double = try { d.optDouble(name, def) } catch (e: Exception) { def }
    fun optI(name: String, def: Int): Int = try { d.optInt(name, def) } catch (e: Exception) { def }
    fun str(name: String, def: String): String = try { d.optString(name, def) } catch (e: Exception) { def }

    val level = optI("level", 1)
    val streak = optI("streak", 0)
    val weight = opt("weight", 110.0)
    val goal = opt("goalWeight", 85.0)
    val completion = opt("completion", 0.0).coerceIn(0.0, 1.0)
    val cal = optI("calories", 0)
    val calGoal = optI("calorieGoal", 2200)
    val protein = optI("protein", 0)
    val proteinGoal = optI("proteinGoal", 176)
    val water = optI("water", 0)
    val waterGoal = optI("waterGoal", 3800)
    val steps = optI("steps", 0)
    val stepsGoal = optI("stepsGoal", 8000)
    val xpPct = opt("xpPct", 0.0).coerceIn(0.0, 1.0)
    val color = zoneColor(completion)

    if (layout == R.layout.widget_small) {
      views.setImageViewBitmap(R.id.ring, ringBitmap(completion, color))
      views.setTextViewText(R.id.tv_streak, "\uD83D\uDD25 $streak")
      views.setTextViewText(R.id.tv_level, "\u2B50 Lv $level")
      views.setTextViewText(R.id.tv_weight, "${weight.roundToInt()} kg")
      views.setTextViewText(R.id.tv_pct, "${(completion * 100).roundToInt()}%")
      views.setTextColor(R.id.tv_pct, color)
      setLaunch(context, views, R.id.small_root, "reforge://action/open", 1)
    } else if (layout == R.layout.widget_medium) {
      views.setImageViewBitmap(R.id.ring_m, ringBitmap(completion, color))
      views.setTextViewText(R.id.tv_level_m, "Lv $level  ·  \uD83D\uDD25 $streak day streak")
      views.setTextViewText(R.id.tv_mission, "Today's completion: ${(completion * 100).roundToInt()}%")
      views.setTextViewText(R.id.tv_cal_rem, "Calories left: ${(calGoal - cal).coerceAtLeast(0)}")
      views.setTextViewText(R.id.tv_protein_rem, "Protein: $protein/${proteinGoal}g")
      views.setTextViewText(R.id.tv_water, "Water: $water / ${waterGoal}ml")
      views.setProgressBar(R.id.xpbar_m, 100, (xpPct * 100).roundToInt(), false)
      views.setTextViewText(R.id.tv_quote, quoteFor(completion, level))
      setLaunch(context, views, R.id.btn_water, "reforge://action/water", 10)
      setLaunch(context, views, R.id.btn_meal, "reforge://action/meal", 11)
      setLaunch(context, views, R.id.btn_workout, "reforge://action/workout", 12)
      setLaunch(context, views, R.id.btn_walk, "reforge://action/walk", 13)
      setLaunch(context, views, R.id.medium_root, "reforge://action/open", 2)
    } else {
      views.setImageViewBitmap(R.id.ring_l, ringBitmap(completion, color))
      views.setTextViewText(R.id.tv_daily_score, "Daily Score  ${(completion * 100).roundToInt()} / 100")
      views.setTextViewText(R.id.tv_weight_l, "⚖️ Current ${weight.roundToInt()}kg  ·  Goal ${goal.roundToInt()}kg")
      views.setTextViewText(R.id.tv_transformation, "${(completion * 100).roundToInt()}% of transformation")
      views.setTextViewText(R.id.tv_calories_l, "🔥 $cal / $calGoal kcal")
      views.setTextViewText(R.id.tv_protein_l, "🍗 $protein / $proteinGoal g")
      views.setTextViewText(R.id.tv_water_l, "💧 $water / $waterGoal ml")
      views.setTextViewText(R.id.tv_steps_l, "🏃 $steps / $stepsGoal steps")
      views.setTextViewText(R.id.tv_workout_l, if (d.optBoolean("workoutDone")) "💪 Workout done" else "💪 Workout pending")
      views.setTextViewText(R.id.tv_sleep_l, "🌙 ${d.optDouble("sleepHours", 0.0)}h sleep")
      views.setTextViewText(R.id.tv_rank_l, "🎖 ${str("rank", "Bronze Novice")}  ·  ${str("title", "The Beginner")}")
      views.setTextViewText(R.id.tv_boss_l, "👹 Boss: ${str("boss", "Sugar Monster")}")
      views.setTextViewText(R.id.tv_xp_l, "Level $level  ·  ${(xpPct * 100).roundToInt()}% to next")
      views.setProgressBar(R.id.xpbar_l, 100, (xpPct * 100).roundToInt(), false)
      views.setProgressBar(R.id.calbar_l, 100, progressPct(cal, calGoal), false)
      views.setProgressBar(R.id.proteinbar_l, 100, progressPct(protein, proteinGoal), false)
      views.setProgressBar(R.id.waterbar_l, 100, progressPct(water, waterGoal), false)
      views.setProgressBar(R.id.stepsbar_l, 100, progressPct(steps, stepsGoal), false)
      views.setTextViewText(R.id.tv_reminder_l, reminderFor(proteinGoal, protein, waterGoal, water, stepsGoal, steps))
      setLaunch(context, views, R.id.btn_quick_log, "reforge://action/meal", 20)
      setLaunch(context, views, R.id.btn_coach, "reforge://action/coach", 21)
      setLaunch(context, views, R.id.large_root, "reforge://action/open", 3)
    }
  }

  private fun progressPct(v: Int, goal: Int): Int {
    if (goal <= 0) return 0
    return ((v.toDouble() / goal.toDouble()) * 100).roundToInt().coerceIn(0, 100)
  }

  private fun quoteFor(completion: Double, level: Int): String = when {
    completion >= 1.0 -> "You beat today! Legend stuff. 👑"
    completion >= 0.75 -> "Only one walk away from leveling up."
    completion >= 0.5 -> "Halfway there — Future You is proud."
    level > 5 -> "Small wins become big transformations."
    else -> "Every meal is a choice. Yours today? Champion."
  }

  private fun reminderFor(pGoal: Int, protein: Int, wGoal: Int, water: Int, sGoal: Int, steps: Int): String = when {
    protein < pGoal -> "🍗 ${pGoal - protein}g protein left for today's mission."
    water < wGoal -> "💧 Drink one more glass to keep your streak alive."
    steps < sGoal -> "🏃 Finish one walk to earn 150 XP."
    else -> "✅ Quests clear. Future You says thanks!"
  }

  private fun setLaunch(context: Context, views: RemoteViews, viewId: Int, action: String, requestCode: Int) {
    try {
      val intent = Intent(context, MainActivity::class.java)
      intent.data = Uri.parse(action)
      intent.action = "es.antonborri.home_widget.action.LAUNCH"
      val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
      val pi = PendingIntent.getActivity(context, requestCode, intent, flags)
      views.setOnClickPendingIntent(viewId, pi)
    } catch (e: Exception) {
      // ignore: widget still renders without interactivity
    }
  }
}
