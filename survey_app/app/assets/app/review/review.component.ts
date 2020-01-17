import 'rxjs/add/operator/switchMap';
import { Component, OnInit, Input } from '@angular/core';
import { Router, ActivatedRoute, Params }from '@angular/router';

import {ReviewService}         from './review.service';
import {Review} from "./review";

@Component({
//  moduleId: module.repo,
  selector: 'commits',
  templateUrl: 'assets/app/review/review.component.html',
})
export class ReviewComponent implements OnInit {
  public review: Review = null;
  // public selectedHero: Commit;

  constructor(
    private reviewService: ReviewService,
    private router: Router,
    private route: ActivatedRoute) { }

  public ngOnInit(): void {
    this.getReview();
  }

  private getReview(): void {
    this.route.params
      .switchMap((params: Params) =>
        this.reviewService.getReview(params['repo_name'], params['commit'], params['key'])
      )
      .subscribe(review => this.review = review);
  }
  public saveReview(repoId: String, commit: String, warning: String, comment: String, useful: Boolean): void {
    this.reviewService.saveReview(repoId, commit, warning, comment, useful);
  }
}
