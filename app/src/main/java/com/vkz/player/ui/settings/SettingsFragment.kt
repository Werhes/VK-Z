package com.vkz.player.ui.settings

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.SeekBar
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.widget.SwitchCompat
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
import com.vkz.player.LoginActivity
import com.vkz.player.R
import com.vkz.player.viewmodel.SettingsViewModel

class SettingsFragment : Fragment() {

    private lateinit var viewModel: SettingsViewModel

    private lateinit var switchRecommendations: SwitchCompat
    private lateinit var switchPopular: SwitchCompat
    private lateinit var switchNewReleases: SwitchCompat
    private lateinit var switchPlaylists: SwitchCompat
    private lateinit var seekTracksPerBlock: SeekBar
    private lateinit var tvTracksPerBlockValue: TextView
    private lateinit var btnLogout: Button

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        val view = inflater.inflate(R.layout.fragment_settings, container, false)

        viewModel = ViewModelProvider(requireActivity())[SettingsViewModel::class.java]

        switchRecommendations = view.findViewById(R.id.switch_recommendations)
        switchPopular = view.findViewById(R.id.switch_popular)
        switchNewReleases = view.findViewById(R.id.switch_new_releases)
        switchPlaylists = view.findViewById(R.id.switch_playlists)
        seekTracksPerBlock = view.findViewById(R.id.seek_tracks_per_block)
        tvTracksPerBlockValue = view.findViewById(R.id.tv_tracks_per_block_value)
        btnLogout = view.findViewById(R.id.btn_logout)

        setupListeners()
        observeViewModel()

        return view
    }

    private fun setupListeners() {
        switchRecommendations.setOnCheckedChangeListener { _, isChecked ->
            viewModel.updateShowRecommendations(isChecked)
        }

        switchPopular.setOnCheckedChangeListener { _, isChecked ->
            viewModel.updateShowPopular(isChecked)
        }

        switchNewReleases.setOnCheckedChangeListener { _, isChecked ->
            viewModel.updateShowNewReleases(isChecked)
        }

        switchPlaylists.setOnCheckedChangeListener { _, isChecked ->
            viewModel.updateShowPlaylists(isChecked)
        }

        seekTracksPerBlock.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                // Map 0-45 to 5-50
                val value = progress + 5
                tvTracksPerBlockValue.text = value.toString()
            }

            override fun onStartTrackingTouch(seekBar: SeekBar?) {}

            override fun onStopTrackingTouch(seekBar: SeekBar?) {
                val value = (seekBar?.progress ?: 15) + 5
                viewModel.updateMaxTracksPerBlock(value)
            }
        })

        btnLogout.setOnClickListener {
            showLogoutConfirmation()
        }
    }

    private fun observeViewModel() {
        viewModel.mixSettings.observe(viewLifecycleOwner) { settings ->
            // Update UI without triggering listeners
            switchRecommendations.setOnCheckedChangeListener(null)
            switchRecommendations.isChecked = settings.showRecommendations
            switchRecommendations.setOnCheckedChangeListener { _, isChecked ->
                viewModel.updateShowRecommendations(isChecked)
            }

            switchPopular.setOnCheckedChangeListener(null)
            switchPopular.isChecked = settings.showPopular
            switchPopular.setOnCheckedChangeListener { _, isChecked ->
                viewModel.updateShowPopular(isChecked)
            }

            switchNewReleases.setOnCheckedChangeListener(null)
            switchNewReleases.isChecked = settings.showNewReleases
            switchNewReleases.setOnCheckedChangeListener { _, isChecked ->
                viewModel.updateShowNewReleases(isChecked)
            }

            switchPlaylists.setOnCheckedChangeListener(null)
            switchPlaylists.isChecked = settings.showPlaylists
            switchPlaylists.setOnCheckedChangeListener { _, isChecked ->
                viewModel.updateShowPlaylists(isChecked)
            }

            val seekValue = (settings.maxTracksPerBlock - 5).coerceIn(0, 45)
            seekTracksPerBlock.progress = seekValue
            tvTracksPerBlockValue.text = settings.maxTracksPerBlock.toString()
        }

        viewModel.isLoggedOut.observe(viewLifecycleOwner) { loggedOut ->
            if (loggedOut) {
                val intent = Intent(requireContext(), LoginActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
                startActivity(intent)
                requireActivity().finish()
            }
        }
    }

    private fun showLogoutConfirmation() {
        AlertDialog.Builder(requireContext())
            .setTitle(R.string.settings_logout_confirm_title)
            .setMessage(R.string.settings_logout_confirm_message)
            .setPositiveButton(R.string.settings_logout) { _, _ ->
                viewModel.logout()
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }
}