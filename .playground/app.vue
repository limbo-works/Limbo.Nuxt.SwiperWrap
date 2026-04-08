<template>
  <main class="playground">
    <header class="hero">
      <p class="eyebrow">SwiperWrap Playground</p>
      <h1>Interactive demo and test surface</h1>
      <p class="lead">
        Use the controls to verify pagination, in-view detection, focus behavior,
        variable widths, and custom slot mode.
      </p>
    </header>

    <section class="panel">
      <h2>Global controls</h2>
      <div class="controls-grid">
        <label class="field">
          Move by
          <input v-model.number="moveBy" type="number" min="-1" max="8" />
        </label>
        <label class="field">
          Start index
          <input
            v-model.number="setIndex"
            type="number"
            min="0"
            :max="Math.max(cards.length - 1, 0)"
          />
        </label>
        <label class="field field--inline">
          <input v-model="autoFocus" type="checkbox" />
          Auto focus active
        </label>
        <label class="field field--inline">
          <input v-model="withScreenReaderStatus" type="checkbox" />
          Screen reader status text
        </label>
      </div>
    </section>

    <section class="panel">
      <h2>Default mode</h2>
      <SwiperWrap
        :move-by="moveBy"
        :set-index="setIndex"
        :auto-focus="autoFocus"
        :screen-reader-template="
          withScreenReaderStatus ? 'Showing #{active} of #{total}' : ''
        "
        :items-wrapper-class-names="[
          'carousel-track',
          'snap-row',
          {
            'has-scroll': cards.length >= 2,
            'no-scroll': cards.length < 2,
          },
        ]"
        @update="(index) => (liveIndex = index)"
        @state-change="(state) => (liveState = state)"
      >
        <template #before="{ showPagination, go }">
          <div class="toolbar">
            <button
              :disabled="!showPagination.previous"
              @click="go.previous(false)"
            >
              Previous
            </button>
            <button :disabled="!showPagination.next" @click="go.next(false)">
              Next
            </button>
            <button @click="go.previous(true)">Loop to end</button>
            <button @click="go.next(true)">Loop to start</button>
          </div>
        </template>

        <template #items>
          <button
            v-for="card in cards"
            :key="card.id"
            class="card snap-start"
            :style="cardStyle(card)"
          >
            <strong>{{ card.title }}</strong>
            <span>{{ card.text }}</span>
          </button>
        </template>

        <template #default="{ pagination, state }">
          <div class="meta">
            <span>Index: {{ pagination.index }} / {{ pagination.count - 1 }}</span>
            <span>In view: {{ state.inView.join(', ') || '-' }}</span>
          </div>
        </template>
      </SwiperWrap>

      <div class="diagnostic">
        <strong>Last events</strong>
        <p>update: {{ liveIndex }}</p>
        <p>
          state-change:
          {{
            `${liveState.showPrevious ? 'prev:on' : 'prev:off'} | ${
              liveState.showNext ? 'next:on' : 'next:off'
            }`
          }}
        </p>
      </div>
    </section>

    <section class="panel">
      <h2>Custom slot mode</h2>
      <p class="hint">
        This section validates compatibility with full custom markup.
      </p>

      <SwiperWrap :move-by="-1" :auto-focus="autoFocus">
        <template #custom="{ go, pagination }">
          <div class="toolbar">
            <button @click="go.previous(false)">Previous</button>
            <button @click="go.next(false)">Next</button>
            <span class="pill"
              >{{ pagination.index + 1 }} / {{ pagination.count }}</span
            >
          </div>

          <div class="js-swiper-wrap__content custom-track">
            <article
              v-for="item in stories"
              :key="item.id"
              class="js-swiper-wrap__child custom-card"
            >
              <h3>{{ item.title }}</h3>
              <p>{{ item.body }}</p>
            </article>

            <div
              class="js-swiper-wrap__child--spacer"
              style="width: 1px; height: 1px"
              aria-hidden="true"
            />
          </div>
        </template>
      </SwiperWrap>
    </section>
  </main>
</template>

<script setup>
const moveBy = ref(1);
const setIndex = ref(0);
const autoFocus = ref(true);
const withScreenReaderStatus = ref(true);

const liveIndex = ref(0);
const liveState = ref({
	showPrevious: false,
	showNext: false,
});

const cards = ref([
	{ id: 1, width: 280, title: 'Card 1', text: 'Compact item for edge testing.' },
	{ id: 2, width: 320, title: 'Card 2', text: 'Wider card to test partial visibility.' },
	{ id: 3, width: 360, title: 'Card 3', text: 'Checks snap and move calculations.' },
	{ id: 4, width: 300, title: 'Card 4', text: 'Use keyboard focus to verify autofocus.' },
	{ id: 5, width: 260, title: 'Card 5', text: 'Short width validates in-view transitions.' },
	{ id: 6, width: 420, title: 'Card 6', text: 'Largest width tests end boundary behavior.' },
]);

const cardStyle = (card) => ({
	width: `min(${card.width}px, calc(100vw - 3.5rem))`,
});

const stories = ref([
	{
		id: 'a',
		title: 'Announcement',
		body: 'Testing custom slot mode with semantic article children.',
	},
	{
		id: 'b',
		title: 'Update',
		body: 'This slide verifies class-based query selectors.',
	},
	{
		id: 'c',
		title: 'Case study',
		body: 'Use these items to validate custom-wrapper integration.',
	},
	{
		id: 'd',
		title: 'Wrap-up',
		body: 'Looping and focus should work the same as default mode.',
	},
]);
</script>

<style>
:root {
  --bg: #f7f4ef;
  --paper: #fffefb;
  --ink: #1f1d1a;
  --soft: #6e665b;
  --line: #d8cec0;
  --brand: #0e7a68;
  --brand-ink: #ffffff;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  color: var(--ink);
  font-family: 'Avenir Next', 'Segoe UI', sans-serif;
  background:
    radial-gradient(circle at 10% 10%, #fff7e8 0%, transparent 40%),
    radial-gradient(circle at 90% 20%, #e5f7f2 0%, transparent 42%),
    var(--bg);
}

.playground {
  max-width: 1080px;
  margin: 0 auto;
  padding: 2rem 1rem 3rem;
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 1rem;
  min-width: 0;
}

.hero {
  background: linear-gradient(135deg, #fffefb, #fff6e8 62%, #eafaf6);
  border: 1px solid var(--line);
  border-radius: 14px;
  padding: 1.25rem;
}

.eyebrow {
  margin: 0;
  color: var(--soft);
  letter-spacing: 0.08em;
  text-transform: uppercase;
  font-size: 0.75rem;
}

h1,
h2,
h3 {
  margin: 0;
}

.lead {
  margin: 0.5rem 0 0;
  color: var(--soft);
}

.panel {
  background: var(--paper);
  border: 1px solid var(--line);
  border-radius: 14px;
  padding: 1rem;
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 0.75rem;
  min-width: 0;
  overflow-x: clip;
}

.panel > .c-swiper-wrap {
  min-width: 0;
  max-width: 100%;
}

.panel > .c-swiper-wrap .c-swiper-wrap__content {
  min-width: 0;
  max-width: 100%;
}

.controls-grid {
  display: grid;
  gap: 0.75rem;
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.field {
  display: grid;
  gap: 0.35rem;
  color: var(--soft);
  font-size: 0.9rem;
}

.field input[type='number'] {
  width: 100%;
  border: 1px solid var(--line);
  border-radius: 9px;
  padding: 0.5rem 0.65rem;
  background: #fff;
}

.field--inline {
  align-content: center;
  grid-auto-flow: column;
  justify-content: start;
  gap: 0.5rem;
}

.toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

button {
  border: 1px solid #0a6354;
  background: var(--brand);
  color: var(--brand-ink);
  padding: 0.45rem 0.75rem;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.9rem;
}

button:disabled {
  background: #aab8b5;
  border-color: #90a09d;
  cursor: not-allowed;
}

.carousel-track {
  display: flex;
  width: 100%;
  max-width: 100%;
  min-width: 0;
}

.snap-row {
  scroll-snap-type: x mandatory;
}

.has-scroll {
  overflow-x: auto;
}

.no-scroll {
  overflow-x: hidden;
}

.snap-start {
  scroll-snap-align: start;
}

.card {
  flex-shrink: 0;
  max-width: calc(100vw - 3.5rem);
  min-height: 116px;
  display: grid;
  align-content: start;
  gap: 0.35rem;
  border: 1px solid var(--line);
  background: linear-gradient(170deg, #ffffff, #f8f6f2);
  color: var(--ink);
  border-radius: 10px;
  padding: 0.75rem;
  text-align: left;
}

.card strong {
  font-size: 1rem;
}

.card span {
  color: var(--soft);
  font-size: 0.9rem;
}

.meta {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  color: var(--soft);
  font-size: 0.9rem;
}

.diagnostic {
  border: 1px dashed var(--line);
  border-radius: 10px;
  padding: 0.75rem;
  background: #fff;
}

.diagnostic p {
  margin: 0.35rem 0 0;
  color: var(--soft);
}

.hint {
  margin: 0;
  color: var(--soft);
}

.custom-track {
  display: flex;
  gap: 0.65rem;
  width: 100%;
  max-width: 100%;
  min-width: 0;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
}

.custom-card {
  scroll-snap-align: start;
  flex-shrink: 0;
  max-width: calc(100vw - 3.5rem);
  width: 320px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: #fff;
  padding: 0.75rem;
}

.custom-card h3 {
  margin-bottom: 0.4rem;
}

.custom-card p {
  margin: 0;
  color: var(--soft);
}

.pill {
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  padding: 0.2rem 0.55rem;
  border: 1px solid var(--line);
  background: #fff;
  color: var(--soft);
  font-size: 0.85rem;
}

@media (max-width: 760px) {
  .controls-grid {
    grid-template-columns: 1fr;
  }

  .card,
  .custom-card {
    width: min(85vw, 360px) !important;
  }
}
</style>
