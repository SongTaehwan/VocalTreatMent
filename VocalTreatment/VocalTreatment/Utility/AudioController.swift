//
//  AudioController.swift
//  VocalTreatment
//
//  Created by 송태환 on 2022/07/21.
//

import Foundation
import AVFoundation
import CoreGraphics

class AudioController {
	private var audioRecorder: AVAudioRecorder!
	private var timer: DispatchSourceTimer = {
		let queue = DispatchQueue(label: Bundle.main.bundleIdentifier ?? "audio timer", attributes: .concurrent)
		return DispatchSource.makeTimerSource(flags: [], queue: queue)
	}()


	private func setupAudioSession() {
		do {
			let session = AVAudioSession.sharedInstance()
			try session.setCategory(.record, mode: .measurement, options: .duckOthers)
			try session.setActive(true, options: .notifyOthersOnDeactivation)
		} catch {
			fatalError("Failed to configure and activate session.")
		}
	}

	private func setupAudioRecorder() {
		let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
		let url = tempDirectory.appendingPathComponent("recording.m4a")

		let recordSettings = [
			AVSampleRateKey : NSNumber(value: Float(44100.0) as Float),
			AVFormatIDKey : NSNumber(value: Int32(kAudioFormatMPEG4AAC) as Int32),
			AVNumberOfChannelsKey : NSNumber(value: 1 as Int32),
			AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.low.rawValue) as Int32),
		]

		do {
			audioRecorder = try AVAudioRecorder(url: url, settings: recordSettings)
		} catch  {
			fatalError("Unable to create audio recorder: \(error.localizedDescription)")
		}

		audioRecorder.prepareToRecord()
		audioRecorder.isMeteringEnabled = true
	}

	func recordForever(audioRecorder: AVAudioRecorder) {
		timer.schedule(deadline: .now(), repeating: .milliseconds(300), leeway: .milliseconds(100))
		timer.setEventHandler { [weak self] in
			audioRecorder.updateMeters()

			// NOTE: seems to be the approx correction to get real decibels
			let correction: Float = 100
			let average = audioRecorder.averagePower(forChannel: 0) + correction
			let peak = audioRecorder.peakPower(forChannel: 0) + correction
			print(average, peak)
		}

		timer.resume()
	}

	func start() {
		setupAudioSession()
		setupAudioRecorder()
		audioRecorder.record()
		recordForever(audioRecorder: audioRecorder)
	}

	func stop() {
		if audioRecorder.isRecording {
			timer.cancel()
			timer.suspend()
			audioRecorder.stop()
		}
	}
}
