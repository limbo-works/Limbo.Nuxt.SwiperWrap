# SwiperWrap
a Nuxt component for handling swipers


## Basic usage

```
<SwiperWrap
  :move-by="1"
  :class=""
  :items-wrapper-class-names=""
>

  <template #before="{ showPagination, go }">
    <div>
      <button
        :aria-disabled="!showPagination.previous"
        aria-label="Gå til forrige"
        @click="() => go.previous(false)"
      >
        prev
      </button>
      <button
        :aria-disabled="!showPagination.next"
        aria-label="Gå til næste"
        @click="() => go.next(false)"
      >
        next
      </button>
    </div>
  </template>

  <template #items>
    <div
      v-for="item in list"
      :key="item"
    >
      ...
    </div>
  </template>

  <template #default="{ pagination }">
    <div
      v-if="images[pagination.index]"
    >
      <span
        v-if="images.length > 1"
        class="
          text-image-pagination
        "
        v-text="`${pagination.index + 1} / ${pagination.count}`"
      ></span>
    </div>
  </template>

</Swiperwrap>
```


## Available configuration

### Props
| Prop                | Description                                                                      |
| ------------------- | -------------------------------------------------------------------------------- |
| tag        | tag of container element. Default: 'section'            |
| moveBy        | How many items should a single go.next() or go.prev() move. Default: -1             |
| itemsWrapperClassNames | A string of classes to at to wrapper dev og components |
| setIndex | start index. Default: 0 |
| screenReaderTemplate | A template string for status element in screenreaders. Default: 'Viser slide #{active} af #{total}', |


### Available slots
| Slot name           | Description                                                                      |
| ------------------- | -------------------------------------------------------------------------------- |
| default        | content placed after items container              |
| before | content placed before items container |
| items | Items container |
| custom | used to overwrite all behaviour, wraps all other slots |

#### Slot props available for all slots

| Slot name           | Description                                                                      |
| ------------------- | -------------------------------------------------------------------------------- |
| state.scrollable        | Boolean. is scrollable             |
| state.inView | Array. Items in view. |
| go.previous() | Function. Move back by specied moveBy amount |
| go.next() | Function. Move forward by specied moveBy amount |
| go.to() | Function. Move to specied index |
| pagination.index | Int. Currentindex, first of shown items |
| pagination.count | Int. Total number of items. |
| showPagination.next | Boolean. Should next button be shown. |
| showPagination.previous | Boolean. Should previous button be shown. |
| showPagination.either | Boolean. Should either previous or next button be shown. |
| showPagination.both | Boolean. Should both previous and next button be shown. |
| methods.updateCurrent() | Function. Updates pagination.index and state.inView items. (happens in default use-cases automatically) |
| methods.goToFocused() | Function. Updates pagination.index and state.inView items to go from element in focus. |
