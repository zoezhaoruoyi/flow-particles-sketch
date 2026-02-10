
import { useState, useRef, useCallback } from 'react';

export const useAudioAnalyzer = () => {
  const [volume, setVolume] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const audioContextRef = useRef<AudioContext | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const animationFrameRef = useRef<number>();

  const startAudio = useCallback(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const context = new (window.AudioContext || (window as any).webkitAudioContext)();
      const source = context.createMediaStreamSource(stream);
      const analyser = context.createAnalyser();
      
      analyser.fftSize = 256;
      source.connect(analyser);
      
      audioContextRef.current = context;
      analyserRef.current = analyser;

      const updateVolume = () => {
        const dataArray = new Uint8Array(analyser.frequencyBinCount);
        analyser.getByteFrequencyData(dataArray);
        
        let sum = 0;
        for (let i = 0; i < dataArray.length; i++) {
          sum += dataArray[i];
        }
        
        const average = sum / dataArray.length;
        setVolume(average / 255); // Normalize to 0-1
        
        animationFrameRef.current = requestAnimationFrame(updateVolume);
      };

      updateVolume();
      return true;
    } catch (err) {
      console.error("Audio initialization failed:", err);
      setError("Microphone access is required for audio reactivity.");
      return false;
    }
  }, []);

  return { volume, startAudio, error };
};
