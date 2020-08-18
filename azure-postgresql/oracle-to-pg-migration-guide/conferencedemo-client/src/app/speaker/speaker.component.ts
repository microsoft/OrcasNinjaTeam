import { Component, OnInit, OnDestroy } from '@angular/core';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { ActivatedRoute } from '@angular/router';
import { SpeakerService } from '../services/speaker.service';
import { Speaker } from '../models/speaker';
import { takeUntil } from 'rxjs/operators';
import { Subject } from 'rxjs';

@Component({
  selector: 'app-speaker',
  templateUrl: './speaker.component.html'
})

export class SpeakerComponent implements OnInit, OnDestroy {
  speaker: Speaker = {firstName: '', lastName: ''} as any;
  speakerId: number;
  imgSpeaker: SafeResourceUrl;
  private _destroyed$ = new Subject();

  constructor(private route: ActivatedRoute, private speakerService: SpeakerService, private _sanitizer: DomSanitizer) { }
  ngOnInit(): void {
    this.route.params.subscribe((params: { speakerId: string }) => {
      this.speakerId = +params.speakerId;
    })

    this.speakerService.getSpeaker(this.speakerId).subscribe(data => {
      this.speaker = data;
      takeUntil(this._destroyed$);
      this.imgSpeaker = this._sanitizer.bypassSecurityTrustResourceUrl('data:image/png;base64, ' + data.speakerPic);
    });
  }

  ngOnDestroy(): void {
    this._destroyed$.next(true);
    this._destroyed$.complete();
  }
}
