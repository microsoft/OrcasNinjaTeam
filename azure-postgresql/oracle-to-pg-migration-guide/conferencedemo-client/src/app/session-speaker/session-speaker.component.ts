import { Component, OnInit, OnDestroy } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { SessionSpeakerService } from '../services/sessionspeaker.service';
import { SessionSpeaker } from '../models/session-speaker';
import { EventService } from '../services/event.service';
import { Event } from '../models/Event';
import { RegisterationService } from '../services/registeration.service';
import { Registration } from '../models/registration';
import { takeUntil } from 'rxjs/operators';
import { Subject } from 'rxjs';

@Component({
  selector: 'app-session-speaker',
  templateUrl: './session-speaker.component.html'
})
export class SessionSpeakerComponent implements OnInit, OnDestroy {

  conferenceSessionsSpeakers: SessionSpeaker[] = [];
  attendeeId: number = +sessionStorage.getItem('loggedInAttendeeId');

  event: Event = {} as any;
  eventId: number;
  registration: Registration;
  registrationReponse: Registration[] = [];
  currentDate: Date;
  private _destroyed$ = new Subject();

  constructor(private route: ActivatedRoute, private sessionSpeakerService: SessionSpeakerService, private eventService: EventService,
    private registerAttendeesService: RegisterationService) { }

  // Post Registration Method (Called on Button Click)
  postRegistration(sessionId: number) {
    this.registration = new Registration();
    this.registration.attendeeId = this.attendeeId;
    this.registration.sessionId = sessionId;
    this.currentDate = new Date();

    this.registerAttendeesService.postRegistration(this.registration).subscribe(data => {
      this.registrationReponse = data;
      takeUntil(this._destroyed$);
      if (data != null) {
        const sessionSpeaker = this.conferenceSessionsSpeakers.filter(a => a.sessionId === this.registration.sessionId)[0];
        sessionSpeaker.isRegistered = true;
      }
    });
  }

  ngOnInit(): void {

    this.route.params.subscribe((params: { eventId: string }) => {
      this.eventId = +params.eventId;
    })

    this.sessionSpeakerService.getSessionSpeaker(this.eventId).subscribe(data => {
      this.conferenceSessionsSpeakers = data;
      takeUntil(this._destroyed$);
    });

    this.eventService.getEvents().subscribe(data => {
      takeUntil(this._destroyed$);
      if (data.length > 0) {
        this.event = data.filter(a => a.id === this.eventId)[0];
      }
      else {
        this.event = null;
      }
    });
  }

  ngOnDestroy(): void {
    this._destroyed$.next(true);
    this._destroyed$.complete();
  }

}
