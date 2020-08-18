import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { Speaker } from '../models/speaker';
import { environment } from 'src/environments/environment';


@Injectable({
  providedIn: 'root'
})
export class SpeakerService {
  constructor(
    private http: HttpClient
  ) { }

  getSpeaker(speakerId: number): Observable<Speaker> {
    const httpOptions = {
      headers: new HttpHeaders({
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': 'GET'
      })
    };
    return this.http.get<Speaker>(`${environment.webApiUrl}/speakers/${speakerId}`, httpOptions)
      .pipe(
        map(data => {
          return data
        }),
        catchError(data => {
          if (data instanceof HttpErrorResponse && data.status === 404) {
            return [];
          } else {
            this.handleError(data);
          }
        })
      );
  }

  private handleError(error: HttpErrorResponse) {
    if (error.error instanceof ErrorEvent) {
      // A client-side or network error occurred. Handle it accordingly.
      console.error('An error occurred:', error.error.message);
    } else {
      // The backend returned an unsuccessful response code.
      // The response body may contain clues as to what went wrong,
      console.error(
        `Backend returned code ${error.status}, ` +
        `body was: ${error.error}`);
    }
    // return an observable with a user-facing error message
    return throwError('Something bad happened; please try again later.');
  }
}
