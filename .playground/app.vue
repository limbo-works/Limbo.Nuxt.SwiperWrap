<template>
  <div>
    <SwiperWrap
      :move-by="1"
      :class="[]"
      :items-wrapper-class-names="[
        'flex w-full',
        'snap snap-x snap-mandatory',
        {
          'overflow-x-auto': images.length >= 2,
          'overflow-x-hidden': images.length === 1,
        },
      ]"
    >
      <template #before="{ showPagination, go }">
        <div>
          <!-- Previous -->
          <button
            :aria-disabled="!showPagination.previous"
            aria-label="Gå til forrige"
            @click="() => go.previous(false)"
          >
            prev
          </button>

          <!-- Next -->
          <button
            :aria-disabled="!showPagination.next"
            aria-label="Gå til næste"
            @click="() => go.next(false)"
          >
            next
          </button>
        </div>
      </template>
      <!-- Items -->
      <template #items>
        <button
          v-for="image in images"
          :key="image"
          :class="[
            'snap-start pl-layout-margin',
            '>=768:min-w-full >=768:rounded-0 >=768:pl-0 w-500',
          ]"
          style="width: 500px"
        >
          <div>hello! {{ image }}</div>
        </button>
      </template>

      <!-- Caption -->
      <template #default="{ pagination }">
        <div v-if="images[pagination.index]">
          <span
            v-if="images.length > 1"
            class="text-image-pagination"
            v-text="`${pagination.index + 1} / ${pagination.count}`"
          ></span>

          <span
            v-if="images[pagination.index].imageText"
            :id="`${_uid}-caption-${pagination.index}`"
            :key="`${_uid}-caption-${pagination.index}`"
            class="s-rich-text text-teaser-sm"
            v-html="images[pagination.index].imageText"
          ></span>
        </div>
      </template>
    </SwiperWrap>
  </div>
</template>

<script setup>
const images = ref(["hey1", "hey2", "hey3", "hey4", "hey5"]);
</script>

<style>
.flex {
  display: flex;
}
.overflow-x-auto {
  overflow-x: auto;
}
.w-full {
  width: 100%;
}
.w-500 {
  width: 500px;
  flex-shrink: 0;
}
</style>
