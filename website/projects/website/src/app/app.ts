import { Component, DOCUMENT, LOCALE_ID, inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  imports: [RouterOutlet],
  selector: 'bfs-fw-root',
  styleUrl: './app.css',
  templateUrl: './app.html',
})
export class App {
  constructor() {
    inject(DOCUMENT).documentElement.lang = inject(LOCALE_ID);
  }
}
