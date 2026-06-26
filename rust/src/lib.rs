use serde::{Deserialize, Serialize};
use std::sync::Mutex;

// ──────────────────────────────────────────────────────────────
// Модели данных (как в Python VkTrack, VkPlaylist, VkUser)
// ──────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VkTrack {
    pub id: i64,
    pub owner_id: i64,
    pub artist: String,
    pub title: String,
    pub duration: i64,
    pub url: String,
    pub thumb_url: String,
    pub thumb_url_big: String,
    pub access_key: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VkPlaylist {
    pub id: i64,
    pub owner_id: i64,
    pub title: String,
    pub count: i64,
    pub thumb_url: String,
    pub description: String,
    pub access_key: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VkUser {
    pub id: i64,
    pub first_name: String,
    pub last_name: String,
    pub photo_url: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VkMixSettings {
    pub settings: Option<serde_json::Value>,
}

// ──────────────────────────────────────────────────────────────
// VK API Client (порт Python VkClient)
// ──────────────────────────────────────────────────────────────

const KATE_USER_AGENT: &str = "KateMobileAndroid/56 lite-460 (Android 4.4.2; SDK 19; x86; unknown Android SDK built for x86; en)";
const API_VERSION: &str = "5.131";
const API_BASE: &str = "https://api.vk.ru/method";

pub struct VkClient {
    token: Mutex<Option<String>>,
    user_id: Mutex<Option<i64>>,
    client: reqwest::Client,
}

impl VkClient {
    pub fn new() -> Self {
        let client = reqwest::Client::builder()
            .user_agent(KATE_USER_AGENT)
            .build()
            .expect("Failed to create HTTP client");

        Self {
            token: Mutex::new(None),
            user_id: Mutex::new(None),
            client,
        }
    }

    // ── Auth ────────────────────────────────────────────────

    pub fn set_token(&self, token: String, user_id: Option<i64>) {
        *self.token.lock().unwrap() = Some(token);
        if let Some(uid) = user_id {
            *self.user_id.lock().unwrap() = Some(uid);
        }
    }

    pub fn get_token(&self) -> Option<String> {
        self.token.lock().unwrap().clone()
    }

    pub fn get_user_id(&self) -> Option<i64> {
        self.user_id.lock().unwrap().clone()
    }

    // ── Внутренние запросы ──────────────────────────────────

    async fn call(&self, method: &str, params: Vec<(&str, String)>) -> Result<serde_json::Value, String> {
        let token = self.token.lock().unwrap().clone()
            .ok_or_else(|| "Not authorized".to_string())?;

        let url = format!("{}/{}", API_BASE, method);

        let mut query_params = params;
        query_params.push(("access_token", token));
        query_params.push(("v", API_VERSION.to_string()));
        query_params.push(("lang", "ru".to_string()));

        let response = self.client
            .get(&url)
            .query(&query_params)
            .send()
            .await
            .map_err(|e| format!("HTTP error: {}", e))?;

        let status = response.status();
        let body = response.text().await
            .map_err(|e| format!("Failed to read response body: {}", e))?;

        if !status.is_success() {
            return Err(format!("HTTP {}: {}", status, body));
        }

        let data: serde_json::Value = serde_json::from_str(&body)
            .map_err(|e| format!("JSON parse error: {} (body: {})", e, &body[..body.len().min(500)]))?;

        if let Some(error) = data.get("error") {
            let code = error.get("error_code").and_then(|c| c.as_i64()).unwrap_or(0);
            let msg = error.get("error_msg").and_then(|m| m.as_str()).unwrap_or("Unknown");
            return Err(format!("VK API Error [{}]: {}", code, msg));
        }

        Ok(data.get("response").cloned().unwrap_or(data))
    }

    // ── User ────────────────────────────────────────────────

    pub async fn get_current_user(&self) -> Result<VkUser, String> {
        let data = self.call("users.get", vec![("fields", "photo_100".to_string())]).await?;
        let arr = data.as_array().ok_or("Expected array")?;
        let user = arr[0].clone();
        Ok(VkUser {
            id: user["id"].as_i64().unwrap_or(0),
            first_name: user["first_name"].as_str().unwrap_or("").to_string(),
            last_name: user["last_name"].as_str().unwrap_or("").to_string(),
            photo_url: user["photo_100"].as_str().unwrap_or("").to_string(),
        })
    }

    // ── Tracks ──────────────────────────────────────────────

    pub async fn get_tracks(&self, owner_id: Option<i64>, offset: i64, count: i64) -> Result<Vec<VkTrack>, String> {
        let uid = owner_id.or_else(|| self.get_user_id()).ok_or("No user_id")?;
        let data = self.call("audio.get", vec![
            ("owner_id", uid.to_string()),
            ("offset", offset.to_string()),
            ("count", count.to_string()),
        ]).await?;

        Ok(parse_tracks(data))
    }

    // ── Search ──────────────────────────────────────────────

    pub async fn search_tracks(&self, query: String, count: i64, offset: i64) -> Result<Vec<VkTrack>, String> {
        let data = self.call("audio.search", vec![
            ("q", query),
            ("count", count.to_string()),
            ("offset", offset.to_string()),
            ("auto_complete", "1".to_string()),
            ("sort", "2".to_string()),
        ]).await?;

        Ok(parse_tracks(data))
    }

    // ── Playlists ───────────────────────────────────────────

    pub async fn get_playlists(&self, owner_id: Option<i64>) -> Result<Vec<VkPlaylist>, String> {
        let uid = owner_id.or_else(|| self.get_user_id()).ok_or("No user_id")?;
        let data = self.call("audio.getPlaylists", vec![
            ("owner_id", uid.to_string()),
            ("count", "200".to_string()),
        ]).await?;

        Ok(parse_playlists(data))
    }

    pub async fn get_playlist_tracks(&self, playlist_id: i64, owner_id: i64, access_key: String) -> Result<Vec<VkTrack>, String> {
        let mut params = vec![
            ("owner_id", owner_id.to_string()),
            ("playlist_id", playlist_id.to_string()),
            ("count", "2000".to_string()),
        ];
        if !access_key.is_empty() {
            params.push(("access_key", access_key));
        }

        let data = self.call("audio.get", params).await?;
        Ok(parse_tracks(data))
    }

    // ── Recommendations ─────────────────────────────────────

    pub async fn get_recommendations(&self, target_audio: String, count: i64) -> Result<Vec<VkTrack>, String> {
        let mut params = vec![
            ("count", count.to_string()),
            ("shuffle", "1".to_string()),
        ];
        if target_audio.is_empty() {
            let uid = self.get_user_id().ok_or("No user_id")?;
            params.push(("user_id", uid.to_string()));
        } else {
            params.push(("target_audio", target_audio));
        }

        let data = self.call("audio.getRecommendations", params).await?;
        Ok(parse_tracks(data))
    }

    // ── VK Mix ──────────────────────────────────────────────

    pub async fn get_stream_mix_audios(&self, mix_id: String, count: i64) -> Result<Vec<VkTrack>, String> {
        let data = self.call("audio.getStreamMixAudios", vec![
            ("mix_id", mix_id),
            ("count", count.to_string()),
        ]).await?;

        Ok(parse_tracks(data))
    }

    pub async fn get_stream_mix_settings(&self, mix_id: String) -> Result<serde_json::Value, String> {
        let data = self.call("audio.getStreamMixSettings", vec![
            ("mix_id", mix_id),
        ]).await?;

        Ok(data)
    }

    // ── Audio by ID ─────────────────────────────────────────

    pub async fn get_audio_by_id(&self, audio_ids: String) -> Result<Vec<VkTrack>, String> {
        let data = self.call("audio.getById", vec![
            ("audios", audio_ids),
        ]).await?;

        Ok(parse_tracks(data))
    }
}

// ──────────────────────────────────────────────────────────────
// Парсинг ответов VK API
// ──────────────────────────────────────────────────────────────

fn parse_tracks(data: serde_json::Value) -> Vec<VkTrack> {
    let items = data.get("items")
        .and_then(|i| i.as_array())
        .cloned()
        .unwrap_or_default();

    items.iter().map(|item| {
        let album = item.get("album").and_then(|a| a.as_object()).cloned().unwrap_or_default();
        let thumb_small = album.get("thumb")
            .and_then(|t| t.get("photo"))
            .and_then(|p| p.as_array())
            .and_then(|arr| arr.first())
            .and_then(|p| p.get("url"))
            .and_then(|u| u.as_str())
            .unwrap_or("")
            .to_string();
        let thumb_big = album.get("thumb")
            .and_then(|t| t.get("photo"))
            .and_then(|p| p.as_array())
            .and_then(|arr| arr.last())
            .and_then(|p| p.get("url"))
            .and_then(|u| u.as_str())
            .unwrap_or("")
            .to_string();

        VkTrack {
            id: item["id"].as_i64().unwrap_or(0),
            owner_id: item["owner_id"].as_i64().unwrap_or(0),
            artist: item["artist"].as_str().unwrap_or("Unknown").to_string(),
            title: item["title"].as_str().unwrap_or("Unknown").to_string(),
            duration: item["duration"].as_i64().unwrap_or(0),
            url: item["url"].as_str().unwrap_or("").to_string(),
            thumb_url: if thumb_small.is_empty() { thumb_big.clone() } else { thumb_small },
            thumb_url_big: if thumb_big.is_empty() { thumb_small } else { thumb_big },
            access_key: item["access_key"].as_str().unwrap_or("").to_string(),
        }
    }).collect()
}

fn parse_playlists(data: serde_json::Value) -> Vec<VkPlaylist> {
    let items = data.get("items")
        .and_then(|i| i.as_array())
        .cloned()
        .unwrap_or_default();

    items.iter().map(|item| {
        let thumb = item.get("photo")
            .and_then(|p| p.get("photo"))
            .and_then(|p| p.as_array())
            .and_then(|arr| arr.last())
            .and_then(|p| p.get("url"))
            .and_then(|u| u.as_str())
            .unwrap_or("")
            .to_string();

        VkPlaylist {
            id: item["id"].as_i64().unwrap_or(0),
            owner_id: item["owner_id"].as_i64().unwrap_or(0),
            title: item["title"].as_str().unwrap_or("Без названия").to_string(),
            count: item["count"].as_i64().unwrap_or(0),
            thumb_url: thumb,
            description: item["description"].as_str().unwrap_or("").to_string(),
            access_key: item["access_key"].as_str().unwrap_or("").to_string(),
        }
    }).collect()
}

// ──────────────────────────────────────────────────────────────
// flutter_rust_bridge API (публичные функции для Dart)
// ──────────────────────────────────────────────────────────────

// Эти функции будут вызваны из Dart через flutter_rust_bridge.
// Каждая принимает &VkClient (state) и возвращает результат.

// Создание клиента
pub fn create_client() -> VkClient {
    VkClient::new()
}

// Auth
pub fn set_token(client: &VkClient, token: String, user_id: Option<i64>) {
    client.set_token(token, user_id);
}

pub fn get_token(client: &VkClient) -> Option<String> {
    client.get_token()
}

pub fn get_user_id(client: &VkClient) -> Option<i64> {
    client.get_user_id()
}

// User
pub async fn get_current_user(client: &VkClient) -> Result<VkUser, String> {
    client.get_current_user().await
}

// Tracks
pub async fn get_tracks(client: &VkClient, owner_id: Option<i64>, offset: i64, count: i64) -> Result<Vec<VkTrack>, String> {
    client.get_tracks(owner_id, offset, count).await
}

// Search
pub async fn search_tracks(client: &VkClient, query: String, count: i64, offset: i64) -> Result<Vec<VkTrack>, String> {
    client.search_tracks(query, count, offset).await
}

// Playlists
pub async fn get_playlists(client: &VkClient, owner_id: Option<i64>) -> Result<Vec<VkPlaylist>, String> {
    client.get_playlists(owner_id).await
}

pub async fn get_playlist_tracks(client: &VkClient, playlist_id: i64, owner_id: i64, access_key: String) -> Result<Vec<VkTrack>, String> {
    client.get_playlist_tracks(playlist_id, owner_id, access_key).await
}

// Recommendations
pub async fn get_recommendations(client: &VkClient, target_audio: String, count: i64) -> Result<Vec<VkTrack>, String> {
    client.get_recommendations(target_audio, count).await
}

// VK Mix
pub async fn get_stream_mix_audios(client: &VkClient, mix_id: String, count: i64) -> Result<Vec<VkTrack>, String> {
    client.get_stream_mix_audios(mix_id, count).await
}

pub async fn get_stream_mix_settings(client: &VkClient, mix_id: String) -> Result<serde_json::Value, String> {
    client.get_stream_mix_settings(mix_id).await
}

// Audio by ID
pub async fn get_audio_by_id(client: &VkClient, audio_ids: String) -> Result<Vec<VkTrack>, String> {
    client.get_audio_by_id(audio_ids).await
}