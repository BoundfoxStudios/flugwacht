import { Component, computed, input } from '@angular/core';

@Component({
  selector: 'bfs-fw-logo',
  templateUrl: './logo.html',
})
export class Logo {
  readonly variant = input<'light' | 'dark'>('light');

  protected readonly outlineClass = computed(() =>
    this.variant() === 'dark' ? 'stroke-neutral-50' : 'stroke-neutral-800',
  );

  protected readonly irisClass = computed(() =>
    this.variant() === 'dark' ? 'fill-neutral-700' : 'fill-neutral-800',
  );
}
