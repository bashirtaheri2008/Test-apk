package com.hamgab.messenger.profile

import android.app.AlertDialog
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.bumptech.glide.Glide
import com.hamgab.messenger.MainActivity
import com.hamgab.messenger.auth.AuthActivity
import com.hamgab.messenger.data.FirestoreApi
import com.hamgab.messenger.data.Prefs
import com.hamgab.messenger.databinding.ActivityProfileBinding
import com.hamgab.messenger.databinding.DialogEditProfileBinding
import kotlinx.coroutines.launch

class ProfileActivity : AppCompatActivity() {

    private lateinit var binding: ActivityProfileBinding
    private lateinit var prefs: Prefs
    private val api = FirestoreApi()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityProfileBinding.inflate(layoutInflater)
        setContentView(binding.root)
        prefs = Prefs(this)

        loadProfile()

        binding.btnEdit.setOnClickListener { showEditDialog() }

        binding.btnEditAvatar.setOnClickListener {
            Toast.makeText(this, "تغییر آواتار به‌زودی!", Toast.LENGTH_SHORT).show()
        }

        binding.btnLogout.setOnClickListener {
            AlertDialog.Builder(this)
                .setTitle("خروج")
                .setMessage("آیا مطمئن هستید می‌خواهید خارج شوید؟")
                .setPositiveButton("بله") { _, _ ->
                    prefs.logout()
                    startActivity(Intent(this, AuthActivity::class.java))
                    finishAffinity()
                }
                .setNegativeButton("انصراف", null)
                .show()
        }
    }

    private fun loadProfile() {
        binding.profileName.text = prefs.name.ifEmpty { "کاربر هم‌گب" }
        binding.profilePhone.text = prefs.phone
        binding.profileNameField.text = prefs.name.ifEmpty { "نامشخص" }
        binding.profilePhoneField.text = prefs.phone
        binding.profileBioField.text = prefs.bio.ifEmpty { "بیوگرافی هنوز تنظیم نشده" }

        if (prefs.photoURL.isNotEmpty()) {
            Glide.with(this).load(prefs.photoURL).circleCrop().into(binding.profileAvatar)
        }
    }

    private fun showEditDialog() {
        val dialogBinding = DialogEditProfileBinding.inflate(LayoutInflater.from(this))
        dialogBinding.editName.setText(prefs.name)
        dialogBinding.editBio.setText(prefs.bio)

        val dialog = AlertDialog.Builder(this)
            .setView(dialogBinding.root)
            .create()

        dialogBinding.cancelBtn.setOnClickListener { dialog.dismiss() }

        dialogBinding.saveBtn.setOnClickListener {
            val name = dialogBinding.editName.text.toString().trim()
            val bio = dialogBinding.editBio.text.toString().trim()

            if (name.isEmpty()) {
                Toast.makeText(this, "نام نمی‌تواند خالی باشد", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            prefs.name = name
            prefs.bio = bio

            lifecycleScope.launch {
                api.updateUserProfile(prefs.uid, name, bio, prefs.photoURL)
                dialog.dismiss()
                loadProfile()
                Toast.makeText(this@ProfileActivity, "پروفایل به‌روزرسانی شد", Toast.LENGTH_SHORT).show()
            }
        }

        dialog.show()
    }

    override fun onResume() {
        super.onResume()
        loadProfile()
    }
}
