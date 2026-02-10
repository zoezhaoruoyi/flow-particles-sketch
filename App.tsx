
import React, { useState, useEffect, useRef, useCallback } from 'react';
import FlowCanvas from './components/FlowCanvas';
import { useAudioAnalyzer } from './hooks/useAudioAnalyzer';

const App: React.FC = () => {
  const [isMicEnabled, setIsMicEnabled] = useState(false);
  const { volume, startAudio, error } = useAudioAnalyzer();

  const handleStartInteraction = async () => {
    if (!isMicEnabled) {
      const success = await startAudio();
      if (success) {
        setIsMicEnabled(true);
      }
    }
  };

  return (
    <div className="relative w-screen h-screen bg-neutral-950 overflow-hidden flex flex-col font-sans">
      {/* Background Subtle Gradient */}
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(17,24,39,1)_0%,rgba(0,0,0,1)_100%)] pointer-events-none" />

      {/* Main Canvas Component */}
      <FlowCanvas volume={volume} />

      {/* UI Overlay */}
      <div className="absolute top-8 left-1/2 -translate-x-1/2 z-10 pointer-events-none text-center">
        <h1 className="text-white/40 text-sm tracking-[0.2em] uppercase mb-2">Flow Particles Sketch</h1>
        {!isMicEnabled && (
          <button 
            onClick={handleStartInteraction}
            className="pointer-events-auto px-6 py-2 bg-white/5 border border-white/10 text-white/80 rounded-full text-xs transition-all hover:bg-white/10 backdrop-blur-md"
          >
            {error ? "Mic Access Denied" : "Enable Audio Reactivity"}
          </button>
        )}
        {isMicEnabled && (
          <div className="flex items-center justify-center gap-2">
            <div 
              className="h-1 bg-blue-500/50 rounded-full transition-all duration-75" 
              style={{ width: `${Math.min(100, volume * 500)}px` }} 
            />
          </div>
        )}
      </div>

      {/* Instructions */}
      <div className="absolute bottom-8 left-8 z-10 pointer-events-none">
        <p className="text-white/20 text-[10px] uppercase tracking-widest leading-relaxed">
          Draw freely on screen<br />
          Particles drift to sound frequency
        </p>
      </div>
      
      {/* Visual Feedback of Mic State */}
      {isMicEnabled && (
        <div className="absolute top-4 right-4 flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
          <span className="text-white/40 text-[10px] uppercase">Audio Active</span>
        </div>
      )}
    </div>
  );
};

export default App;
