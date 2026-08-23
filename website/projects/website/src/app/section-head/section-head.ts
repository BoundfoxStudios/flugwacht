import { Component, booleanAttribute, computed, input } from '@angular/core';

@Component({
  selector: 'bfs-fw-section-head',
  templateUrl: './section-head.html',
})
export class SectionHead {
  readonly heading = input.required<string>();
  readonly centered = input(false, { transform: booleanAttribute });
  readonly onDark = input(false, { transform: booleanAttribute });

  protected readonly headingClass = computed(() =>
    this.onDark() ? 'text-white' : 'text-neutral-800',
  );
}
