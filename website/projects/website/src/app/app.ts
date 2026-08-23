import { Component, DOCUMENT, LOCALE_ID, inject } from '@angular/core';
import { Footer } from './footer/footer';
import { Hero } from './hero/hero';
import { Navigation } from './navigation/navigation';

@Component({
  imports: [Navigation, Hero, Footer],
  selector: 'bfs-fw-root',
  styleUrl: './app.css',
  templateUrl: './app.html',
})
export class App {
  constructor() {
    inject(DOCUMENT).documentElement.lang = inject(LOCALE_ID);
  }
}
