package com.hamgab.messenger.profile

import android.app.AlertDialog
import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.bumptech.glide.Glide
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

        binding.toolbar.setNavigationOnClickListener { finish() }

        loadProfile()

        binding.editBtn.setOnClickListener { showEditDialog() }

        binding.logoutBtn.setOnClickListener {
            prefs.logout()
            val intent = Intent(this, AuthActivity::class.java)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            startActivity(intent)
            finish()
        }
    }

    private fun loadProfile() {
        binding.displayName.text = prefs.name.ifEmpty { "کاربر هم‌گب" }
        binding.displayPhone.text = prefs.phone
        binding.displayBio.text = prefs.bio

        if (prefs.photoURL.isNotEmpty()) {
            Glide.with(this).load(prefs.photoURL).circleCrop().into(binding.avatar)
        }
    }

    private fun showEditDialog() {
        val dialogBinding = DialogEditProfileBinding.inflate(layoutInflater)
        dialogBinding.editName.setText(prefs.name)
        dialogBinding.editBio.setText(prefs.bio)

        val dialog = AlertDialog.Builder(this)
            .setView(dialogBinding.root)
            .create()

        dialogBinding.saveBtn.setOnClickListener {
            val name = dialogBinding.editName.text.toString().trim()
            val bio = dialogBinding.editBio.text.toString().trim()

            if (name.isEmpty()) {
                dialogBinding.editName.error = "نام را وارد کنید"
                return@setOnClickListener
            }

            lifecycleScope.launch {
                api.updateUserProfile(prefs.uid, name, bio, prefs.photoURL)
                prefs.name = name
                prefs.bio = bio
                loadProfile()
                dialog.dismiss()
            }
        }

        dialog.show()
    }
}
