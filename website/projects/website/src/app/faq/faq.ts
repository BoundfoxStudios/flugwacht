import { Component } from '@angular/core';
import { SectionHead } from '../section-head/section-head';

@Component({
  selector: 'bfs-fw-faq',
  imports: [SectionHead],
  templateUrl: './faq.html',
})
export class Faq {
  protected readonly entries = [
    {
      question: $localize`:@@faq.free.question:Is Flugwacht really free?`,
      answer: $localize`:@@faq.free.answer:Yes. Flugwacht is free and open source, has no ads and needs no account. It's a project by Boundfox Studios.`,
    },
    {
      question: $localize`:@@faq.which.question:Which flights can I track?`,
      answer: $localize`:@@faq.which.answer:Every flight that broadcasts ADS-B, which is nearly every airliner worldwide. You can add a flight by its flight number, registration or hex code.`,
    },
    {
      question: $localize`:@@faq.noSignal.question:What does 'no signal' mean?`,
      answer: $localize`:@@faq.noSignal.answer:Over oceans and in remote areas there are fewer receivers, so short gaps are normal. The flight reappears once it's back in range.`,
    },
    {
      question: $localize`:@@faq.data.question:Does Flugwacht collect my data?`,
      answer: $localize`:@@faq.data.answer:No. Your flights are stored only on your device, and the app only talks to the data source you picked.`,
    },
  ];
}
