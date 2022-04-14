import { createSignal, Show } from "solid-js";
import { render } from "solid-js/web";
import HLS from "hls.js/dist/hls.light.min";
import "./style.css";

const video = document.getElementById("video");
const [restarting, setRestarting] = createSignal(false);
const [unmute, setUnmute] = createSignal(true);

const App = () => (
  <>
    <Show when={restarting()}>
      <RestartingBanner />
    </Show>
    <Show when={unmute()}>
      <UnmuteBanner />
    </Show>
  </>
);

const RestartingBanner = () => (
  <Screencover>
    <Banner>reconnecting</Banner>
  </Screencover>
);

const UnmuteBanner = () => {
  const click = () => {
    setUnmute(false);
    video.muted = false;
    video.volume = 1;
  };

  return (
    <Screencover onClick={click}>
      <Banner>click to unmute</Banner>
    </Screencover>
  );
};

const Banner = (props) => (
  <div
    {...props}
    class={`
      ${props.color ? props.color : "text-white"}
      justify-center text-3xl my-auto max-w-xs
      alert bg-gray-900 select-none
    `}
  />
);

const Screencover = (props) => (
  <div
    {...props}
    class={`
      fixed inset-x-0 inset-y-0 overflow-hidden
      flex justify-center z-50
    `}
  />
);

let hls;
const videoScreen = document.getElementById("video");

const init = () => {
  const params = new URLSearchParams(window.location.search);
  if (params.get("url") == null) throw "error: no url parameter set";
  const streamURL = params.get("url");

  hls = new HLS({
    defaultAudioCodec: "mp4a.40.2",
    autoStartLoad: false,
    liveDurationInfinity: true,
  });
  hls.attachMedia(videoScreen);

  hls.on(HLS.Events.ERROR, async (event, data) => {
    if (
      data.details === "manifestLoadError" ||
      data.details === "levelLoadError"
    ) {
      await sleep(1000);
      hls.loadSource(streamURL);
    } else {
      setRestarting(true);
      hls.destroy();
    }
  });

  hls.on(HLS.Events.MANIFEST_LOADED, async (event, data) => {
    setRestarting(false);
    const startTime = Number(
      data.networkDetails.response
        .match(/stream-[0-9]+.ts/)[0]
        .match(/[0-9]+/)[0]
    );
    const syncTime = await getSyncTime(startTime);
    if (syncTime !== 0) hls.startLoad(syncTime);
    else hls.startLoad();
  });

  hls.on(HLS.Events.DESTROYING, () => init());

  hls.loadSource(streamURL);
};

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const getSyncTime = (startTime) =>
  fetch("/sync", {})
    .then((response) => response.text())
    .then((txt) => (isNaN(txt) ? 0 : Number(txt)))
    // -15 is halfway through a 30 second playlist
    .then((time) =>
      time !== 0 ? Math.round(time - 15.0 - startTime / 1000.0) : 0
    );

init();
render(App, document.getElementById("screen"));
