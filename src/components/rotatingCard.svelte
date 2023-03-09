<script>
  import { onMount, tick } from "svelte";
  import { range } from "../utils/animation";
  import { tweened } from "svelte/motion";

  let x, y;

  let windowX, windowY;

  let cardX, cardY, cardW, cardH;

  let card;

  let active = false;

  const positions = () => {
    windowX = window.innerWidth;
    windowY = window.innerHeight;

    const bcr = card.getBoundingClientRect();
    cardX = bcr.left;
    cardY = bcr.top;
    cardW = bcr.width;
    cardH = bcr.height;
    console.log("pos", { cardX, cardY, cardH, cardW });
  };

  onMount(async () => {
    addEventListener("resize", positions);

    positions();

    document.querySelectorAll("img").forEach((el) => {
      el.addEventListener("load", positions);
    });
  });

  const twX = tweened(0, { duration: 200 });
  const twY = tweened(0, { duration: 200 });

  const enter = () => {
    active = true;
  };

  const leave = () => {
    twX.set(50, { duration: 200 });
    twY.set(50, { duration: 200 });
  };

  const updXY = (e) => {
    if (!active) return;
    x = range(cardX, cardX + cardW, 0, 100, e.x);
    y = range(cardY, cardY + cardH, 0, 100, e.y);
    twX.set(x);
    twY.set(y);
  };
</script>

<div on:mouseenter={enter} on:mousemove={updXY} on:mouseleave={leave}>
  <div
    bind:this={card}
    class="border border-neutral-700 rounded-md w-full bg-neutral-900 overflow-hidden"
    style="transform:
    rotateY({active ? range(0, 100, 15, -15, $twX) : 0}deg) 
    rotateX({active ? range(0, 100, 15, -15, $twY) : 0}deg)
    perspective(400px)"
  >
    <div class="relative">
      <slot />
    </div>
    <div
      class="absolute bg-white w-40 h-40 left-0 top-0 z-10 blur-[100px]"
      style="transform:
      translate(calc({range(0, 100, 0, cardW, $twX)}px - 50%),
      calc({range(0, 100, 0, cardH, $twY)}px - 50%));
      opacity: 
      {range(0, 100, 0, 0.5, Math.abs($twX - 50) + Math.abs($twY - 50))};
      "
    />
  </div>
</div>
