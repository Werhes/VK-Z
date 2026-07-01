import Foundation
import AVFoundation
import MediaPlayer
import Combine

// MARK: - Audio Player Manager
final class AudioPlayerManager: NSObject, ObservableObject {
    static let shared = AudioPlayerManager()
    
    // MARK: - Published Properties
    @Published var currentTrack: VKTrack?
    @Published var playerState: PlayerState = .stopped
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 1.0
    @Published var repeatMode: PlayerRepeatMode = .all
    @Published var isShuffled: Bool = false
    
    // MARK: - Queue
    @Published var queue: [VKTrack] = []
    @Published var currentIndex: Int = 0
    
    // MARK: - Private Properties
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommandCenter()
        setupNowPlaying()
    }
    
    // MARK: - Setup
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothHFP])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextTrack()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousTrack()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }
    }
    
    private func setupNowPlaying() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    // MARK: - Playback Controls
    func playTrack(_ track: VKTrack) {
        guard let url = track.audioUrl else {
            playerState = .error("Не удалось получить URL трека")
            return
        }
        
        playerState = .loading
        currentTrack = track
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = volume
        
        addTimeObserver()
        
        player?.play()
        playerState = .playing
        updateNowPlayingInfo()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    func play() {
        guard playerState == .paused || playerState == .stopped else { return }
        player?.play()
        playerState = .playing
        updateNowPlayingInfo()
    }
    
    func pause() {
        guard case .playing = playerState else { return }
        player?.pause()
        playerState = .paused
        updateNowPlayingInfo()
    }
    
    func togglePlayPause() {
        switch playerState {
        case .playing:
            pause()
        case .paused, .stopped:
            if currentTrack != nil {
                play()
            } else if !queue.isEmpty {
                playTrack(queue[0])
            }
        default:
            break
        }
    }
    
    func nextTrack() {
        guard !queue.isEmpty else { return }
        
        if isShuffled {
            currentIndex = Int.random(in: 0..<queue.count)
        } else {
            currentIndex = (currentIndex + 1) % queue.count
        }
        
        playTrack(queue[currentIndex])
    }
    
    func previousTrack() {
        guard !queue.isEmpty else { return }
        
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        
        currentIndex = (currentIndex - 1 + queue.count) % queue.count
        playTrack(queue[currentIndex])
    }
    
    func seek(to time: TimeInterval) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 1000))
    }
    
    func setVolume(_ volume: Float) {
        self.volume = volume
        player?.volume = volume
    }
    
    // MARK: - Queue Management
    func setQueue(tracks: [VKTrack], startIndex: Int = 0) {
        queue = tracks
        currentIndex = startIndex
        if !tracks.isEmpty {
            playTrack(tracks[startIndex])
        }
    }
    
    func addToQueue(_ track: VKTrack) {
        queue.append(track)
    }
    
    func removeFromQueue(at index: Int) {
        guard index < queue.count else { return }
        queue.remove(at: index)
        if index < currentIndex {
            currentIndex -= 1
        }
    }
    
    func clearQueue() {
        queue.removeAll()
        currentIndex = 0
        stop()
    }
    
    func toggleShuffle() {
        isShuffled.toggle()
    }
    
    func toggleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .off
        }
    }
    
    // MARK: - Private Methods
    private func addTimeObserver() {
        removeTimeObserver()
        
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000),
            queue: .main
        ) { [weak self] time in
            self?.currentTime = time.seconds
            self?.duration = self?.player?.currentItem?.duration.seconds ?? 0
            self?.updateNowPlayingInfo()
        }
    }
    
    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        switch repeatMode {
        case .one:
            seek(to: 0)
            play()
        case .all:
            nextTrack()
        case .off:
            if currentIndex < queue.count - 1 {
                nextTrack()
            } else {
                playerState = .stopped
                currentTime = 0
            }
        }
    }
    
    private func stop() {
        removeTimeObserver()
        player?.pause()
        player = nil
        currentTrack = nil
        playerState = .stopped
        currentTime = 0
        duration = 0
    }
    
    // MARK: - Now Playing Info
    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        
        if let track = currentTrack {
            nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = track.albumTitle
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate ?? 0
            
            if let coverUrl = track.coverUrl {
                URLSession.shared.dataTask(with: coverUrl) { data, _, _ in
                    if let data = data, let image = UIImage(data: data) {
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
                            boundsSize: image.size
                        ) { _ in image }
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                    }
                }.resume()
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // MARK: - Cleanup
    deinit {
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self)
    }
}