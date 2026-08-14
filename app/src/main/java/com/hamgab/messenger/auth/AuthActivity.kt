package com.hamgab.messenger.auth

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.Editable
import android.text.TextWatcher
import android.view.View
import android.widget.EditText
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.hamgab.messenger.MainActivity
import com.hamgab.messenger.data.FirestoreApi
import com.hamgab.messenger.data.Prefs
import com.hamgab.messenger.databinding.ActivityAuthBinding
import kotlinx.coroutines.launch
import java.util.Random

class AuthActivity : AppCompatActivity() {

    private lateinit var binding: ActivityAuthBinding
    private val api = FirestoreApi()
    private lateinit var prefs: Prefs
    private var currentOTP = ""
    private var currentPhone = ""
    private var resendTimer: Int = 0
    private val handler = Handler(Looper.getMainLooper())
    private val resendRunnable = object : Runnable {
        override fun run() {
            if (resendTimer > 0) {
                resendTimer--
                binding.resendTimer.text = "درخواست مجدد بعد از $resendTimer ثانیه"
                handler.postDelayed(this, 1000)
            } else {
                binding.resendTimer.visibility = View.GONE
                binding.resendBtn.visibility = View.VISIBLE
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAuthBinding.inflate(layoutInflater)
        setContentView(binding.root)
        prefs = Prefs(this)

        // Auto-login if already logged in
        if (prefs.isLoggedIn && prefs.uid.isNotEmpty()) {
            startActivity(Intent(this, MainActivity::class.java))
            finish()
            return
        }

        setupPhoneInput()
        setupOTPInputs()
        setupButtons()
    }

    private fun setupPhoneInput() {
        binding.phoneInput.addTextChangedListener(object : TextWatcher {
            override fun afterTextChanged(s: Editable?) {
                s?.let {
                    val digits = it.toString().replace(Regex("\\D"), "")
                    if (digits != it.toString()) {
                        binding.phoneInput.setText(digits)
                        binding.phoneInput.setSelection(digits.length)
                    }
                    binding.sendOtpBtn.isEnabled = digits.length == 9
                }
            }
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
        })
    }

    private fun setupOTPInputs() {
        val boxes = arrayOf(binding.otp1, binding.otp2, binding.otp3, binding.otp4, binding.otp5, binding.otp6)
        for (i in boxes.indices) {
            boxes[i].addTextChangedListener(object : TextWatcher {
                override fun afterTextChanged(s: Editable?) {
                    val text = s?.toString() ?: ""
                    if (text.isNotEmpty()) {
                        if (i < 5) boxes[i + 1].requestFocus()
                        else verifyOTP()
                    }
                }
                override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
                override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            })

            boxes[i].setOnKeyListener { _, keyCode, event ->
                if (keyCode == android.view.KeyEvent.KEYCODE_DEL && boxes[i].text.isEmpty() && i > 0) {
                    boxes[i - 1].requestFocus()
                    boxes[i - 1].setText("")
                    true
                } else false
            }
        }
    }

    private fun setupButtons() {
        binding.sendOtpBtn.setOnClickListener {
            val phone = binding.phoneInput.text.toString().trim()
            if (phone.length != 9) {
                showError(binding.phoneError, "⚠️ شماره معتبر نیست — ۹ رقم بدون صفر وارد کنید")
                return@setOnClickListener
            }
            currentPhone = "+93$phone"
            generateOTP()
            showOTPStep()
        }

        binding.resendBtn.setOnClickListener {
            generateOTP()
            startResendTimer()
            clearOTPBoxes()
        }

        binding.verifyBtn.setOnClickListener {
            verifyOTP()
        }
    }

    private fun generateOTP() {
        // SIMULATE OTP — server is offline, generate locally
        val random = Random()
        currentOTP = String.format("%06d", random.nextInt(1000000))
    }

    private fun showOTPStep() {
        binding.phoneStep.visibility = View.GONE
        binding.otpStep.visibility = View.VISIBLE

        // Display phone number
        val displayPhone = "0${currentPhone.substring(3)}"
        binding.otpPhoneDisplay.text = displayPhone

        // Show OTP code for testing (since OTP server is offline)
        binding.otpTestDisplay.visibility = View.VISIBLE
        binding.otpTestDisplay.text = "🔑 کد تست: $currentOTP"

        clearOTPBoxes()
        startResendTimer()
        binding.otp1.requestFocus()
    }

    private fun startResendTimer() {
        resendTimer = 90
        binding.resendTimer.visibility = View.VISIBLE
        binding.resendBtn.visibility = View.GONE
        binding.resendTimer.text = "درخواست مجدد بعد از $resendTimer ثانیه"
        handler.removeCallbacks(resendRunnable)
        handler.postDelayed(resendRunnable, 1000)
    }

    private fun clearOTPBoxes() {
        binding.otp1.setText("")
        binding.otp2.setText("")
        binding.otp3.setText("")
        binding.otp4.setText("")
        binding.otp5.setText("")
        binding.otp6.setText("")
        binding.otpError.visibility = View.GONE
        binding.otpSuccess.visibility = View.GONE
    }

    private fun verifyOTP() {
        val code = "${binding.otp1.text}${binding.otp2.text}${binding.otp3.text}${binding.otp4.text}${binding.otp5.text}${binding.otp6.text}"
        if (code.length < 6) {
            showOTPError("⚠️ لطفاً کد ۶ رقمی را کامل وارد کنید")
            return
        }

        if (code == currentOTP) {
            // OTP verified — login
            binding.otpError.visibility = View.GONE
            binding.otpSuccess.visibility = View.VISIBLE
            binding.otpSuccess.text = "✓ تأیید شد! در حال ورود..."
            handler.removeCallbacks(resendRunnable)

            loginWithPhone(currentPhone)
        } else {
            showOTPError("❌ کد وارد شده اشتباه است")
        }
    }

    private fun loginWithPhone(phone: String) {
        val uid = phone.replace(Regex("[^0-9]"), "")
        lifecycleScope.launch {
            try {
                // Check if user exists
                var user = api.getUser(uid)
                if (user == null || user.uid.isEmpty()) {
                    // Create new user
                    api.createOrUpdateUser(uid, phone, "کاربر هم‌گب", "", "")
                    user = api.getUser(uid)
                }

                // Save to prefs
                prefs.uid = uid
                prefs.phone = phone
                prefs.isLoggedIn = true
                prefs.name = user?.name ?: "کاربر هم‌گب"
                prefs.bio = user?.bio ?: ""
                prefs.photoURL = user?.photoURL ?: ""

                // Go to main
                startActivity(Intent(this@AuthActivity, MainActivity::class.java))
                finish()
            } catch (e: Exception) {
                showOTPError("❌ خطا در ورود. دوباره تلاش کنید.")
            }
        }
    }

    private fun showError(view: TextView, msg: String) {
        view.text = msg
        view.visibility = View.VISIBLE
    }

    private fun showOTPError(msg: String) {
        binding.otpError.text = msg
        binding.otpError.visibility = View.VISIBLE
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(resendRunnable)
    }
}
