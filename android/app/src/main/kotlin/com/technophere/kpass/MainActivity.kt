package com.technophere.kpass

import android.os.Build
import android.os.Bundle
import android.webkit.CookieManager
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val channelName = "com.technophere.kpass/cookies"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
      when (call.method) {
        "getCookiesForUrl" -> {
          val url = call.argument<String>("url")
          if (url.isNullOrEmpty()) {
            result.error("ARG_ERROR", "url is required", null)
            return@setMethodCallHandler
          }
          try {
            val cookieManager = CookieManager.getInstance()
            // Ensure cookies are accepted
            cookieManager.setAcceptCookie(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
              // best-effort; may not be necessary for our use
            }
            // Try multiple URL variants to collect all cookies
            val urls = listOf(
              url,
              "https://lms.keio.jp/",
              "https://lms.keio.jp",
              "http://lms.keio.jp/",
              "http://lms.keio.jp"
            )
            val parts = mutableListOf<String>()
            for (u in urls) {
              val c = cookieManager.getCookie(u)
              if (!c.isNullOrEmpty()) parts.add(c)
            }
            // Merge and de-duplicate by key
            val map = linkedMapOf<String, String>()
            parts.joinToString("; ").split(";").forEach { pair ->
              val idx = pair.indexOf('=')
              if (idx > 0) {
                val k = pair.substring(0, idx).trim()
                val v = pair.substring(idx + 1).trim()
                if (k.isNotEmpty()) map[k] = v
              }
            }
            val merged = map.entries.joinToString("; ") { "${it.key}=${it.value}" }
            result.success(merged)
          } catch (e: Exception) {
            result.error("COOKIE_ERROR", e.message, null)
          }
        }
        else -> result.notImplemented()
        "httpGet" -> {
          val urlStr = call.argument<String>("url")
          if (urlStr.isNullOrEmpty()) {
            result.error("ARG_ERROR", "url is required", null)
            return@setMethodCallHandler
          }
          try {
            val urlObj = URL(urlStr)
            val conn = (urlObj.openConnection() as HttpURLConnection).apply {
              requestMethod = "GET"
              setRequestProperty("Accept", "application/json")
              // Attach cookies from CookieManager for this URL
              val cm = CookieManager.getInstance()
              val cookie = cm.getCookie(urlStr) ?: cm.getCookie(urlObj.protocol + "://" + urlObj.host)
              if (cookie != null) setRequestProperty("Cookie", cookie)
            }
            val status = conn.responseCode
            val reader = BufferedReader(InputStreamReader(if (status >= 400) conn.errorStream else conn.inputStream))
            val body = reader.readText()
            reader.close()
            result.success(mapOf("status" to status, "body" to body))
          } catch (e: Exception) {
            result.error("HTTP_ERROR", e.message, null)
          }
        }
      }
    }
  }
}

