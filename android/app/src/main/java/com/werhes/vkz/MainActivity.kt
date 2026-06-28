package com.werhes.vkz

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.werhes.vkz.data.api.AuthManager
import com.werhes.vkz.player.PlayerManager
import com.werhes.vkz.ui.navigation.MainNavigation
import com.werhes.vkz.ui.theme.VKZTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        AuthManager.init(applicationContext)
        PlayerManager.init(applicationContext)

        setContent {
            VKZTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    MainNavigation(isAuthenticated = AuthManager.isAuthenticated())
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        PlayerManager.release()
    }
}