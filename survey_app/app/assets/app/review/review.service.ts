import { Injectable }    from '@angular/core';
import { Headers, Http } from '@angular/http';

import 'rxjs/add/operator/toPromise';

import {Review} from "./review";

@Injectable()
export class ReviewService {

  private commitUrl = 'api/review';

  constructor(private http: Http) { }

  public getReview(repoName: String, commit: String, key: String): Promise<Review> {
    return this.http.get(`${this.commitUrl}/${repoName}/${commit}/${key}`)
               .toPromise()
               .then(response => response.json() as Review)
               .catch(this.handleError);
  }

  public saveReview(repoId: String, commit: String, warning: String, comment: String, useful: Boolean): void {
    this.http.post(`${this.commitUrl}/${repoId}/${commit}/warning/${warning}`, {"comment": comment, "useful": useful})
      .toPromise()
      .then(response => response);
  }

  private handleError(error: any): Promise<any> {
    return Promise.reject(error.message || error);

  }
}

