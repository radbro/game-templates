// Opt-in graph testing when the machine has no working browser audio device.
// This file is test code. The game keeps the browser's normal output device.
export async function configureAudioTestSink(context) {
  const sink = process.env.AUDIO_TEST_SINK || 'default';
  if (!['default', 'none'].includes(sink)) throw Error('AUDIO_TEST_SINK must be default or none.');
  if (sink === 'none') {
    await context.addInitScript(() => {
      const Original = window.AudioContext;
      window.AudioContext = class extends Original {
        constructor(options = {}) { super({...options, sinkId: {type: 'none'}}); }
      };
    });
  }
  return {sink, physicalSpeakerOutputTested: false};
}
