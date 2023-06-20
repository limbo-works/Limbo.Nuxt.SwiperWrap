<!--
	Last modified: 2023/06/12 11:34:21
-->
<template>
  <Component
    :is="tag"
    class="c-swiper-wrap"
  >
    <div
      v-if="screenReaderTemplate && items.length > 1"
      key="status"
      class="c-swiper-wrap__live-region"
      role="status"
      v-text="screenReaderText"
    />

    <slot
      v-bind="slotBindings"
      name="custom"
    >
      <slot
        v-bind="slotBindings"
        name="before"
      />

      <div
        ref="content"
        :class="['c-swiper-wrap__content', itemsWrapperClassNames]"
        @wheel="updateCurrent"
        @scroll="updateCurrent"
        @touchmove="updateCurrent"
        @touchend="updateCurrent"
        @focusin="goToFocused"
      >
        <slot
          v-bind="slotBindings"
          name="items"
        />
      </div>

      <slot v-bind="slotBindings" />
    </slot>
  </Component>
</template>

<script>
const getActiveItemsLabel = (items, normal, end = normal) =>
	[items.slice(0, -1).join(normal), ...items.slice(-1)]
		.filter(Boolean)
		.join(end);

export default {
	name: 'SwiperWrap',
	props: {
		tag: {
			type: String,
			default: 'section',
		},
		moveBy: {
			type: Number,
			default: -1,
		},
		setIndex: {
			type: Number,
			default: null,
		},
		itemsWrapperClassNames: {
			type: [Array, Object, String],
			default: '',
		},
		screenReaderTemplate: {
			type: String,
			default: 'Viser slide #{active} af #{total}',
		},
	},
	data() {
		return {
			currentIndex: this.setIndex || 0,
			items: [],
			spacerItems: [],
			itemsInView: [],
			itemsContainer: null,
			wrapper: {
				left: 0,
				right: 0,
				width: 0,
			},
			lastTracedScrollPosition: null,
			states: {
				isScrollable: false,
				showPrevious: false,
				showNext: false,
			},
			frameRequest: null,
			screenReaderText: '',
		};
	},
	computed: {
		slotBindings() {
			return {
				state: {
					scrollable: this.states.isScrollable,
					inView: [...this.itemsInView],
				},
				go: {
					previous: this.previousItems,
					next: this.nextItems,
					to: this.goto,
				},
				pagination: {
					index: this.currentIndex,
					count: this.items.length,
				},
				showPagination: {
					next: this.states.showNext,
					previous: this.states.showPrevious,
					either: this.states.showNext || this.states.showPrevious,
					both: this.states.showNext && this.states.showPrevious,
				},
				methods: {
					updateCurrent: this.updateCurrent,
					goToFocused: this.goToFocused,
				},
			};
		},
	},
	watch: {
		states: {
			handler(val) {
				const oldIsScrollable = val.isScrollable;
				val.isScrollable = val.showPrevious || val.showNext;
				if (val.isScrollable === oldIsScrollable) {
					this.$emit('state-change', val);
				}
			},
			deep: true,
			immediate: false, // is updated on mounted
		},

		setIndex(val) {
			if (typeof val !== 'undefined' && val !== this.currentIndex) {
				this.goto(val);
			}
		},

		currentIndex: {
			handler(val) {
				this.$emit('update', val);
			},
			immediate: true,
		},

		'slotBindings.state.inView': {
			handler(activeItems) {
				if (!activeItems.length) {
					return null;
				}

				const activeItemsLabel = getActiveItemsLabel(
					activeItems.map((i) => ++i),
					', ',
					' & '
				);
				const total = this.items.length;

				this.screenReaderText = this.screenReaderTemplate
					.split('#{active}')
					.join(activeItemsLabel)
					.split('#{total}')
					.join(total);
			},
			immediate: true,
		},
	},

	mounted() {
		this.initElements();
	},
	destroy() {
		window.removeEventListener('resize', this.resizeUpdate);
	},
	methods: {
		initElements() {
			if (this.$slots.items) {
				this.itemsContainer = this.$refs.content;
				this.items = [...this.itemsContainer.children].filter(
					(el) => !el.hasAttribute('data-swiper-ignore')
				);
			} else if (this.$slots.custom) {
				this.items = [
					...this.$el.querySelectorAll('.js-swiper-wrap__child'),
				];
				this.spacerItems = [
					...this.$el.querySelectorAll(
						'.js-swiper-wrap__child--spacer'
					),
				];
				this.itemsContainer = this.$el.querySelector(
					'.js-swiper-wrap__content'
				);
			}

			if (this.items?.length) {
				this.currentIndex = Math.min(
					Math.max(0, this.currentIndex),
					this.items.length - 1
				);

				if (this.items.length) {
					window.addEventListener('resize', this.resizeUpdate);
					this.resizeUpdate();
				} else {
					this.currentIndex = -1;
				}

				this.goto(this.currentIndex, 'instant');
			} else {
				console.warn(
					"SwiperWrap: No content provided through 'items' slot"
				);
			}
		},

		goto(index, behavior = 'smooth') {
			if (this.itemsContainer && this.items?.length) {
				// Set index
				const nextIndex = Math.min(
					Math.max(0, index),
					this.items.length - 1
				);

				this.scrollTo(nextIndex, this.items, behavior);
			}
		},

		previousItems(loopAround) {
			if (this.itemsContainer) {
				// Get current index
				const { moveBy } = this.getMoveData();

				// Find next index
				const nextIndex = loopAround
					? this.items.length - 1
					: Math.max(this.currentIndex - moveBy, 0);
				this.scrollTo(nextIndex);
			}
		},

		nextItems(loopAround) {
			if (this.itemsContainer) {
				const { moveBy } = this.getMoveData();

				const nextIndex = loopAround
					? 0
					: Math.min(
							this.currentIndex + moveBy,
							this.items.length - 1
 );

				this.scrollTo(nextIndex);
			}
		},

		getMoveData(items = this.items, container = this.wrapper) {
			let { moveBy } = this;

			if (moveBy <= 0) {
				const width = this.itemsContainer.scrollWidth / items.length;

				moveBy = Math.floor(container.width / width) || 1;
			}

			return {
				moveBy,
			};
		},

		updateCurrent() {
			window.cancelAnimationFrame(this.frameRequest);
			this.frameRequest = window.requestAnimationFrame(() => {
				this.updateItemsInView(this.items);
				this.updateArrowState(this.items, this.wrapper);
			});
		},

		updateArrowState(items, container) {
			// Arrow visibility
			const lastRight =
				items[items.length - 1].getBoundingClientRect().right;

			this.states.showNext =
				Math.floor(lastRight) > Math.ceil(container.right) &&
				this.currentIndex !== items.length - 1;
			this.states.showPrevious = this.currentIndex > 0;
		},

		scrollTo(index, items = this.items, behavior = 'smooth') {
			const nextLeft = items[index].getBoundingClientRect().left;
			const firstLeft = items[0].getBoundingClientRect().left;

			// Smooth scroll
			if (this.itemsContainer.scrollTo) {
				this.itemsContainer.scrollTo({
					left: nextLeft - firstLeft,
					behavior,
				});
			} else {
				this.itemsContainer.scrollLeft = nextLeft - firstLeft;
			}
		},

		updateItemsInView(items = this.items) {
			if (!items) {
				return null;
			}

			let first = -1;
			const getItemsInView = (comparison) =>
				items.reduce((acc, child, index) => {
					if (comparison(child)) {
						if (first === -1) {
							first = index;
						}

						acc.push(index);
					}

					return acc;
				}, []);

			this.itemsInView = getItemsInView(this._childFullyVisible);

			if (first === -1) {
				this.itemsInView = getItemsInView(this._childPartiallyVisible);
			}

			this.currentIndex = first !== -1 ? first : this.currentIndex;
		},

		resizeUpdate() {
			if (this.itemsContainer) {
				const { left, right } =
					this.itemsContainer.getBoundingClientRect();

				this.wrapper.left = left;
				this.wrapper.right = right;
				this.wrapper.width = right - left;

				this.updateCurrent();
			}
		},

		goToFocused(e) {
			const path = [...(e?.path || [])];
			const contentIndex = path.indexOf(this.itemsContainer);

			if (this.itemsContainer && contentIndex) {
				const node = path[contentIndex - 1];
				const nodeIndex = Array.prototype.indexOf.call(
					this.itemsContainer.childNodes,
					node
				);

				if (this.currentIndex !== nodeIndex) {
					this.goto(nodeIndex);
				}
			}
		},

		// MINOR HELPERFUNCTIONS
		_childFullyVisible(item) {
			const { left, right } = this.wrapper;
			const rect = item.getBoundingClientRect();

			return (
				Math.floor(rect.right) <= Math.ceil(right + 1) &&
				Math.ceil(rect.left) >= Math.floor(left)
			);
		},
		_childPartiallyVisible(item) {
			const { left, right } = this.wrapper;
			const rect = item.getBoundingClientRect();

			const isEncompassing = rect.left <= left && rect.right >= right;
			const checkXWithin = (value) => value >= left && value <= right;

			return (
				isEncompassing ||
				checkXWithin(rect.left) ||
				checkXWithin(rect.right)
			);
		},
	},
};
</script>

<style lang="postcss">
/*! purgecss start ignore */
.c-swiper-wrap__live-region {
	position: absolute;
	width: 1px;
	height: 1px;
	margin: -1px;
	padding: 0;
	overflow: hidden;
	white-space: nowrap;
	border-width: 0;
	clip: rect(0, 0, 0, 0);
}
/*! purgecss end ignore */
</style>
