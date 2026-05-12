import Foundation
import CoreWLAN

/// One sample of WiFi signal state at a moment in time.
struct SignalSample: Identifiable {
    let id = UUID()
    let timestamp: Date
    let rssi: Int          // dBm. Higher (closer to 0) is stronger.
    let noise: Int         // dBm noise floor.
    let transmitRate: Double  // Mbps
    let ssid: String?

    var snr: Int { rssi - noise }
}

/// Ring buffer of recent signal samples. Used to render the live
/// signal/noise/SNR/transmit-rate graph. Bounded capacity prevents
/// unbounded memory growth even if the graph window stays open
/// indefinitely.
///
/// Sampling cadence is driven externally (start/stop) so we don't waste
/// CPU when the graph isn't visible. The graph window opens → starts
/// sampling at 1 Hz; window closes → stops sampling.
final class SignalSampleStore {
    private let client = CWWiFiClient.shared()
    private var samples: [SignalSample] = []
    private let capacity: Int
    private var timer: Timer?
    private let sampleInterval: TimeInterval

    /// Fires on the main thread whenever a new sample is appended.
    var onSampleAdded: ((SignalSample) -> Void)?

    /// - Parameter capacity: how many samples to retain. 300 @ 1 Hz = 5 minutes
    ///   of history visible in the live graph.
    /// - Parameter sampleInterval: seconds between samples. 1.0 gives a
    ///   smooth-looking line graph without burning CPU; 0.5 is also fine.
    init(capacity: Int = 300, sampleInterval: TimeInterval = 1.0) {
        self.capacity = capacity
        self.sampleInterval = sampleInterval
    }

    /// All retained samples, oldest first. Safe to read from main thread.
    var allSamples: [SignalSample] { samples }

    /// Begin sampling. Idempotent — calling twice in a row is a no-op.
    func start() {
        guard timer == nil else { return }
        // Capture an immediate sample so the graph isn't empty for the
        // first second after the window opens.
        appendCurrentSample()

        timer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] _ in
            self?.appendCurrentSample()
        }
    }

    /// Stop sampling. Existing samples are retained so the graph stays
    /// visible if the window briefly toggles.
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Wipe history. Useful when the user changes networks and wants a
    /// fresh graph rather than seeing the previous network's data.
    func reset() {
        samples.removeAll(keepingCapacity: true)
    }

    private func appendCurrentSample() {
        guard let iface = client.interface(), iface.powerOn() else { return }
        let sample = SignalSample(
            timestamp: Date(),
            rssi: iface.rssiValue(),
            noise: iface.noiseMeasurement(),
            transmitRate: iface.transmitRate(),
            ssid: iface.ssid()
        )
        samples.append(sample)
        if samples.count > capacity {
            samples.removeFirst(samples.count - capacity)
        }
        onSampleAdded?(sample)
    }
}
