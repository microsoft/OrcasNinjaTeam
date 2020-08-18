import { Component, OnInit, OnDestroy } from '@angular/core';
import { EventService } from '../services/event.service';
import { Event } from '../models/Event';
import { takeUntil } from 'rxjs/operators';
import { Subject } from 'rxjs';

@Component({
  selector: 'app-event-dashboard',
  templateUrl: './event-dashboard.component.html'
})
export class EventDashboardComponent implements OnInit, OnDestroy {

  conferenceEvents: Event[] = [];
  private _destroyed$ = new Subject();

  constructor(
    private eventService: EventService
  ) { }


  ngOnInit(): void {
    this.eventService.getEvents().subscribe(data => {
      takeUntil(this._destroyed$);
      this.conferenceEvents = data;
    });
  }

  ngOnDestroy(): void {
    this._destroyed$.next(true);
    this._destroyed$.complete();
  }
}
